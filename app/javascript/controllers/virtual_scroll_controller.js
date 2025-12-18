import { Controller } from "@hotwired/stimulus";
import _ from "lodash";
import { VirtualScrollGeometry } from "utilities/virtual_scroll_geometry";
import { GridKeyboardNavigator } from "utilities/grid_keyboard_navigator";
import { StickyColumnManager } from "utilities/sticky_column_manager";
import { VirtualScrollCellRenderer } from "utilities/virtual_scroll_cell_renderer";

const SORT_FOCUS_STORAGE_KEY = "irida:virtual-scroll:pending-focus";
const SORT_FOCUS_TTL_MS = 5000;

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
 * - ResizeObserver for responsive behavior
 * - Protection for cells currently being edited
 * - Integration with table_controller.js and editable_cell_controller.js
 *
 * @example
 *   <div data-controller="virtual-scroll"
 *        data-virtual-scroll-metadata-fields-value='["field1", "field2"]'
 *        data-virtual-scroll-fixed-columns-value='["puid", "name"]'
 *        data-virtual-scroll-sticky-column-count-value="2"
 *        data-virtual-scroll-sort-key-value="metadata_field1">
 */
export default class extends Controller {
  static values = {
    metadataFields: Array,
    fixedColumns: Array,
    stickyColumnCount: Number,
    sortKey: String,
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
    this.restorePendingFocusFromSessionStorage();

    if (this.sortFocusToRestore) {
      this.boundRestoreSortFocusAfterLoad = () => {
        const target = this.sortFocusToRestore;
        if (!target) return;

        // Turbo may restore focus after our initial render; re-assert focus on load.
        requestAnimationFrame(() => {
          requestAnimationFrame(() => {
            this.focusCellIfNeeded(target.row, target.col);
          });
        });

        this.sortFocusToRestore = null;
      };

      document.addEventListener(
        "turbo:load",
        this.boundRestoreSortFocusAfterLoad,
        { once: true },
      );

      document.addEventListener(
        "turbo:render",
        this.boundRestoreSortFocusAfterLoad,
        { once: true },
      );

      // Fallback for cases where turbo:load doesn't fire (or fires before connect)
      setTimeout(() => {
        if (this.sortFocusToRestore) {
          this.focusCellIfNeeded(
            this.sortFocusToRestore.row,
            this.sortFocusToRestore.col,
          );
          this.sortFocusToRestore = null;
        }
      }, 0);
    }

    // Get CSS configuration values
    this.cssConfig = this.constructor.getCSSConfig();

    this.boundHandleSort = this.handleSort.bind(this);
    this.element.addEventListener("click", this.boundHandleSort, true);

    this.boundHandleKeydown = this.handleKeydown.bind(this);
    this.element.addEventListener("keydown", this.boundHandleKeydown, true);

    this.boundHandleDblClick = this.handleDblClick.bind(this);
    this.element.addEventListener("dblclick", this.boundHandleDblClick, true);

    this.boundHideLoading = this.hideLoading.bind(this);
    document.addEventListener("turbo:before-cache", this.boundHideLoading);

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
    this.debouncedResizeHandler = _.debounce(this.boundHandleResize, 100);

    this.containerTarget.addEventListener("scroll", this.handleScroll, {
      passive: true,
    });

    // Initialize ResizeObserver for responsive behavior
    this.resizeObserver = new ResizeObserver(this.debouncedResizeHandler);
    this.resizeObserver.observe(this.containerTarget);

    // Handle Turbo cache restoration - need to re-render when page is restored from cache
    this.boundHandleTurboRender = this.handleTurboRender.bind(this);
    document.addEventListener("turbo:render", this.boundHandleTurboRender);

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
    if (!this.headerTarget || !this.bodyTarget) return false;
    if (
      !Array.isArray(this.metadataFieldsValue) ||
      !Array.isArray(this.fixedColumnsValue)
    )
      return false;

    this.headerRow = this.headerTarget.querySelector("tr");
    if (!this.headerRow) return false;
    this.numBaseColumns = this.fixedColumnsValue.length;
    this.numMetadataColumns = this.metadataFieldsValue.length;
    this.metadataFieldIndex = new Map();
    this.metadataFieldsValue.forEach((field, index) => {
      this.metadataFieldIndex.set(field, index);
    });
    const maxStickyColumns = Math.min(
      this.stickyColumnCountValue ?? this.numBaseColumns,
      this.numBaseColumns,
    );
    this.numStickyColumns = this.detectStickyColumnCount(maxStickyColumns);

    const table = this.element.querySelector("table");
    if (!table) return false;

    const headerCells = Array.from(this.headerRow.querySelectorAll("th"));
    this.baseHeaderElements = headerCells.slice(0, this.numBaseColumns);

    // Measure base column widths
    this.baseColumnWidths = this.baseHeaderElements.map((th, idx) => {
      const width = th.getBoundingClientRect().width;

      // Explicitly set width and box-sizing for base columns
      Object.assign(th.style, {
        width: width > 0 ? `${width}px` : "",
        boxSizing: "border-box",
      });

      if (idx < this.numStickyColumns) {
        // Ensure the sticky header cell keeps its stacking context
        Object.assign(th.style, {
          position: "sticky",
          top: "0px",
          zIndex: String(this.constructor.constants.STICKY_HEADER_Z_INDEX),
        });
        th.dataset.fixed = "true";
      } else {
        Object.assign(th.style, {
          position: "",
          left: "",
          zIndex: "",
        });
        th.dataset.fixed = "false";
      }

      return width;
    });
    this.baseColumnsWidth = this.baseColumnWidths.reduce((a, b) => a + b, 0);

    // Compute explicit left offsets only for sticky columns so sticky positions
    // will align correctly even after we manipulate the DOM.
    this.stickyColumnLefts = this.baseColumnWidths.map((_, idx) => {
      if (idx >= this.numStickyColumns) return null;
      return this.baseColumnWidths.slice(0, idx).reduce((a, b) => a + b, 0);
    });

    // Measure actual metadata column widths from DOM
    const metadataHeaders = headerCells.slice(this.numBaseColumns);
    this.metadataColumnWidths = metadataHeaders.map((th) => {
      const width =
        th.getBoundingClientRect().width || this.cssConfig.columnWidth;

      // Explicitly set width for metadata headers to prevent them from resizing
      // and prevent text overflow
      Object.assign(th.style, {
        width: `${width}px`,
        minWidth: `${width}px`,
        maxWidth: `${width}px`,
        boxSizing: "border-box",
        overflow: "hidden",
        textOverflow: "ellipsis",
        whiteSpace: "nowrap",
      });

      return width;
    });

    // If no metadata columns measured yet, use columnWidth from CSS as fallback
    if (this.metadataColumnWidths.length === 0) {
      this.metadataColumnWidths = Array(this.numMetadataColumns).fill(
        this.cssConfig.columnWidth,
      );
    }

    // Initialize geometry calculator with measured column widths
    this.geometry = new VirtualScrollGeometry(this.metadataColumnWidths);

    // Initialize sticky column manager
    this.stickyManager = new StickyColumnManager({
      columnWidths: this.baseColumnWidths,
      stickyCount: this.numStickyColumns,
      headerZIndex: this.constructor.constants.STICKY_HEADER_Z_INDEX,
      bodyZIndex: this.constructor.constants.STICKY_BODY_Z_INDEX,
    });

    // Initialize cell renderer
    this.cellRenderer = new VirtualScrollCellRenderer({
      metadataFields: this.metadataFieldsValue,
      numBaseColumns: this.numBaseColumns,
      metadataColumnWidths: this.metadataColumnWidths,
      columnWidthFallback: this.cssConfig.columnWidth,
    });

    // Keep all metadata headers in DOM (rendered server-side)
    // No need to virtualize headers - performance impact is minimal for 1000 headers
    this.metadataHeaders = metadataHeaders;

    // Keep references to base header elements for sticky positioning updates
    this.baseHeaderElements = headerCells.slice(0, this.numBaseColumns);

    // Calculate total metadata width using measured widths
    const totalMetadataWidth = this.metadataColumnWidths.reduce(
      (a, b) => a + b,
      0,
    );
    const totalWidth = this.baseColumnsWidth + totalMetadataWidth;

    // Set table and header row dimensions
    Object.assign(this.headerRow.style, {
      width: `${totalWidth}px`,
    });

    Object.assign(table.style, {
      width: `${totalWidth}px`,
      tableLayout: "fixed",
    });

    // Apply sticky positioning to base header cells
    this.baseHeaderElements.forEach((th, index) => {
      this.stickyManager.applyToHeaderCell(th, index);
    });

    if (this.baseColumnsWidth > 0) {
      this.measureRetryCount = 0;
    }

    // If measurements failed because the table is hidden, retry a few times
    if (
      this.baseColumnsWidth === 0 &&
      this.measureRetryCount < this.constructor.constants.MAX_MEASURE_RETRIES &&
      !this.isRetrying
    ) {
      this.isRetrying = true;
      this.measureRetryCount += 1;
      requestAnimationFrame(() => {
        this.isRetrying = false;
        // Ensure controller is still connected before retrying
        if (!this.element.isConnected) return;
        this.initializeDimensions();
        this.render();
      });
    }

    return true;
  }

