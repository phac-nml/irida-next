import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

/**
 * VirtualScrollController
 *
 * Implements virtualized horizontal scrolling for tables with large numbers of metadata columns.
 * Only renders visible columns plus a buffer, maintaining sticky columns and all existing functionality.
 *
 * Features:
 * - Variable-width column support (measures actual DOM widths)
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

  static targets = ["container", "header", "body", "row"];

  COLUMN_WIDTH = 150; // pixels - fallback for unmeasured columns
  BUFFER_COLUMNS = 3; // Number of columns to render outside viewport on each side
  TAILWIND_2XL_BREAKPOINT = 1536; // pixels

  /**
   * Stimulus lifecycle: Connect controller and initialize
   */
  connect() {
    this.boundRender = this.render.bind(this);
    this.handleScroll = _.debounce(this.boundRender, 50);
    this.boundHandleResize = this.handleResize.bind(this);
    this.hasAutoScrolled = false;

    // Initialize metadata column widths array
    this.metadataColumnWidths = [];

    this.containerTarget.addEventListener("scroll", this.handleScroll);

    // Initialize ResizeObserver for responsive behavior
    this.resizeObserver = new ResizeObserver(
      _.debounce(this.boundHandleResize, 100),
    );
    this.resizeObserver.observe(this.containerTarget);

    requestAnimationFrame(() => {
      this.initializeDimensions();
      this.render();
      // Auto-scroll to sorted column if applicable
      this.scrollToSortedColumn();
    });
  }

  /**
   * Initialize dimensions by measuring actual column widths from DOM
   * Supports variable-width columns instead of fixed COLUMN_WIDTH
   */
  initializeDimensions() {
    this.headerRow = this.headerTarget.querySelector("tr");
    this.numBaseColumns = this.fixedColumnsValue.length;
    this.numMetadataColumns = this.metadataFieldsValue.length;
    this.numStickyColumns = Math.min(
      this.stickyColumnCountValue ?? this.numBaseColumns,
      this.numBaseColumns,
    );

    const table = this.element.querySelector("table");

    const headerCells = Array.from(this.headerRow.querySelectorAll("th"));
    this.baseHeaderElements = headerCells.slice(0, this.numBaseColumns);

    // Measure base column widths
    this.baseColumnWidths = this.baseHeaderElements.map((th, idx) => {
      const width = th.offsetWidth;
      // Explicitly set width for base columns to prevent them from resizing
      th.style.width = `${width}px`;
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
      return th.offsetWidth || this.COLUMN_WIDTH; // Use measured width or fallback
    });

    // If no metadata columns measured yet, use COLUMN_WIDTH as fallback
    if (this.metadataColumnWidths.length === 0) {
      this.metadataColumnWidths = Array(this.numMetadataColumns).fill(
        this.COLUMN_WIDTH,
      );
    }

    // Extract and prepare metadata header templates with measured widths
    this.metadataHeaderTemplates = metadataHeaders.map((th, idx) => {
      const clone = th.cloneNode(true);
      clone.dataset.virtualizedCell = true;
      const measuredWidth = this.metadataColumnWidths[idx] || this.COLUMN_WIDTH;
      clone.style.width = `${measuredWidth}px`;
      clone.style.display = "table-cell";
      clone.style.boxSizing = "border-box";
      // Make sure virtualized header cells don't cover the fixed columns
      clone.style.zIndex = "1";
      return clone;
    });

    // Remove original metadata headers from DOM
    metadataHeaders.forEach((th) => th.remove());

    // Keep references to the original base header elements so we can
    // re-prepend them during render to guarantee they stay at the start
    // of the header row (avoids virtualized cells being inserted before them).
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
  }

  /**
   * Stimulus lifecycle: Disconnect and cleanup
   */
  disconnect() {
    this.containerTarget.removeEventListener("scroll", this.handleScroll);

    // Cleanup ResizeObserver to prevent memory leaks
    if (this.resizeObserver) {
      this.resizeObserver.disconnect();
      this.resizeObserver = null;
    }
  }

  /**
   * Handle resize events - re-measure and re-render
   */
  handleResize() {
    // Detect if sticky column count should change based on breakpoint
    const newStickyColumnCount = this.detectStickyColumnCount();
    if (newStickyColumnCount !== this.numStickyColumns) {
      this.numStickyColumns = newStickyColumnCount;
    }

    // Re-measure base column widths in case they changed
    this.baseColumnWidths = this.baseHeaderElements.map((th) => {
      return th.offsetWidth;
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

    // Find column index in metadata fields
    const columnIndex = this.metadataFieldsValue.indexOf(fieldName);
    if (columnIndex === -1) return; // Field not found

    // Calculate scroll position to make column "just visible" on right edge
    const cumulativeWidth = this.cumulativeWidthToColumn(columnIndex);
    const columnWidth =
      this.metadataColumnWidths[columnIndex] || this.COLUMN_WIDTH;

    // Position column at right edge of viewport with small padding
    const padding = 16; // pixels
    const targetScrollLeft =
      this.baseColumnsWidth +
      cumulativeWidth +
      columnWidth -
      this.containerTarget.clientWidth +
      padding;

    // Clamp to valid range
    const maxScroll = Math.max(
      0,
      this.containerTarget.scrollWidth - this.containerTarget.clientWidth,
    );
    const clampedScroll = Math.max(0, Math.min(maxScroll, targetScrollLeft));

    // Apply scroll
    this.containerTarget.scrollLeft = clampedScroll;
  }

  /**
   * Main render method - updates visible columns based on scroll position
   */
  render() {
    if (this.baseColumnsWidth === undefined) return;

    const scrollLeft = this.containerTarget.scrollLeft;
    const metadataAreaScrollLeft = Math.max(
      0,
      scrollLeft - this.baseColumnsWidth,
    );

    // Use cumulative width calculation instead of fixed width division
    const firstVisibleMetadataColumn = Math.max(
      0,
      this.findColumnIndexAtPosition(metadataAreaScrollLeft) -
        this.BUFFER_COLUMNS,
    );

    // Calculate how many columns fit in viewport using variable widths
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

    const lastVisibleMetadataColumn = Math.min(
      this.numMetadataColumns,
      firstVisibleMetadataColumn + visibleColumnCount,
    );

    // --- Render Header ---
    const headerFragment = document.createDocumentFragment();

    // Append fixed header elements (use stored references to avoid cloning)
    this.baseHeaderElements.forEach((th, idx) => {
      th.style.width = `${this.baseColumnWidths[idx]}px`;
      th.style.display = "table-cell";
      th.style.boxSizing = "border-box";

      if (idx < this.numStickyColumns) {
        th.style.left = `${this.stickyColumnLefts[idx]}px`;
        th.style.position = "sticky";
        th.style.top = "0px";
        // header should be highest
        th.style.zIndex = "20";
        th.dataset.fixed = "true";
      } else {
        th.style.left = "";
        th.style.position = "";
        th.style.zIndex = "";
        th.dataset.fixed = "false";
      }

      headerFragment.appendChild(th);
    });

    // Header Start Spacer - use cumulative measured widths
    if (firstVisibleMetadataColumn > 0) {
      const startSpacer = document.createElement("th");
      const spacerWidth = this.cumulativeWidthToColumn(
        firstVisibleMetadataColumn,
      );
      startSpacer.style.width = `${spacerWidth}px`;
      startSpacer.style.display = "table-cell";
      startSpacer.dataset.virtualizedCell = true;
      startSpacer.style.zIndex = "1";
      headerFragment.appendChild(startSpacer);
    }

    // Header virtualized cells with measured widths
    for (
      let i = firstVisibleMetadataColumn;
      i < lastVisibleMetadataColumn;
      i++
    ) {
      if (this.metadataHeaderTemplates[i]) {
        const clone = this.metadataHeaderTemplates[i].cloneNode(true);
        // Ensure measured width is applied
        const measuredWidth =
          this.metadataColumnWidths[i] || this.COLUMN_WIDTH;
        clone.style.width = `${measuredWidth}px`;
        headerFragment.appendChild(clone);
      }
    }

    // Header End Spacer - use cumulative measured widths
    if (lastVisibleMetadataColumn < this.numMetadataColumns) {
      const endSpacer = document.createElement("th");
      const remainingWidth = this.metadataColumnWidths
        .slice(lastVisibleMetadataColumn)
        .reduce((a, b) => a + b, 0);
      endSpacer.style.width = `${remainingWidth}px`;
      endSpacer.style.display = "table-cell";
      endSpacer.dataset.virtualizedCell = true;
      endSpacer.style.zIndex = "1";
      headerFragment.appendChild(endSpacer);
    }

    // Replace headerRow children with our ordered fragment
    while (this.headerRow.firstChild)
      this.headerRow.removeChild(this.headerRow.firstChild);
    this.headerRow.appendChild(headerFragment);

    // --- Render Body Rows ---
    this.rowTargets.forEach((row) => {
      // Check for cells currently being edited - protect from virtualization
      const editingCells = Array.from(
        row.querySelectorAll('[contenteditable="true"]'),
      );
      const editingCellIndices = editingCells.map((cell) => {
        const cellIndex = cell.cellIndex;
        // Calculate metadata column index (subtract base columns)
        return cellIndex - this.numBaseColumns;
      });

      // Remove any previously-rendered virtualized cells (except editing cells)
      row.querySelectorAll("[data-virtualized-cell]").forEach((cell) => {
        // Don't remove if it's being edited
        if (cell.getAttribute("contenteditable") !== "true") {
          cell.remove();
        }
      });

      // Keep templates aside so we can reattach them
      const templates = Array.from(
        row.querySelectorAll("template[data-field]"),
      );

      // Collect non-template children (these are the normal column cells)
      const nonTemplateChildren = Array.from(row.children).filter(
        (c) => c.tagName.toLowerCase() !== "template",
      );

      // Build a fragment: keep all non-template children (preserve order), then
      // insert virtualized metadata cells, then end spacer, then templates.
      const rowFrag = document.createDocumentFragment();

      // Append all non-template children back in original order
      nonTemplateChildren.forEach((el) => rowFrag.appendChild(el));

      // Start spacer - use cumulative measured widths
      if (firstVisibleMetadataColumn > 0) {
        const startSpacer = document.createElement("td");
        const spacerWidth = this.cumulativeWidthToColumn(
          firstVisibleMetadataColumn,
        );
        startSpacer.style.width = `${spacerWidth}px`;
        startSpacer.style.display = "table-cell";
        startSpacer.dataset.virtualizedCell = true;
        startSpacer.style.zIndex = "1";
        rowFrag.appendChild(startSpacer);
      }

      // Virtualized metadata cells from templates with measured widths
      for (
        let i = firstVisibleMetadataColumn;
        i < lastVisibleMetadataColumn;
        i++
      ) {
        const field = this.metadataFieldsValue[i];
        if (!field) continue;

        // Check if this cell is currently being edited
        if (editingCellIndices.includes(i)) {
          // Keep existing editing cell, don't create new one
          continue;
        }

        const selector = `template[data-field="${CSS.escape(field)}"]`;
        const template =
          row.querySelector(selector) ||
          templates.find((t) => t.dataset.field === field);
        if (template) {
          const cellElement =
            template.content.firstElementChild.cloneNode(true);
          cellElement.dataset.virtualizedCell = true;
          cellElement.dataset.fieldId = field; // Add field ID for editable_cell_controller
          const measuredWidth =
            this.metadataColumnWidths[i] || this.COLUMN_WIDTH;
          cellElement.style.width = `${measuredWidth}px`;
          cellElement.style.display = "table-cell";
          cellElement.style.boxSizing = "border-box";
          cellElement.style.zIndex = "1";
          rowFrag.appendChild(cellElement);
        } else {
          console.error(
            `Template not found for row ${row.dataset.sampleId} and field ${field}`,
          );
        }
      }

      // End spacer - use cumulative measured widths
      if (lastVisibleMetadataColumn < this.numMetadataColumns) {
        const endSpacer = document.createElement("td");
        const remainingWidth = this.metadataColumnWidths
          .slice(lastVisibleMetadataColumn)
          .reduce((a, b) => a + b, 0);
        endSpacer.style.width = `${remainingWidth}px`;
        endSpacer.style.display = "table-cell";
        endSpacer.dataset.virtualizedCell = true;
        endSpacer.style.zIndex = "1";
        rowFrag.appendChild(endSpacer);
      }

      // Finally reattach templates (they must remain in the row for future clones)
      templates.forEach((t) => rowFrag.appendChild(t));

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
}
