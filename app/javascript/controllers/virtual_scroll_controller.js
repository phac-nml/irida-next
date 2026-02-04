import { Controller } from "@hotwired/stimulus";
import debounce from "debounce";
import { GridKeyboardNavigator } from "utilities/grid_keyboard_navigator";

import { createVirtualScrollLifecycle } from "controllers/virtual_scroll/lifecycle";
import { focusMixin } from "controllers/virtual_scroll/focus";
import { deferredTemplateFieldsMixin } from "controllers/virtual_scroll/deferred_template_fields";
import { navigationEventsMixin } from "controllers/virtual_scroll/navigation_events";
import {
  initializeDimensions,
  handleResize,
} from "controllers/virtual_scroll/layout_pipeline";
import { renderVirtualScroll } from "controllers/virtual_scroll/render_pipeline";

/**
 * VirtualScrollController
 *
 * Implements virtualized horizontal scrolling for tables with large numbers of metadata columns.
 * Only renders visible body cells plus a buffer. Headers are rendered server-side (no virtualization).
 *
 * Features:
 * - Variable-width column support (measures actual DOM widths)
 * - Headers rendered server-side for simplicity and performance
 * - Body cells virtualized (only visible + buffer rendered)
 * - Sticky column preservation (never virtualized)
 * - Auto-scroll to sorted column on page load
 * - ResizeObserver for responsive behaviour
 * - Protection for cells currently being edited
 * - Integration with table_controller.js and editable_cell_controller.js
 *
 * Grid contract (APG data grid):
 * - Root element uses role="grid" with aria-rowcount/aria-colcount
 * - Rows have aria-rowindex (1-based)
 * - Cells have aria-colindex (1-based) and role="columnheader" or role="gridcell"
 * - Body rows include data-virtual-scroll-target="row" and data-sample-id
 * - Templates live under data-virtual-scroll-target="templateContainer" with
 *   <template data-field="..."> nodes per metadata field
 * - Development diagnostics emit virtual-scroll:measure/render/resize events
 *
 * @example
 *   <div data-controller="virtual-scroll"
 *        data-virtual-scroll-metadata-fields-value='["field1", "field2"]'
 *        data-virtual-scroll-fixed-columns-value='["puid", "name"]'
 *        data-virtual-scroll-sticky-column-count-value="2"
 *        data-virtual-scroll-sort-key-value="metadata_field1">
 */
class VirtualScrollController extends Controller {
  /**
   * Stimulus value definitions
   * @property {string[]} metadataFieldsValue - Array of metadata field names to render as columns
   * @property {string[]} fixedColumnsValue - Array of fixed column identifiers (non-metadata)
   * @property {number} stickyColumnCountValue - Maximum number of columns to make sticky
   * @property {string} sortKeyValue - Current sort key (e.g., "metadata_fieldname" or "updated_at")
   * @property {boolean} stretchBaseColumnsValue - Whether to stretch base columns when no metadata
   */
  static values = {
    metadataFields: Array,
    fixedColumns: Array,
    stickyColumnCount: Number,
    sortKey: String,
    stretchBaseColumns: Boolean,
  };

  static targets = [
    "container",
    "header",
    "body",
    "row",
    "templateContainer",
    "loading",
    "deferredFrame",
  ];

  // Track a pending focus target for post-render reapplication
  pendingFocusRow = null;
  pendingFocusCol = null;

  sortFocusToRestore = null;

  static constants = Object.freeze({
    BUFFER_COLUMNS: 3, // Number of columns to render outside viewport on each side
    MAX_MEASURE_RETRIES: 5,
    MAX_CELL_READY_RETRIES: 5,
    PAGE_JUMP_SIZE: 5, // Rows to jump on PageUp/PageDown
    STICKY_HEADER_Z_INDEX: 20,
    STICKY_BODY_Z_INDEX: 10,
  });