  /**
   * Set up MutationObserver to detect when deferred templates are added to the DOM
   */
  setupDeferredTemplateObserver() {
    if (!this.hasTemplateContainerTarget) return;

    this.deferredObserver = new MutationObserver((mutations) => {
      // Check if any added nodes have data-deferred attribute
      const hasDeferredContent = mutations.some((mutation) =>
        Array.from(mutation.addedNodes).some(
          (node) =>
            node.nodeType === Node.ELEMENT_NODE &&
            node.dataset?.deferred === "true",
        ),
      );

      if (hasDeferredContent) {
        // Use setTimeout to ensure all mutations are processed
        setTimeout(() => {
          // Guard against execution after controller disconnect
          if (!this.element?.isConnected) return;
          this.mergeDeferredTemplates();
        }, 0);
      }
    });

    // Observe the template container for child additions
    this.deferredObserver.observe(this.templateContainerTarget, {
      childList: true,
      subtree: false,
    });
  }

  /**
   * Merge deferred templates into main container and re-render visible cells
   */
  mergeDeferredTemplates() {
    if (!this.hasTemplateContainerTarget) return;

    try {
      // Find all deferred template containers
      const deferredContainers = this.templateContainerTarget.querySelectorAll(
        '[data-deferred="true"]',
      );

      if (deferredContainers.length === 0) return;

      // Merge deferred templates into existing sample containers
      deferredContainers.forEach((deferredContainer) => {
        const sampleId = deferredContainer.dataset.sampleId;
        const mainContainer = this.templateContainerTarget.querySelector(
          `[data-sample-id="${sampleId}"]:not([data-deferred])`,
        );

        if (mainContainer) {
          // Move all template children from deferred to main container
          Array.from(deferredContainer.children).forEach((template) => {
            mainContainer.appendChild(template);
          });

          // Remove deferred container
          deferredContainer.remove();
        }
      });

      // Re-render visible range to replace placeholders with real cells
      this.replaceVisiblePlaceholders();
    } catch (error) {
      // Dispatch error event for monitoring
      this.element.dispatchEvent(
        new CustomEvent("virtual-scroll:error", {
          detail: { error, context: "mergeDeferredTemplates" },
        }),
      );
    }
  }

