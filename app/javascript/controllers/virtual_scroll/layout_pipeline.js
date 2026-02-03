// Virtual scroll layout pipeline.
// Extracted from VirtualScrollController to keep measurement logic focused.

import { VirtualScrollGeometry } from "utilities/virtual_scroll_geometry";
import { StickyColumnManager } from "utilities/sticky_column_manager";
import { VirtualScrollCellRenderer } from "utilities/virtual_scroll_cell_renderer";

export function initializeDimensions(controller) {
  if (!controller.headerTarget || !controller.bodyTarget) return false;
  if (
    !Array.isArray(controller.metadataFieldsValue) ||
    !Array.isArray(controller.fixedColumnsValue)
  )
    return false;

  controller.headerRow = controller.headerTarget.querySelector("tr");
  if (!controller.headerRow) return false;
  controller.numBaseColumns = controller.fixedColumnsValue.length;
  controller.numMetadataColumns = controller.metadataFieldsValue.length;
  controller.metadataFieldIndex = new Map();
  controller.metadataFieldsValue.forEach((field, index) => {
    controller.metadataFieldIndex.set(field, index);
  });
  const maxStickyColumns = Math.min(
    controller.stickyColumnCountValue ?? controller.numBaseColumns,
    controller.numBaseColumns,
  );
  controller.numStickyColumns =
    controller.detectStickyColumnCount(maxStickyColumns);

  const table = controller.element.querySelector("table");
  if (!table) return false;

  const headerCells = Array.from(controller.headerRow.querySelectorAll("th"));
  controller.baseHeaderElements = headerCells.slice(
    0,
    controller.numBaseColumns,
  );

  // Measure base column widths
  controller.baseColumnWidths = controller.baseHeaderElements.map((th, idx) => {
    const width = th.getBoundingClientRect().width;

    // Explicitly set width and box-sizing for base columns
    Object.assign(th.style, {
      width: width > 0 ? `${width}px` : "",
      boxSizing: "border-box",
    });

    if (idx < controller.numStickyColumns) {
      // Ensure the sticky header cell keeps its stacking context
      Object.assign(th.style, {
        position: "sticky",
        top: "0px",
        zIndex: String(controller.constructor.constants.STICKY_HEADER_Z_INDEX),
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
  controller.baseColumnsWidth = controller.baseColumnWidths.reduce(
    (a, b) => a + b,
    0,
  );

  controller.stretchBaseColumnsToContainer();

  // Compute explicit left offsets only for sticky columns so sticky positions
  // will align correctly even after we manipulate the DOM.
  controller.stickyColumnLefts = controller.baseColumnWidths.map((_, idx) => {
    if (idx >= controller.numStickyColumns) return null;
    return controller.baseColumnWidths.slice(0, idx).reduce((a, b) => a + b, 0);
  });

  // Measure actual metadata column widths from DOM
  const metadataHeaders = headerCells.slice(controller.numBaseColumns);
  controller.metadataColumnWidths = metadataHeaders.map((th) => {
    const width =
      th.getBoundingClientRect().width || controller.cssConfig.columnWidth;

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
  if (controller.metadataColumnWidths.length === 0) {
    controller.metadataColumnWidths = Array(controller.numMetadataColumns).fill(
      controller.cssConfig.columnWidth,
    );
  }

  // Initialize geometry calculator with measured column widths
  controller.geometry = new VirtualScrollGeometry(
    controller.metadataColumnWidths,
  );

  // Initialize sticky column manager
  controller.stickyManager = new StickyColumnManager({
    columnWidths: controller.baseColumnWidths,
    stickyCount: controller.numStickyColumns,
    headerZIndex: controller.constructor.constants.STICKY_HEADER_Z_INDEX,
    bodyZIndex: controller.constructor.constants.STICKY_BODY_Z_INDEX,
  });

  // Initialize cell renderer
  controller.cellRenderer = new VirtualScrollCellRenderer({
    metadataFields: controller.metadataFieldsValue,
    numBaseColumns: controller.numBaseColumns,
    metadataColumnWidths: controller.metadataColumnWidths,
    columnWidthFallback: controller.cssConfig.columnWidth,
  });

  if (controller.keyboardNavigator) {
    controller.keyboardNavigator.updateTotalColumns(
      controller.totalColumnCount(),
    );
  }

  // Keep all metadata headers in DOM (rendered server-side)
  // No need to virtualize headers - performance impact is minimal for 1000 headers
  controller.metadataHeaders = metadataHeaders;

  // Keep references to base header elements for sticky positioning updates
  controller.baseHeaderElements = headerCells.slice(
    0,
    controller.numBaseColumns,
  );

  // Calculate total metadata width using measured widths
  const totalMetadataWidth = controller.metadataColumnWidths.reduce(
    (a, b) => a + b,
    0,
  );
  const totalWidth = controller.calculateTotalTableWidth(totalMetadataWidth);

  // Set table and header row dimensions
  Object.assign(controller.headerRow.style, {
    width: `${totalWidth}px`,
  });

  Object.assign(table.style, {
    width: `${totalWidth}px`,
    tableLayout: "fixed",
  });

  // Apply sticky positioning to base header cells
  controller.baseHeaderElements.forEach((th, index) => {
    controller.stickyManager.applyToHeaderCell(th, index);
  });

  if (controller.baseColumnsWidth > 0) {
    controller.measureRetryCount = 0;
  }

  // If measurements failed because the table is hidden, retry a few times
  if (
    controller.baseColumnsWidth === 0 &&
    controller.measureRetryCount <
      controller.constructor.constants.MAX_MEASURE_RETRIES &&
    !controller.isRetrying
  ) {
    controller.isRetrying = true;
    controller.measureRetryCount += 1;
    requestAnimationFrame(() => {
      controller.isRetrying = false;
      // Ensure controller is still connected before retrying
      if (!controller.element.isConnected) return;
      initializeDimensions(controller);
      controller.render();
    });
  }

  return true;
}

export function handleResize(controller) {
  // Don't handle resize during initialization
  if (controller.isInitializing || !controller.isInitialized) {
    return;
  }

  if (
    !controller.baseHeaderElements ||
    controller.baseHeaderElements.length === 0
  )
    return;

  // Detect if sticky column count should change based on breakpoint
  const maxStickyColumns = Math.min(
    controller.stickyColumnCountValue ?? controller.numBaseColumns,
    controller.numBaseColumns,
  );
  const newStickyColumnCount =
    controller.detectStickyColumnCount(maxStickyColumns);
  if (newStickyColumnCount !== controller.numStickyColumns) {
    controller.numStickyColumns = newStickyColumnCount;
  }

  // Re-measure base column widths in case they changed
  controller.baseColumnWidths = controller.baseHeaderElements.map((th) => {
    const width = th.offsetWidth;
    if (width > 0) {
      th.style.width = `${width}px`;
    }
    return width;
  });
  controller.baseColumnsWidth = controller.baseColumnWidths.reduce(
    (a, b) => a + b,
    0,
  );

  controller.stretchBaseColumnsToContainer();

  // Recalculate sticky column left positions
  controller.stickyColumnLefts = controller.baseColumnWidths.map((_, idx) => {
    if (idx >= controller.numStickyColumns) return null;
    return controller.baseColumnWidths.slice(0, idx).reduce((a, b) => a + b, 0);
  });

  const totalMetadataWidth = controller.metadataColumnWidths.reduce(
    (a, b) => a + b,
    0,
  );
  const totalWidth = controller.calculateTotalTableWidth(totalMetadataWidth);
  const table = controller.element.querySelector("table");
  if (table && controller.headerRow) {
    controller.headerRow.style.width = `${totalWidth}px`;
    table.style.width = `${totalWidth}px`;
    table.style.tableLayout = "fixed";
  }

  // Update utilities with new measurements
  if (controller.geometry) {
    controller.geometry.updateColumnWidths(controller.metadataColumnWidths);
  }
  if (controller.stickyManager) {
    controller.stickyManager.updateColumnWidths(controller.baseColumnWidths);
    controller.stickyManager.updateStickyCount(controller.numStickyColumns);
  }
  if (controller.cellRenderer) {
    controller.cellRenderer.updateColumnWidths(controller.metadataColumnWidths);
  }

  // Clear row visible ranges to force full re-render
  controller.rowVisibleRanges.clear();

  // Trigger re-render with new measurements
  controller.render();
}