  /**
   * Read configuration values from CSS custom properties
   * @returns {{columnWidth: number, breakpoint2xl: number}}
   * @private
   */
  static getCSSConfig() {
    const style = getComputedStyle(document.documentElement);
    const columnWidthRaw = style
      .getPropertyValue("--metadata-column-width")
      .trim();
    const breakpoint2xlRaw = style.getPropertyValue("--breakpoint-2xl").trim();

    // Fallback values: 300px metadata column width (matches Tailwind w-[300px]),
    // 1536px is Tailwind's 2xl breakpoint for responsive sticky column behaviour
    return {
      columnWidth: parseInt(columnWidthRaw || "300", 10),
      breakpoint2xl: parseInt(breakpoint2xlRaw || "1536", 10),
    };
  }

  measureRetryCount = 0;
  isRetrying = false; // Guard for race condition in retry logic

  /**
   * Stimulus lifecycle: Connect controller and initialize
   */
  connect() {
    this.lifecycle = createVirtualScrollLifecycle();

    this.restorePendingFocusFromSessionStorage();

    this.setupSortFocusRestoration();

    // Set up navigation event listeners for virtualized blur handling
    this.setupNavigationEventListeners();

    // Get CSS configuration values
    this.cssConfig = this.constructor.getCSSConfig();

    this.boundHandleSort = this.handleSort.bind(this);
    this.lifecycle.listen(this.element, "click", this.boundHandleSort, {
      capture: true,
    });

    this.boundHandleKeydown = this.handleKeydown.bind(this);
    this.lifecycle.listen(this.element, "keydown", this.boundHandleKeydown, {
      capture: true,
    });

    this.boundHandleDblClick = this.handleDblClick.bind(this);
    this.lifecycle.listen(this.element, "dblclick", this.boundHandleDblClick, {
      capture: true,
    });

    this.boundHandleFocusin = this.handleFocusin.bind(this);
    this.lifecycle.listen(this.element, "focusin", this.boundHandleFocusin);

    this.boundHandleLayoutToggle = this.handleLayoutToggle.bind(this);
    this.lifecycle.listen(
      window,
      "layout:toggle",
      this.boundHandleLayoutToggle,
    );

    // Listen for focus reset events from table controller
    this.boundHandleFocusReset = this.handleFocusReset.bind(this);
    this.lifecycle.listen(
      this.element,
      "table:focus-reset",
      this.boundHandleFocusReset,
    );

    this.boundHideLoading = this.hideLoading.bind(this);
    this.lifecycle.listen(
      document,
      "turbo:before-cache",
      this.boundHideLoading,
    );

    // Listen for deferred template arrival - use MutationObserver for reliable detection
    this.setupDeferredTemplateObserver();

    this.boundRender = this.render.bind(this);
    this.boundHandleResize = this.handleResize.bind(this);
    this.hasAutoScrolled = false;
    this.isInitialized = false;
    this.isInitializing = true;

    // Reset any cached visible range from previous connections (important for Turbo navigation)
    this.lastFirstVisible = undefined;
    this.lastLastVisible = undefined;

    // Initialize metadata column widths array
    this.metadataColumnWidths = [];
    this.geometry = null; // Will be initialized after measuring column widths

    // Track per-row visible ranges to avoid unnecessary updates
    this.rowVisibleRanges = new Map();

    // RAF-based scroll handling (no debounce for instant response)
    this.rafPending = false;
    this.handleScroll = () => {
      if (!this.rafPending) {
        this.rafPending = true;
        requestAnimationFrame(() => {
          this.rafPending = false;
          this.boundRender();
        });
      }
    };

    // Keep debounce for resize (less critical)
    this.debouncedResizeHandler = debounce(this.boundHandleResize, 100);

    this.lifecycle.trackDebounce(this.debouncedResizeHandler);

    this.lifecycle.listen(this.containerTarget, "scroll", this.handleScroll, {
      passive: true,
    });

    // Initialize ResizeObserver for responsive behaviour
    this.resizeObserver = new ResizeObserver(this.debouncedResizeHandler);
    this.resizeObserver.observe(this.containerTarget);
    this.lifecycle.trackObserver(this.resizeObserver);

    // Handle Turbo cache restoration - need to re-render when page is restored from cache
    this.boundHandleTurboRender = this.handleTurboRender.bind(this);
    this.lifecycle.listen(
      document,
      "turbo:render",
      this.boundHandleTurboRender,
    );

    // Sync template content when cells are replaced via Turbo Stream (e.g., after metadata edit)
    this.boundSyncTemplateOnStreamReplace =
      this.syncTemplateOnStreamReplace.bind(this);
    this.lifecycle.listen(
      document,
      "turbo:before-stream-render",
      this.boundSyncTemplateOnStreamReplace,
    );

    requestAnimationFrame(() => {
      const initialized = this.initializeDimensions();
      this.isInitialized = initialized;

      if (initialized) {
        const tableElement = this.element.querySelector("table");

        // Initialize keyboard navigator after dimensions are set
        this.keyboardNavigator = new GridKeyboardNavigator({
          gridElement: this.element,
          bodyElement: this.bodyTarget,
          rootElement: tableElement || this.bodyTarget,
          numBaseColumns: this.numBaseColumns,
          totalColumns: this.totalColumnCount(),
          pageJumpSize: this.constructor.constants.PAGE_JUMP_SIZE,
          onNavigate: (rowIndex, colIndex) =>
            this.ensureCellReady(rowIndex, colIndex),
        });

        // Render once to clone templates into visible cells
        this.render();

        // Auto-scroll to sorted column if applicable
        requestAnimationFrame(() => {
          this.scrollToSortedColumn();
          this.isInitializing = false;
        });
      } else {
        this.isInitializing = false;
      }
    });
  }