  /**
   * Replace placeholder cells in visible range with real cells from templates
   */
  replaceVisiblePlaceholders() {
    if (!this.hasBodyTarget) return;

    const rows = this.bodyTarget.querySelectorAll(
      '[data-virtual-scroll-target="row"]',
    );

    rows.forEach((row) => {
      const placeholders = row.querySelectorAll('[data-placeholder="true"]');

      if (placeholders.length === 0) return;

      const sampleId = row.dataset.sampleId;
      const templates = this.templateContainerTarget?.querySelector(
        `[data-sample-id="${sampleId}"]`,
      );

      placeholders.forEach((placeholder) => {
        const field = placeholder.dataset.fieldId;
        if (!field) return;

        const selector = `template[data-field="${CSS.escape(field)}"]`;
        const template = templates?.querySelector(selector);

        if (!template) return; // Still not available

        // Clone real cell from template
        const clonedContent = template.content.cloneNode(true);
        const realCell = clonedContent.firstElementChild;

        if (!realCell) return;

        // Copy attributes from placeholder
        realCell.dataset.virtualizedCell = "true";
        realCell.dataset.fieldId = field;

        // Apply styles from placeholder
        realCell.style.cssText = placeholder.style.cssText;

        // Copy ARIA attributes
        if (placeholder.hasAttribute("aria-colindex")) {
          realCell.setAttribute(
            "aria-colindex",
            placeholder.getAttribute("aria-colindex"),
          );
        }

        // Replace placeholder with real cell
        placeholder.replaceWith(realCell);
      });
    });
  }

