import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

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
  ];

  COLUMN_WIDTH = 250; // pixels - fallback for unmeasured columns
  BUFFER_COLUMNS = 3; // Number of columns to render outside viewport on each side
  TAILWIND_2XL_BREAKPOINT = 1536; // pixels
  measureRetryCount = 0;
  MAX_MEASURE_RETRIES = 5;

  /**
   * Stimulus lifecycle: Connect controller and initialize
   */
  connect() {
    this.boundHandleSort = this.handleSort.bind(this);
    this.element.addEventListener("click", this.boundHandleSort);

    this.boundHideLoading = this.hideLoading.bind(this);
    document.addEventListener("turbo:before-cache", this.boundHideLoading);

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

    // Debounced handlers
    this.handleScroll = _.debounce(() => {
      this.boundRender();
    }, 50);
    this.debouncedResizeHandler = _.debounce(this.boundHandleResize, 100);

    this.containerTarget.addEventListener("scroll", this.handleScroll);

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

    // Reset state and re-render
    this.lastFirstVisible = undefined;
    this.lastLastVisible = undefined;

    // Re-initialize dimensions in case the DOM structure changed
    requestAnimationFrame(() => {
      this.initializeDimensions();
      this.render();
    });
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
    this.numStickyColumns = Math.min(
      this.stickyColumnCountValue ?? this.numBaseColumns,
      this.numBaseColumns,
    );

    const table = this.element.querySelector("table");
    if (!table) return false;

    const headerCells = Array.from(this.headerRow.querySelectorAll("th"));
    this.baseHeaderElements = headerCells.slice(0, this.numBaseColumns);

    // Measure base column widths
    this.baseColumnWidths = this.baseHeaderElements.map((th, idx) => {
      const width = th.getBoundingClientRect().width;
      // Explicitly set width for base columns to prevent them from resizing
      if (width > 0) {
        th.style.width = `${width}px`;
      }
      th.style.boxSizing = "border-box";

      if (idx < this.numStickyColumns) {
        // Ensure the sticky header cell keeps its stacking context
        th.style.position = "sticky";
        th.style.top = "0px";
        th.style.zIndex = "10";
        th.dataset.fixed = "true";
      } else {
        th.dataset.fixed = "false";
        th.style.position = "";
        th.style.left = "";
        th.style.zIndex = "";
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
      const width = th.getBoundingClientRect().width || this.COLUMN_WIDTH;
      // Explicitly set width for metadata headers to prevent them from resizing
      th.style.width = `${width}px`;
      th.style.minWidth = `${width}px`;
      th.style.maxWidth = `${width}px`;
      th.style.boxSizing = "border-box";
      return width;
    });

    // If no metadata columns measured yet, use COLUMN_WIDTH as fallback
    if (this.metadataColumnWidths.length === 0) {
      this.metadataColumnWidths = Array(this.numMetadataColumns).fill(
        this.COLUMN_WIDTH,
      );
    }

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

    this.headerRow.style.width = `${totalWidth}px`;
    table.style.width = `${totalWidth}px`;
    table.style.tableLayout = "fixed";

    // Apply explicit left offsets for the sticky headers so their `left` matches
    // the computed pixel values instead of relying on CSS variables which can
    // get out of sync when we set explicit widths.
    this.baseHeaderElements.forEach((th, index) => {
      th.style.display = "table-cell";
      th.style.boxSizing = "border-box";
      if (index < this.numStickyColumns) {
        th.style.left = `${this.stickyColumnLefts[index]}px`;
        th.style.position = "sticky";
        th.style.top = "0px";
        th.style.zIndex = "10";
        th.dataset.fixed = "true";
      } else {
        th.style.left = "";
        th.style.position = "";
        th.style.zIndex = "";
        th.dataset.fixed = "false";
      }
    });

    if (this.baseColumnsWidth > 0) {
      this.measureRetryCount = 0;
    }

    // If measurements failed because the table is hidden, retry a few times
    if (
      this.baseColumnsWidth === 0 &&
      this.measureRetryCount < this.MAX_MEASURE_RETRIES
    ) {
      this.measureRetryCount += 1;
      requestAnimationFrame(() => {
        this.initializeDimensions();
        this.render();
      });
    }

    return true;
  }

  /**
   * Stimulus lifecycle: Disconnect and cleanup
   */
  disconnect() {
    this.element.removeEventListener("click", this.boundHandleSort);
    document.removeEventListener("turbo:before-cache", this.boundHideLoading);

    this.containerTarget.removeEventListener("scroll", this.handleScroll);
    this.handleScroll?.cancel?.();
    this.debouncedResizeHandler?.cancel?.();

    // Cleanup Turbo event listener
    if (this.boundHandleTurboRender) {
      document.removeEventListener("turbo:render", this.boundHandleTurboRender);
    }

    // Cleanup ResizeObserver to prevent memory leaks
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
      this.resizeObserver = null;
    }
  }

  /**
   * Handle sort clicks to show loading overlay
   * @param {Event} event - Click event
   */
  handleSort(event) {
    const link = event.target.closest("a[href]");
    if (link && this.headerTarget.contains(link)) {
      if (link.dataset.turboAction === "replace") {
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
    // Don't handle resize during initialization
    if (this.isInitializing || !this.isInitialized) {
      return;
    }

    if (!this.baseHeaderElements || this.baseHeaderElements.length === 0)
      return;

    // Detect if sticky column count should change based on breakpoint
    const newStickyColumnCount = this.detectStickyColumnCount();
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

    // Trigger re-render with new measurements
    this.render();
  }

  /**
   * Detect sticky column count based on window width
   * @returns {number} Number of sticky columns (2 at @2xl+, 1 below)
   */
  detectStickyColumnCount() {
    if (window.innerWidth >= this.TAILWIND_2XL_BREAKPOINT) {
      return Math.min(2, this.numBaseColumns);
    }
    return Math.min(1, this.numBaseColumns);
  }

  /**
   * Find column index at a given scroll position using cumulative widths
   * @param {number} scrollLeft - Scroll position in pixels
   * @returns {number} Column index at that position
   */
  findColumnIndexAtPosition(scrollLeft) {
    let cumulative = 0;
    for (let i = 0; i < this.metadataColumnWidths.length; i++) {
      cumulative += this.metadataColumnWidths[i];
      if (cumulative > scrollLeft) {
        return i;
      }
    }
    return this.metadataColumnWidths.length - 1;
  }

  /**
   * Calculate cumulative width up to a given column index
   * @param {number} columnIndex - Column index
   * @returns {number} Cumulative width in pixels
   */
  cumulativeWidthToColumn(columnIndex) {
    return this.metadataColumnWidths
      .slice(0, columnIndex)
      .reduce((a, b) => a + b, 0);
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
      this.findColumnIndexAtPosition(metadataAreaScrollLeft) -
        this.BUFFER_COLUMNS,
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

    visibleColumnCount += 2 * this.BUFFER_COLUMNS; // Add buffer on both sides

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

    // Skip re-rendering if the visible column range hasn't changed
    if (
      this.lastFirstVisible === firstVisibleMetadataColumn &&
      this.lastLastVisible === lastVisibleMetadataColumn
    ) {
      return;
    }

    this.lastFirstVisible = firstVisibleMetadataColumn;
    this.lastLastVisible = lastVisibleMetadataColumn;

    // --- Update Header Sticky Positioning ---
    // Headers are rendered server-side, just update sticky positioning for base columns
    this.baseHeaderElements.forEach((th, idx) => {
      if (idx < this.numStickyColumns) {
        th.style.left = `${this.stickyColumnLefts[idx]}px`;
        th.style.position = "sticky";
        th.style.top = "0px";
        th.style.zIndex = "20"; // Highest priority for sticky headers
        th.dataset.fixed = "true";
      } else {
        th.style.left = "";
        th.style.position = "";
        th.style.zIndex = "";
        th.dataset.fixed = "false";
      }
    });

    // --- Render Body Rows ---
    // Check if templateContainer is available for debugging
    if (!this.hasTemplateContainerTarget) {
      console.error(
        "[virtual-scroll] templateContainer target not found! Templates cannot be loaded.",
      );
    }

    this.rowTargets.forEach((row, rowIndex) => {
      // Check for the cell currently being edited so we can preserve it
      const editingCellInfo = this.getRowEditingCellInfo(row);
      const editingCellNode = editingCellInfo?.cell ?? null;

      // Get sample ID from the row's data attribute to look up templates
      const sampleId = row.dataset.sampleId;

      // Get templates from the template container (stored outside table to avoid HTML5 foster parenting)
      const templateContainer = this.hasTemplateContainerTarget
        ? this.templateContainerTarget.querySelector(
            `[data-sample-id="${sampleId}"]`,
          )
        : null;

      // Collect all non-template children
      const allChildren = Array.from(row.children).filter(
        (c) => c.tagName.toLowerCase() !== "template",
      );

      // Identify base columns vs virtualized cells
      // Base columns do NOT have the data-virtualized-cell attribute
      // and are th/td elements at the start of the row (not spacers or metadata cells)
      const baseColumns = [];
      const virtualizedCells = [];

      for (const child of allChildren) {
        // Check if this is a virtualized cell (spacer or metadata cell we previously added)
        if (child.dataset.virtualizedCell) {
          virtualizedCells.push(child);
        } else if (baseColumns.length < this.numBaseColumns) {
          // This is a base column (not virtualized, and we haven't collected all base columns yet)
          baseColumns.push(child);
        } else {
          // This shouldn't happen, but treat it as virtualized
          virtualizedCells.push(child);
        }
      }

      // Index existing virtualized cells by fieldId for reuse to reduce DOM churn
      const reusableCells = new Map();
      for (const cell of virtualizedCells) {
        const fieldId = cell.dataset.fieldId;
        if (editingCellNode && cell === editingCellNode) continue;
        if (fieldId) {
          reusableCells.set(fieldId, cell);
        }
      }

      // Remove non-reused virtualized cells
      for (const cell of virtualizedCells) {
        if (editingCellNode && cell === editingCellNode) continue;
        if (!reusableCells.has(cell.dataset.fieldId)) {
          cell.remove();
        }
      }

      // Build a fragment: append base columns, then virtualized metadata cells, spacers, and templates
      const rowFrag = document.createDocumentFragment();

      // Append base column cells back in original order
      baseColumns.forEach((el) => rowFrag.appendChild(el));

      // Start spacer - use colspan to span hidden columns
      if (firstVisibleMetadataColumn > 0) {
        const startSpacer = document.createElement("td");
        // Use colspan to span all hidden columns - this maintains table column alignment
        startSpacer.colSpan = firstVisibleMetadataColumn;
        startSpacer.dataset.virtualizedCell = "true";
        startSpacer.style.padding = "0";
        startSpacer.style.border = "none";
        rowFrag.appendChild(startSpacer);
      }

      // Virtualized metadata cells from templates with measured widths
      for (
        let i = firstVisibleMetadataColumn;
        i < lastVisibleMetadataColumn;
        i++
      ) {
        const field = this.metadataFieldsValue[i];
        if (!field) {
          continue;
        }

        if (
          editingCellInfo &&
          editingCellInfo.columnIndex === i &&
          editingCellNode
        ) {
          this.applyMetadataCellStyles(editingCellNode, i);
          editingCellNode.dataset.virtualizedCell = "true";
          rowFrag.appendChild(editingCellNode);
          continue;
        }

        const selector = `template[data-field="${CSS.escape(field)}"]`;
        const template = templateContainer
          ? templateContainer.querySelector(selector)
          : null;
        const reusable = reusableCells.get(field);
        if (reusable) {
          this.applyMetadataCellStyles(reusable, i);
          reusable.dataset.virtualizedCell = "true";
          rowFrag.appendChild(reusable);
          reusableCells.delete(field);
          continue;
        }

        if (!template) {
          continue;
        }

        // Clone the entire template content as a DocumentFragment, then extract first element
        // This preserves the original template content properly
        const clonedContent = template.content.cloneNode(true);
        const cellElement = clonedContent.firstElementChild;

        if (!cellElement) {
          continue;
        }

        cellElement.dataset.virtualizedCell = "true";
        cellElement.dataset.fieldId = field; // Add field ID for editable_cell_controller
        this.applyMetadataCellStyles(cellElement, i);
        rowFrag.appendChild(cellElement);
      }

      // End spacer - use colspan to span remaining columns
      if (lastVisibleMetadataColumn < this.numMetadataColumns) {
        const endSpacer = document.createElement("td");
        // Use colspan to span all remaining columns
        endSpacer.colSpan = this.numMetadataColumns - lastVisibleMetadataColumn;
        endSpacer.dataset.virtualizedCell = "true";
        endSpacer.style.padding = "0";
        endSpacer.style.border = "none";
        rowFrag.appendChild(endSpacer);
      }

      // Templates are now stored in a separate container outside the table,
      // so no need to reattach them to the row

      // Count how many non-template children we're adding
      const fragChildren = Array.from(rowFrag.childNodes).filter(
        (c) => c.nodeType === 1 && c.tagName.toLowerCase() !== "template",
      );

      // Replace row children with the fragment
      while (row.firstChild) row.removeChild(row.firstChild);
      row.appendChild(rowFrag);

      // Re-apply left/position/z-index and width to the sticky cells now at the start
      const newChildren = Array.from(row.children).filter(
        (c) => c.tagName.toLowerCase() !== "template",
      );
      for (let i = 0; i < this.numStickyColumns; i++) {
        const child = newChildren[i];
        if (!child) continue;
        child.dataset.fixed = "true";
        child.style.left = `${this.stickyColumnLefts[i]}px`;
        child.style.width = `${this.baseColumnWidths[i]}px`;
        child.style.display = "table-cell";
        child.style.boxSizing = "border-box";
        child.style.position = "sticky";
        // body fixed cells should be below header but above virtualized
        child.style.zIndex = "10";
      }

      // Ensure remaining base columns (non-sticky) keep their widths but scroll normally
      for (let i = this.numStickyColumns; i < this.numBaseColumns; i++) {
        const child = newChildren[i];
        if (!child) continue;
        child.dataset.fixed = "false";
        child.style.position = "";
        child.style.left = "";
        child.style.zIndex = "";
        child.style.width = `${this.baseColumnWidths[i]}px`;
        child.style.display = "table-cell";
        child.style.boxSizing = "border-box";
      }
    });
  }

  getActiveEditingColumnIndex() {
    const editingCell = this.findEditingCellInElement(this.bodyTarget);
    if (!editingCell) return null;
    const fieldId = editingCell.dataset.fieldId;
    if (!fieldId) return null;
    const columnIndex = this.metadataFieldIndex?.get(fieldId);
    return columnIndex ?? null;
  }

  getRowEditingCellInfo(row) {
    const editingCell = this.findEditingCellInElement(row);
    if (!editingCell) return null;
    const fieldId = editingCell.dataset.fieldId;
    if (!fieldId) return null;
    const columnIndex = this.metadataFieldIndex?.get(fieldId);
    if (columnIndex === undefined) return null;
    return { cell: editingCell, columnIndex };
  }

  findEditingCellInElement(root) {
    if (!root) return null;
    const markedEditingCell = root.querySelector?.('[data-editing="true"]');
    if (markedEditingCell) {
      return markedEditingCell;
    }

    const activeElement = document.activeElement;
    if (!activeElement || !(activeElement instanceof Element)) {
      return null;
    }
    if (!root.contains(activeElement)) {
      return null;
    }
    return activeElement.closest("[data-field-id]");
  }

  applyMetadataCellStyles(cell, columnIndex) {
    // With table-layout: fixed and colspan spacers, widths are inherited from headers
    // Just ensure proper display and stacking
    cell.style.display = "table-cell";
    cell.style.boxSizing = "border-box";
    const width = this.metadataColumnWidths[columnIndex] ?? this.COLUMN_WIDTH;
    cell.style.width = `${width}px`;
    cell.style.minWidth = `${width}px`;
    cell.style.maxWidth = `${width}px`;

    // Add ARIA colindex for accessibility (1-based, includes base columns)
    const ariaColindex = this.numBaseColumns + columnIndex + 1;
    cell.setAttribute("aria-colindex", ariaColindex);
  }
}