  /**
   * Handle Turbo render events - force re-render when page content changes
   */
  handleTurboRender() {
    // Only handle if we're initialized and the controller element is still in the DOM
    if (!this.isInitialized || !this.element.isConnected) return;

    // If a sort was triggered and the response renders in-place (e.g., within a Turbo Frame),
    // the controller may stay connected. Re-check sessionStorage so we can restore focus.
    this.restorePendingFocusFromSessionStorage();

    // Reset state and re-render
    this.lastFirstVisible = undefined;
    this.lastLastVisible = undefined;

    // Re-initialize dimensions in case the DOM structure changed
    requestAnimationFrame(() => {
      this.initializeDimensions();
      this.render();

      if (this.sortFocusToRestore) {
        this.focusCellIfNeeded(
          this.sortFocusToRestore.row,
          this.sortFocusToRestore.col,
        );
        this.sortFocusToRestore = null;
      }
    });
  }

  /**
   * Sync template content when a cell is replaced via Turbo Stream.
   * This ensures virtualized cells show updated values after edits when scrolling.
   * @param {CustomEvent} event - Turbo before-stream-render event
   */
  syncTemplateOnStreamReplace(event) {
    const streamElement = event.target;
    if (streamElement.action !== "replace") return;

    const targetId = streamElement.target;
    if (!targetId) return;

    // Check if this replacement is for a cell within our virtualized table
    const existingCell = document.getElementById(targetId);
    if (!existingCell) return;

    // Verify the cell belongs to this controller's table
    if (!this.element.contains(existingCell)) return;

    const fieldId = existingCell.dataset.fieldId;
    if (!fieldId) return;

    // Find the sample ID from the row
    const row = existingCell.closest("tr[data-sample-id]");
    const sampleId = row?.dataset?.sampleId;
    if (!sampleId) return;

    // Get the new content from the stream's template
    const newContent = streamElement.templateContent?.firstElementChild;
    if (!newContent) return;

    // Find and update the corresponding template in templateContainer
    const templateSelector = `[data-sample-id="${sampleId}"] template[data-field="${CSS.escape(fieldId)}"]`;
    const template =
      this.templateContainerTarget?.querySelector(templateSelector);
    if (!template) return;

    // Clone the new content and update the template
    const clonedContent = newContent.cloneNode(true);
    template.innerHTML = "";
    template.content.appendChild(clonedContent);
  }

  /**
   * Value change callback - re-render when metadata fields change dynamically
   */
  metadataFieldsValueChanged() {
    if (this.isInitialized) {
      this.rowVisibleRanges?.clear();
      this.initializeDimensions();
      this.render();
    }
  }