  /**
   * Stimulus lifecycle: Disconnect and cleanup
   */
  disconnect() {
    this.element.removeEventListener("click", this.boundHandleSort, true);
    this.element.removeEventListener("keydown", this.boundHandleKeydown, true);
    this.element.removeEventListener(
      "dblclick",
      this.boundHandleDblClick,
      true,
    );
    document.removeEventListener("turbo:before-cache", this.boundHideLoading);

    // Cleanup MutationObserver for deferred templates
    if (this.deferredObserver) {
      this.deferredObserver.disconnect();
      this.deferredObserver = null;
    }

    this.containerTarget.removeEventListener("scroll", this.handleScroll);

    // Cancel RAF if pending
    this.rafPending = false;

    this.debouncedResizeHandler?.cancel?.();

    // Cleanup Turbo event listener
    if (this.boundHandleTurboRender) {
      document.removeEventListener("turbo:render", this.boundHandleTurboRender);
    }

    if (this.boundRestoreSortFocusAfterLoad) {
      document.removeEventListener(
        "turbo:load",
        this.boundRestoreSortFocusAfterLoad,
      );

      document.removeEventListener(
        "turbo:render",
        this.boundRestoreSortFocusAfterLoad,
      );
    }

    // Cleanup ResizeObserver to prevent memory leaks
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
      this.resizeObserver = null;
    }

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

  restorePendingFocusFromSessionStorage() {
    try {
      const raw = sessionStorage.getItem(SORT_FOCUS_STORAGE_KEY);
      if (!raw) return;

      const data = JSON.parse(raw);
      sessionStorage.removeItem(SORT_FOCUS_STORAGE_KEY);

      if (!data || typeof data !== "object") return;
      if (data.path && data.path !== window.location.pathname) return;
      if (
        !Number.isInteger(data.ts) ||
        Date.now() - data.ts > SORT_FOCUS_TTL_MS
      )
        return;

      if (Number.isInteger(data.row) && Number.isInteger(data.col)) {
        this.pendingFocusRow = data.row;
        this.pendingFocusCol = data.col;
        this.sortFocusToRestore = { row: data.row, col: data.col };
      }
    } catch {
      // Ignore storage errors
    }
  }

  focusCellIfNeeded(rowIndex, colIndex) {
    const tableElement = this.element.querySelector("table");
    const focusRoot = tableElement || this.bodyTarget;
    if (!focusRoot) return false;

    const row = focusRoot.querySelector(`[aria-rowindex="${rowIndex}"]`);
    const cell = row?.querySelector?.(`[aria-colindex="${colIndex}"]`);
    if (!cell) return false;

    const activeCell = document.activeElement?.closest?.("[aria-colindex]");
    if (activeCell === cell) return true;

    // Ensure roving tabindex points at the cell
    focusRoot.querySelectorAll("[aria-colindex]").forEach((node) => {
      node.tabIndex = -1;
    });
    cell.tabIndex = 0;
    cell.focus();

    if (this.keyboardNavigator) {
      this.keyboardNavigator.focusedRowIndex = rowIndex;
      this.keyboardNavigator.focusedColIndex = colIndex;
    }

    return true;
  }

