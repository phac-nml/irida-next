// Virtual scroll render pipeline.
// Extracted from VirtualScrollController to keep render logic focused.

import { calculateVisibleRange } from "controllers/virtual_scroll/visible_range";

export function renderVirtualScroll(controller) {
  if (!controller.isInitialized) return;

  // Re-measure if needed (e.g. if initialized while hidden)
  if (
    controller.baseColumnsWidth === 0 ||
    controller.baseColumnsWidth === undefined
  ) {
    controller.handleResize();
  }
  if (controller.baseColumnsWidth === 0) return;

  // Capture current focus if it's in the grid and we don't have a pending focus
  if (
    controller.pendingFocusRow === null ||
    controller.pendingFocusCol === null
  ) {
    const activeElement = document.activeElement;
    const tableElement = controller.element.querySelector("table");
    if (activeElement && tableElement?.contains?.(activeElement)) {
      const row = activeElement.closest("[aria-rowindex]");
      const cell = activeElement.closest("[aria-colindex]");
      if (row && cell) {
        controller.pendingFocusRow = parseInt(
          row.getAttribute("aria-rowindex"),
          10,
        );
        controller.pendingFocusCol = parseInt(
          cell.getAttribute("aria-colindex"),
          10,
        );
      }
    }
  }

  const stickyColumnsWidth = controller.baseColumnWidths
    .slice(0, controller.numStickyColumns)
    .reduce((a, b) => a + b, 0);

  const scrollLeft = controller.containerTarget.scrollLeft;
  const metadataAreaScrollLeft = Math.max(
    0,
    scrollLeft + stickyColumnsWidth - controller.baseColumnsWidth,
  );

  const activeEditingColumnIndex = controller.getActiveEditingColumnIndex();

  // Convert pending focus column to metadata index for range calculation
  // pendingFocusCol is 1-based overall column index, we need 0-based metadata index
  // Also consider the keyboard navigator's tracked position as fallback (for when user tabs out)
  const trackedFocusCol =
    controller.pendingFocusCol ?? controller.keyboardNavigator?.focusedColIndex;
  const pendingFocusColumnIndex =
    Number.isInteger(trackedFocusCol) &&
    trackedFocusCol > controller.numBaseColumns
      ? trackedFocusCol - controller.numBaseColumns - 1
      : null;

  const {
    firstVisible: firstVisibleMetadataColumn,
    lastVisible: lastVisibleMetadataColumn,
  } = calculateVisibleRange({
    geometry: controller.geometry,
    metadataColumnWidths: controller.metadataColumnWidths,
    metadataAreaScrollLeft,
    containerWidth: controller.containerTarget.clientWidth,
    bufferColumns: controller.constructor.constants.BUFFER_COLUMNS,
    numMetadataColumns: controller.numMetadataColumns,
    activeEditingColumnIndex,
    pendingFocusColumnIndex,
  });

  // Store the global visible range for quick early exit
  const globalRangeChanged =
    controller.lastFirstVisible !== firstVisibleMetadataColumn ||
    controller.lastLastVisible !== lastVisibleMetadataColumn;

  controller.lastFirstVisible = firstVisibleMetadataColumn;
  controller.lastLastVisible = lastVisibleMetadataColumn;

  // --- Update Header Sticky Positioning ---
  // Headers are rendered server-side, just update sticky positioning for base columns
  controller.baseHeaderElements.forEach((th, idx) => {
    controller.stickyManager.applyToHeaderCell(th, idx);
  });

  // --- Render Body Rows ---
  // Check if templateContainer is available
  if (!controller.hasTemplateContainerTarget) {
    // Dispatch error event for monitoring
    controller.element.dispatchEvent(
      new CustomEvent("virtual-scroll:error", {
        detail: { message: "Template container not found" },
      }),
    );
  }

  controller.rowTargets.forEach((row) => {
    const rowId = row.dataset.sampleId;

    // Check if this row's visible range changed
    const cachedRange = controller.rowVisibleRanges.get(rowId);
    const rangeChanged =
      !cachedRange ||
      cachedRange.first !== firstVisibleMetadataColumn ||
      cachedRange.last !== lastVisibleMetadataColumn;

    // Skip this row if visible range unchanged
    if (!rangeChanged && !globalRangeChanged) {
      return;
    }

    // Update cached range
    controller.rowVisibleRanges.set(rowId, {
      first: firstVisibleMetadataColumn,
      last: lastVisibleMetadataColumn,
    });

    // Render cells using VirtualScrollCellRenderer utility
    controller.cellRenderer.renderRowCells(row, {
      firstVisible: firstVisibleMetadataColumn,
      lastVisible: lastVisibleMetadataColumn,
      templateContainer: controller.templateContainerTarget,
    });

    // Apply sticky styles to base columns
    controller.applyStickyStylesToRow(row);
  });

  const hasPendingFocus =
    Number.isInteger(controller.pendingFocusRow) &&
    Number.isInteger(controller.pendingFocusCol);
  const focusedPending = hasPendingFocus
    ? controller.focusCellIfNeeded(
        controller.pendingFocusRow,
        controller.pendingFocusCol,
      )
    : false;

  if (focusedPending) {
    controller.pendingFocusRow = null;
    controller.pendingFocusCol = null;
  }

  // Ensure a single focus target is available after render
  if (!focusedPending) {
    controller.applyRovingTabindex(
      controller.pendingFocusRow,
      controller.pendingFocusCol,
    );
  }
}