  /**
   * Initialize dimensions by measuring actual column widths from DOM
   * Supports variable-width columns instead of fixed COLUMN_WIDTH
   */
  initializeDimensions() {
    return initializeDimensions(this);
  }

  /**
   * Stimulus lifecycle: Disconnect and cleanup
   */
  disconnect() {
    // Clean up navigation event state
    this.cleanupNavigationEventListeners();

    this.lifecycle?.stop?.();
    this.lifecycle = null;

    // Cancel RAF if pending
    this.rafPending = false;

    // Clear observer references (disconnected via lifecycle)
    this.deferredObserver = null;
    this.resizeObserver = null;

    // Clear caches and utilities
    this.rowVisibleRanges = null;
    this.geometry = null;
    this.keyboardNavigator = null;
    this.stickyManager = null;
    this.cellRenderer = null;
  }

  /**
   * Handle sort clicks to show loading overlay
   * @param {Event} event - Click event
   */
  handleSort(event) {
    const link = event.target.closest("a[href]");
    if (link && this.headerTarget.contains(link)) {
      if (link.dataset.turboAction === "replace") {
        this.rememberPendingFocusFromSortLink(link);
        this.showLoading();
      }
    }
  }

  /**
   * Show loading overlay
   */
  showLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.remove("hidden");
    }
  }

  /**
   * Hide loading overlay
   */
  hideLoading() {
    if (this.hasLoadingTarget) {
      this.loadingTarget.classList.add("hidden");
    }
  }

  /**
   * Handle resize events - re-measure and re-render
   */
  handleResize() {
    handleResize(this);
  }

  /**
   * Detect sticky column count based on window width
   * @returns {number} Number of sticky columns (2 at @2xl+, 1 below)
   */
  detectStickyColumnCount(maxStickyColumns = this.numBaseColumns) {
    const cappedMax = Math.min(maxStickyColumns, this.numBaseColumns);

    // Use breakpoint from CSS custom property
    if (window.innerWidth >= this.cssConfig.breakpoint2xl) {
      return Math.min(2, cappedMax);
    }

    return Math.min(1, cappedMax);
  }

  handleLayoutToggle() {
    if (this.debouncedResizeHandler) {
      this.debouncedResizeHandler();
    }
  }

  shouldStretchBaseColumns() {
    return (
      Boolean(this.stretchBaseColumnsValue) && this.numMetadataColumns === 0
    );
  }

  stretchBaseColumnsToContainer() {
    if (!this.shouldStretchBaseColumns()) return;
    if (!this.baseColumnsWidth || this.baseColumnsWidth <= 0) return;

    const containerWidth = this.containerTarget?.clientWidth;
    if (!containerWidth || containerWidth <= this.baseColumnsWidth) return;

    const extraWidth = containerWidth - this.baseColumnsWidth;
    const updatedWidths = this.baseColumnWidths.map(
      (width) => width + (width / this.baseColumnsWidth) * extraWidth,
    );

    this.baseColumnWidths = updatedWidths;
    this.baseColumnsWidth = updatedWidths.reduce((a, b) => a + b, 0);

    this.baseHeaderElements.forEach((th, index) => {
      th.style.width = `${updatedWidths[index]}px`;
    });
  }

  calculateTotalTableWidth(totalMetadataWidth) {
    const totalWidth = this.baseColumnsWidth + totalMetadataWidth;
    if (this.shouldStretchBaseColumns()) {
      const containerWidth = this.containerTarget?.clientWidth;
      if (containerWidth && containerWidth > totalWidth) return containerWidth;
    }

    return totalWidth;
  }

  /**
   * Auto-scroll to sorted metadata column on page load
   * Only runs once on initial page load
   */
  scrollToSortedColumn() {
    // Only auto-scroll once
    if (this.hasAutoScrolled) return;
    this.hasAutoScrolled = true;

    // Check if sortKey exists and is a metadata field
    const sortKey = this.sortKeyValue;
    if (!sortKey || sortKey === "") return;

    // Extract field name from sort key (e.g., "metadata_field_name" -> "field_name")
    const metadataPrefix = "metadata_";
    if (!sortKey.startsWith(metadataPrefix)) return; // Base column sort, no auto-scroll

    const fieldName = sortKey.substring(metadataPrefix.length);

    // Find the sorted header directly from the DOM (much simpler now that all headers are rendered)
    const sortedHeader = this.headerRow.querySelector(
      `th[data-field-id="${CSS.escape(fieldName)}"]`,
    );
    if (!sortedHeader) return; // Header not found

    // Get the header's position and width from the DOM
    const headerLeft = sortedHeader.offsetLeft;
    const headerWidth = sortedHeader.offsetWidth;

    // Position column at right edge of viewport with small padding
    const padding = 16; // pixels
    const targetScrollLeft =
      headerLeft + headerWidth - this.containerTarget.clientWidth + padding;

    // Clamp to valid range
    const maxScroll = Math.max(
      0,
      this.containerTarget.scrollWidth - this.containerTarget.clientWidth,
    );
    const clampedScroll = Math.max(0, Math.min(maxScroll, targetScrollLeft));

    // Apply scroll - this will trigger scroll events, but we'll render immediately after
    this.containerTarget.scrollLeft = clampedScroll;

    // Force re-render at new scroll position by clearing cached visible range
    // Use requestAnimationFrame to ensure the scroll position has been applied
    requestAnimationFrame(() => {
      this.lastFirstVisible = undefined;
      this.lastLastVisible = undefined;
      this.render();
    });
  }

  /**
   * Main render method - updates visible columns based on scroll position
   */
  render() {
    renderVirtualScroll(this);
  }

  getActiveEditingColumnIndex() {
    // Find cell currently being edited in the body
    const markedEditingCell = this.bodyTarget.querySelector?.(
      '[data-editing="true"]',
    );
    const editingCell =
      markedEditingCell || document.activeElement?.closest?.("[data-field-id]");

    if (!editingCell || !this.bodyTarget.contains(editingCell)) return null;

    const fieldId = editingCell.dataset.fieldId;
    if (!fieldId) return null;

    const columnIndex = this.metadataFieldIndex?.get(fieldId);
    return columnIndex ?? null;
  }

  /**
   * Apply sticky positioning styles to base columns in a row
   * Delegates to StickyColumnManager utility
   * @param {HTMLElement} row - The row element
   */
  applyStickyStylesToRow(row) {
    const children = Array.from(row.children).filter(
      (c) => c.tagName.toLowerCase() !== "template",
    );

    // Apply sticky styles to all base columns (sticky and non-sticky)
    for (let i = 0; i < this.numBaseColumns; i++) {
      const child = children[i];
      if (!child) continue;
      this.stickyManager.applyToBodyCell(child, i);
    }
  }

  /**
   * Sum width of sticky columns for scroll calculations
   * Delegates to StickyColumnManager utility
   */
  stickyColumnsWidth() {
    return this.stickyManager?.getTotalWidth() ?? 0;
  }

  /**
   * Convert 1-based aria-colindex to 0-based metadata column index
   * @param {number} colIndex - 1-based aria-colindex
   * @returns {number} 0-based metadata column index
   */
  getMetadataIndexFromColIndex(colIndex) {
    return colIndex - this.numBaseColumns - 1;
  }

  /**
   * Check if an aria-colindex column is within the current render range
   * @param {number} colIndex - 1-based aria-colindex
   * @returns {boolean} True if column is rendered
   */
  isColumnInRenderRange(colIndex) {
    if (colIndex <= this.numBaseColumns) {
      return true; // Base columns are always rendered
    }
    const metadataIndex = this.getMetadataIndexFromColIndex(colIndex);
    return (
      this.lastFirstVisible !== undefined &&
      this.lastLastVisible !== undefined &&
      metadataIndex >= this.lastFirstVisible &&
      metadataIndex < this.lastLastVisible
    );
  }

  /**
   * Ensure a metadata column is rendered and scrolled into view for focus
   * @param {number} colIndex 1-based column index across all columns
   * @returns {boolean|undefined} true if scroll/render was triggered, false if no scroll needed, undefined for early exits
   */
  ensureMetadataColumnVisible(colIndex) {
    if (colIndex <= this.numBaseColumns) return;
    const metadataIndex = colIndex - this.numBaseColumns - 1;
    if (metadataIndex < 0 || metadataIndex >= this.numMetadataColumns) return;

    // Check if column is in current render range (not just scroll visible)
    const isInRenderRange = this.isColumnInRenderRange(colIndex);

    const stickyWidth = this.stickyColumnsWidth();
    const colLeft = this.geometry.cumulativeWidthTo(metadataIndex);
    const colWidth = this.metadataColumnWidths[metadataIndex];

    const containerWidth = this.containerTarget.clientWidth;
    const currentScrollLeft = this.containerTarget.scrollLeft;

    // Calculate absolute positions in the scrollable container
    const absoluteColLeft = this.baseColumnsWidth + colLeft;
    const absoluteColRight = absoluteColLeft + colWidth;

    // Calculate currently visible area (accounting for sticky columns)
    const visibleStart = currentScrollLeft + stickyWidth;
    const visibleEnd = currentScrollLeft + containerWidth;

    const isScrollVisible =
      absoluteColLeft >= visibleStart && absoluteColRight <= visibleEnd;

    // Only return early if BOTH in render range AND scroll visible
    if (isInRenderRange && isScrollVisible) {
      // Return false: column is already visible; no scroll or re-render is performed.
      return false;
    }

    // If in render range but not scroll visible, we still need to scroll
    // If scroll visible but not in render range, we need to re-render

    // Calculate target scroll to make it visible
    let targetScrollLeft = currentScrollLeft;

    if (absoluteColLeft < visibleStart) {
      // Scroll left to show left edge
      targetScrollLeft = absoluteColLeft - stickyWidth;
    } else if (absoluteColRight > visibleEnd) {
      // Scroll right to show right edge
      targetScrollLeft = absoluteColRight - containerWidth;
    }

    const maxScroll = Math.max(
      0,
      this.containerTarget.scrollWidth - this.containerTarget.clientWidth,
    );
    const clamped = Math.max(0, Math.min(maxScroll, targetScrollLeft));

    if (Math.abs(clamped - currentScrollLeft) > 1) {
      this.containerTarget.scrollLeft = clamped;

      // Force re-render so the column is materialized
      this.lastFirstVisible = undefined;
      this.lastLastVisible = undefined;
      this.render();
      return true;
    }
    return false;
  }

  async ensureCellReady(rowIndex, colIndex) {
    // Try a few frames to allow rendering/placeholders to appear
    const maxTries = this.constructor.constants.MAX_CELL_READY_RETRIES;

    // Determine the search root: header row is in thead, body rows in tbody
    const tableElement = this.element.querySelector("table");
    const searchRoot = tableElement || this.bodyTarget;

    for (let i = 0; i < maxTries; i += 1) {
      // Remember intended focus so post-render roving tabindex can honor it
      // Reset on each iteration because render() clears it
      this.pendingFocusRow = rowIndex;
      this.pendingFocusCol = colIndex;

      // Force scroll to the far left when moving to the first column (Home/Ctrl+Home)
      if (colIndex === 1 && this.containerTarget.scrollLeft !== 0) {
        this.containerTarget.scrollLeft = 0;
        this.lastFirstVisible = undefined;
        this.lastLastVisible = undefined;
      }

      if (colIndex > this.numBaseColumns) {
        const rendered = this.ensureMetadataColumnVisible(colIndex);
        if (!rendered) {
          this.render();
        }
      } else {
        this.render();
      }

      // Check immediately if the cell exists after render
      // This avoids an unnecessary frame delay which can cause focus loss
      // Search in the entire table to find header and body rows
      let row = searchRoot?.querySelector?.(`[aria-rowindex="${rowIndex}"]`);
      let cell = row?.querySelector?.(`[aria-colindex="${colIndex}"]`);

      if (cell) {
        // Ensure it's focused (render might have done it, but to be safe)
        cell.focus();
        return true;
      }

      // Give the DOM a frame to materialize
      // Intentional sequential await - we need to wait for each frame before retrying

      await new Promise((resolve) => requestAnimationFrame(resolve));

      row = searchRoot?.querySelector?.(`[aria-rowindex="${rowIndex}"]`);
      if (!row) continue;
      cell = row.querySelector(`[aria-colindex="${colIndex}"]`);
      if (cell) {
        cell.focus();
        return true;
      }
    }

    // If we exhausted retries, keep pending focus so fallback logic can still try
    return false;
  }

  /**
   * Reset all visible gridcells to tabindex=-1 and set a single active cell to tabindex=0
   * Delegates to GridKeyboardNavigator utility
   */
  applyRovingTabindex(fallbackRowIndex, fallbackColIndex) {
    if (this.keyboardNavigator) {
      this.keyboardNavigator.applyRovingTabindex(
        fallbackRowIndex,
        fallbackColIndex,
      );
    }
  }

  /**
   * Handle keyboard navigation per APG grid pattern (arrow keys, Home/End, PageUp/PageDown)
   * Delegates to GridKeyboardNavigator utility
   */
  handleKeydown(event) {
    this.rememberPendingFocusFromSortKeydown(event);

    if (this.keyboardNavigator) {
      this.keyboardNavigator.handleKeydown(event);
    }
  }

  // rememberPendingFocusFromSortKeydown moved to focusMixin

  handleDblClick(event) {
    if (this.keyboardNavigator) {
      this.keyboardNavigator.handleDblClick(event);
    }
  }

  handleFocusin(event) {
    if (this.keyboardNavigator) {
      this.keyboardNavigator.handleFocusin(event);
    }
  }

  /**
   * Handle focus reset event from table controller.
   * Resets the roving tabindex state to the specified cell coordinates.
   * @param {CustomEvent} event - Event with detail.rowIndex and detail.colIndex
   */
  handleFocusReset(event) {
    const { rowIndex, colIndex } = event.detail || {};

    if (!Number.isInteger(rowIndex) || !Number.isInteger(colIndex)) return;

    // Don't reset during active navigation - this can corrupt navigation state
    // when blur events fire due to cell destruction during re-rendering
    if (this.keyboardNavigator?.isNavigating) {
      return;
    }

    // Don't reset if there's already a pending focus to a different cell
    // This can happen when RAF-triggered renders destroy cells between navigations
    if (
      Number.isInteger(this.pendingFocusRow) &&
      Number.isInteger(this.pendingFocusCol) &&
      (this.pendingFocusRow !== rowIndex || this.pendingFocusCol !== colIndex)
    ) {
      return;
    }

    // Set pending focus to the target cell so that if render() runs,
    // it will use these coordinates instead of trying to capture from activeElement
    this.pendingFocusRow = rowIndex;
    this.pendingFocusCol = colIndex;

    // Reset keyboard navigator state and apply roving tabindex
    if (this.keyboardNavigator) {
      this.keyboardNavigator.focusedRowIndex = rowIndex;
      this.keyboardNavigator.focusedColIndex = colIndex;
      this.keyboardNavigator.applyRovingTabindex(rowIndex, colIndex);
    }

    // Clear pending focus after a short delay to prevent render() from
    // re-focusing the cell. The delay ensures applyRovingTabindex has completed.
    const schedule =
      this.lifecycle?.timeout?.bind(this.lifecycle) || setTimeout;
    schedule(() => {
      if (!this.element?.isConnected) return;
      // Only clear if still pointing to our target (not changed by user interaction)
      if (
        this.pendingFocusRow === rowIndex &&
        this.pendingFocusCol === colIndex
      ) {
        this.pendingFocusRow = null;
        this.pendingFocusCol = null;
      }
    }, 100);
  }

  totalColumnCount() {
    return (this.numBaseColumns || 0) + (this.numMetadataColumns || 0);
  }
}

Object.assign(
  VirtualScrollController.prototype,
  focusMixin,
  deferredTemplateFieldsMixin,
  navigationEventsMixin,
);

export default VirtualScrollController;