  rememberPendingFocusFromSortLink(link) {
    try {
      const headerCell = link.closest('[role="columnheader"][aria-colindex]');
      if (!headerCell) return;

      const col = parseInt(headerCell.getAttribute("aria-colindex"), 10);
      if (!Number.isInteger(col)) return;

      sessionStorage.setItem(
        SORT_FOCUS_STORAGE_KEY,
        JSON.stringify({
          path: window.location.pathname,
          ts: Date.now(),
          row: 1,
          col,
        }),
      );
    } catch {
      // Ignore storage errors
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
    // Don't handle resize during initialization
    if (this.isInitializing || !this.isInitialized) {
      return;
    }

    if (!this.baseHeaderElements || this.baseHeaderElements.length === 0)
      return;

    // Detect if sticky column count should change based on breakpoint
    const maxStickyColumns = Math.min(
      this.stickyColumnCountValue ?? this.numBaseColumns,
      this.numBaseColumns,
    );
    const newStickyColumnCount = this.detectStickyColumnCount(maxStickyColumns);
    if (newStickyColumnCount !== this.numStickyColumns) {
      this.numStickyColumns = newStickyColumnCount;
    }

    // Re-measure base column widths in case they changed
    this.baseColumnWidths = this.baseHeaderElements.map((th) => {
      const width = th.offsetWidth;
      if (width > 0) {
        th.style.width = `${width}px`;
      }
      return width;
    });
    this.baseColumnsWidth = this.baseColumnWidths.reduce((a, b) => a + b, 0);

    // Recalculate sticky column left positions
    this.stickyColumnLefts = this.baseColumnWidths.map((_, idx) => {
      if (idx >= this.numStickyColumns) return null;
      return this.baseColumnWidths.slice(0, idx).reduce((a, b) => a + b, 0);
    });

    // Update utilities with new measurements
    if (this.geometry) {
      this.geometry.updateColumnWidths(this.metadataColumnWidths);
    }
    if (this.stickyManager) {
      this.stickyManager.updateColumnWidths(this.baseColumnWidths);
      this.stickyManager.updateStickyCount(this.numStickyColumns);
    }
    if (this.cellRenderer) {
      this.cellRenderer.updateColumnWidths(this.metadataColumnWidths);
    }

    // Clear row visible ranges to force full re-render
    this.rowVisibleRanges.clear();

    // Trigger re-render with new measurements
    this.render();
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
    if (!this.isInitialized) return;

    // Re-measure if needed (e.g. if initialized while hidden)
    if (this.baseColumnsWidth === 0 || this.baseColumnsWidth === undefined) {
      this.handleResize();
    }
    if (this.baseColumnsWidth === 0) return;

    // Capture current focus if it's in the grid and we don't have a pending focus
    if (this.pendingFocusRow === null || this.pendingFocusCol === null) {
      const activeElement = document.activeElement;
      const tableElement = this.element.querySelector("table");
      if (activeElement && tableElement?.contains?.(activeElement)) {
        const row = activeElement.closest("[aria-rowindex]");
        const cell = activeElement.closest("[aria-colindex]");
        if (row && cell) {
          this.pendingFocusRow = parseInt(row.getAttribute("aria-rowindex"));
          this.pendingFocusCol = parseInt(cell.getAttribute("aria-colindex"));
        }
      }
    }

    const stickyColumnsWidth = this.baseColumnWidths
      .slice(0, this.numStickyColumns)
      .reduce((a, b) => a + b, 0);

    const scrollLeft = this.containerTarget.scrollLeft;
    const metadataAreaScrollLeft = Math.max(
      0,
      scrollLeft + stickyColumnsWidth - this.baseColumnsWidth,
    );

    // Use cumulative width calculation instead of fixed width division
    let firstVisibleMetadataColumn = Math.max(
      0,
      this.geometry.findColumnAtPosition(metadataAreaScrollLeft) -
        this.constructor.constants.BUFFER_COLUMNS,
    );

    // Calculate how many columns fit in viewport using variable widths
    // Always use the full container width because the container is scrollable
    // and metadata columns can be horizontally scrolled into view
    let visibleWidth = 0;
    let visibleColumnCount = 0;

    for (
      let i = firstVisibleMetadataColumn;
      i < this.metadataColumnWidths.length;
      i++
    ) {
      visibleWidth += this.metadataColumnWidths[i];
      visibleColumnCount++;
      if (visibleWidth >= this.containerTarget.clientWidth) break;
    }

    visibleColumnCount += 2 * this.constructor.constants.BUFFER_COLUMNS; // Add buffer on both sides

    let lastVisibleMetadataColumn = Math.min(
      this.numMetadataColumns,
      firstVisibleMetadataColumn + visibleColumnCount,
    );

    const activeEditingColumnIndex = this.getActiveEditingColumnIndex();
    if (activeEditingColumnIndex !== null && activeEditingColumnIndex >= 0) {
      if (activeEditingColumnIndex < firstVisibleMetadataColumn) {
        firstVisibleMetadataColumn = activeEditingColumnIndex;
      }
      if (activeEditingColumnIndex >= lastVisibleMetadataColumn) {
        lastVisibleMetadataColumn = Math.min(
          this.numMetadataColumns,
          activeEditingColumnIndex + 1,
        );
      }
    }

    // Store the global visible range for quick early exit
    const globalRangeChanged =
      this.lastFirstVisible !== firstVisibleMetadataColumn ||
      this.lastLastVisible !== lastVisibleMetadataColumn;

    this.lastFirstVisible = firstVisibleMetadataColumn;
    this.lastLastVisible = lastVisibleMetadataColumn;

    // --- Update Header Sticky Positioning ---
    // Headers are rendered server-side, just update sticky positioning for base columns
    this.baseHeaderElements.forEach((th, idx) => {
      this.stickyManager.applyToHeaderCell(th, idx);
    });

    // --- Render Body Rows ---
    // Check if templateContainer is available
    if (!this.hasTemplateContainerTarget) {
      // Dispatch error event for monitoring
      this.element.dispatchEvent(
        new CustomEvent("virtual-scroll:error", {
          detail: { message: "Template container not found" },
        }),
      );
    }

    this.rowTargets.forEach((row, rowIndex) => {
      const rowId = row.dataset.sampleId;

      // Check if this row's visible range changed
      const cachedRange = this.rowVisibleRanges.get(rowId);
      const rangeChanged =
        !cachedRange ||
        cachedRange.first !== firstVisibleMetadataColumn ||
        cachedRange.last !== lastVisibleMetadataColumn;

      // Skip this row if visible range unchanged
      if (!rangeChanged && !globalRangeChanged) {
        return;
      }

      // Update cached range
      this.rowVisibleRanges.set(rowId, {
        first: firstVisibleMetadataColumn,
        last: lastVisibleMetadataColumn,
      });

      // Render cells using VirtualScrollCellRenderer utility
      this.cellRenderer.renderRowCells(row, {
        firstVisible: firstVisibleMetadataColumn,
        lastVisible: lastVisibleMetadataColumn,
        templateContainer: this.templateContainerTarget,
      });

      // Apply sticky styles to base columns
      this.applyStickyStylesToRow(row);
    });

    // Ensure a single focus target is available after render
    this.applyRovingTabindex(this.pendingFocusRow, this.pendingFocusCol);

    // If a pending focus target exists, set focus explicitly after tabindex reset
    if (
      Number.isInteger(this.pendingFocusRow) &&
      Number.isInteger(this.pendingFocusCol)
    ) {
      const tableElement = this.element.querySelector("table");
      const focusRoot = tableElement || this.bodyTarget;
      const row = focusRoot?.querySelector?.(
        `[aria-rowindex="${this.pendingFocusRow}"]`,
      );
      const cell = row?.querySelector?.(
        `[aria-colindex="${this.pendingFocusCol}"]`,
      );
      if (cell) {
        cell.tabIndex = 0;
        cell.focus();
        if (this.keyboardNavigator) {
          this.keyboardNavigator.focusedRowIndex = this.pendingFocusRow;
          this.keyboardNavigator.focusedColIndex = this.pendingFocusCol;
        }
      }
    }

    this.pendingFocusRow = null;
    this.pendingFocusCol = null;
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
   * Ensure a metadata column is rendered and scrolled into view for focus
   * @param {number} colIndex 1-based column index across all columns
   */
  ensureMetadataColumnVisible(colIndex) {
    if (colIndex <= this.numBaseColumns) return;
    const metadataIndex = colIndex - this.numBaseColumns - 1;
    if (metadataIndex < 0 || metadataIndex >= this.numMetadataColumns) return;

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

    // Check if already fully visible
    if (absoluteColLeft >= visibleStart && absoluteColRight <= visibleEnd) {
      return;
    }

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
    const maxTries = 5;

    for (let i = 0; i < maxTries; i += 1) {
      // Remember intended focus so post-render roving tabindex can honor it
      // Reset on each iteration because render() clears it
      this.pendingFocusRow = rowIndex;
      this.pendingFocusCol = colIndex;

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
      let row = this.bodyTarget?.querySelector?.(
        `[aria-rowindex="${rowIndex}"]`,
      );
      let cell = row?.querySelector?.(`[aria-colindex="${colIndex}"]`);

      if (cell) {
        // Ensure it's focused (render might have done it, but to be safe)
        cell.focus();
        return true;
      }

      // Give the DOM a frame to materialize
      // Intentional sequential await - we need to wait for each frame before retrying
      // eslint-disable-next-line no-await-in-loop
      await new Promise((resolve) => requestAnimationFrame(resolve));

      row = this.bodyTarget?.querySelector?.(`[aria-rowindex="${rowIndex}"]`);
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

  rememberPendingFocusFromSortKeydown(event) {
    // When keyboard-navigation activates sorting, focus can be lost on Turbo refresh.
    // Store the currently focused column header so we can re-focus after render.
    if (!event || (event.key !== "Enter" && event.key !== " ")) return;

    const cell = event.target?.closest?.(
      '[role="columnheader"][aria-colindex]',
    );
    if (!cell || !this.element.contains(cell)) return;

    const link = cell.querySelector("a[href]");
    if (!link) return;

    // Only persist focus for Turbo replace navigations (sorting links)
    if (link.dataset?.turboAction !== "replace") return;

    this.rememberPendingFocusFromSortLink(link);
  }

  handleDblClick(event) {
    if (this.keyboardNavigator) {
      this.keyboardNavigator.handleDblClick(event);
    }
  }

  totalColumnCount() {
    return (this.numBaseColumns || 0) + (this.numMetadataColumns || 0);
  }
}
