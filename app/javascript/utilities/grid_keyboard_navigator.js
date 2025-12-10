/**
 * GridKeyboardNavigator
 *
 * Implements ARIA Grid keyboard navigation pattern for accessible tables.
 * Handles arrow keys, Home/End, PageUp/PageDown navigation with roving tabindex.
 *
 * Follows W3C ARIA Authoring Practices Guide (APG) for data grids:
 * https://www.w3.org/WAI/ARIA/apg/patterns/grid/
 *
 * Features:
 * - Arrow key navigation (Up/Down/Left/Right)
 * - Home/End navigation (with Ctrl for first/last row)
 * - PageUp/PageDown for jumping multiple rows
 * - Roving tabindex management
 * - Callback for ensuring virtualized columns are visible
 *
 * @example
 *   import { GridKeyboardNavigator } from "utilities/grid_keyboard_navigator";
 *
 *   const navigator = new GridKeyboardNavigator({
 *     gridElement: document.querySelector('[role="grid"]'),
 *     bodyElement: document.querySelector('tbody'),
 *     numBaseColumns: 3,
 *     totalColumns: 1003,
 *     pageJumpSize: 5,
 *     onNavigate: (colIndex) => {
 *       // Ensure virtualized column is visible
 *       virtualScroller.ensureColumnVisible(colIndex);
 *     }
 *   });
 *
 *   gridElement.addEventListener('keydown', (e) => navigator.handleKeydown(e));
 */
export class GridKeyboardNavigator {
  /**
   * Create a grid keyboard navigator
   * @param {Object} options - Configuration options
   * @param {HTMLElement} options.gridElement - The grid container element
   * @param {HTMLElement} options.bodyElement - The grid body element (tbody)
   * @param {number} options.numBaseColumns - Number of non-virtualized columns
   * @param {number} options.totalColumns - Total number of columns (including metadata)
   * @param {number} [options.pageJumpSize=5] - Number of rows to jump on PageUp/PageDown
   * @param {Function} [options.onNavigate] - Callback when navigating to column (for virtualization)
   */
  constructor(options) {
    this.grid = options.gridElement;
    this.bodyElement = options.bodyElement;
    this.numBaseColumns = options.numBaseColumns || 0;
    this.totalColumns = options.totalColumns || 0;
    this.pageJumpSize = options.pageJumpSize || 5;
    this.onNavigate = options.onNavigate;

    this.focusedRowIndex = null;
    this.focusedColIndex = null;
  }

  /**
   * Handle keydown events for grid navigation
   * @param {KeyboardEvent} event - The keydown event
   */
  handleKeydown(event) {
    const relevantKeys = [
      "ArrowRight",
      "ArrowLeft",
      "ArrowUp",
      "ArrowDown",
      "Home",
      "End",
      "PageUp",
      "PageDown",
    ];

    if (!relevantKeys.includes(event.key)) return;

    // Ignore if inside editable element
    if (
      event.target.closest(
        "input, textarea, select, button, [contenteditable='true']",
      )
    ) {
      return;
    }

    const cell = event.target.closest("[aria-colindex]");
    if (!cell || !this.bodyElement.contains(cell)) return;

    const currentRow = this.getRowIndex(cell);
    const currentCol = this.getColIndex(cell);
    if (!Number.isInteger(currentRow) || !Number.isInteger(currentCol)) return;

    const target = this.calculateTargetCell(event, currentRow, currentCol);

    if (target.row === currentRow && target.col === currentCol) return;

    event.preventDefault();
    this.navigateToCell(target.row, target.col);
  }

  /**
   * Calculate target cell coordinates based on key pressed
   * @param {KeyboardEvent} event - The keydown event
   * @param {number} currentRow - Current row index (1-based)
   * @param {number} currentCol - Current column index (1-based)
   * @returns {{row: number, col: number}} Target cell coordinates
   * @private
   */
  calculateTargetCell(event, currentRow, currentCol) {
    let targetRow = currentRow;
    let targetCol = currentCol;

    const firstRow = this.getFirstRowIndex();
    const lastRow = this.getLastRowIndex();

    switch (event.key) {
      case "ArrowRight":
        targetCol = Math.min(this.totalColumns, currentCol + 1);
        break;
      case "ArrowLeft":
        targetCol = Math.max(1, currentCol - 1);
        break;
      case "ArrowDown":
        targetRow = Math.min(lastRow, currentRow + 1);
        break;
      case "ArrowUp":
        targetRow = Math.max(firstRow, currentRow - 1);
        break;
      case "Home":
        targetCol = 1;
        if (event.ctrlKey) targetRow = firstRow;
        break;
      case "End":
        targetCol = this.totalColumns;
        if (event.ctrlKey) targetRow = lastRow;
        break;
      case "PageUp":
        targetRow = Math.max(firstRow, currentRow - this.pageJumpSize);
        break;
      case "PageDown":
        targetRow = Math.min(lastRow, currentRow + this.pageJumpSize);
        break;
    }

    return { row: targetRow, col: targetCol };
  }

  /**
   * Navigate to a specific cell
   * @param {number} rowIndex - Target row index (1-based)
   * @param {number} colIndex - Target column index (1-based)
   */
  navigateToCell(rowIndex, colIndex) {
    this.focusedRowIndex = rowIndex;
    this.focusedColIndex = colIndex;

    // Callback to ensure column is visible (for virtualization)
    if (colIndex > this.numBaseColumns && this.onNavigate) {
      this.onNavigate(colIndex);
    }

    const cell = this.findCell(rowIndex, colIndex);
    if (cell) {
      this.resetTabStops();
      cell.tabIndex = 0;
      cell.focus();
    }
  }

  /**
   * Apply roving tabindex pattern to the grid
   * Sets one cell to tabIndex=0, all others to tabIndex=-1
   * @param {number} [fallbackRowIndex] - Row to focus if no active cell
   * @param {number} [fallbackColIndex] - Column to focus if no active cell
   */
  applyRovingTabindex(fallbackRowIndex, fallbackColIndex) {
    // Determine current active cell within the grid if any
    const activeCell = this.getActiveGridCell();
    if (activeCell) {
      this.focusedRowIndex = this.getRowIndex(activeCell);
      this.focusedColIndex = this.getColIndex(activeCell);
    }

    const firstRowIndex = this.getFirstRowIndex();
    if (!this.focusedRowIndex)
      this.focusedRowIndex = fallbackRowIndex ?? firstRowIndex;
    if (!this.focusedColIndex) this.focusedColIndex = fallbackColIndex ?? 1;

    this.resetTabStops();

    let targetCell = this.findCell(this.focusedRowIndex, this.focusedColIndex);

    if (!targetCell) {
      // Fallback to first visible cell
      targetCell = this.bodyElement.querySelector("[aria-colindex]");
    }

    if (targetCell) {
      targetCell.tabIndex = 0;
      this.focusedRowIndex = this.getRowIndex(targetCell);
      this.focusedColIndex = this.getColIndex(targetCell);
    }
  }

  /**
   * Reset all gridcells to tabindex=-1
   * @private
   */
  resetTabStops() {
    this.bodyElement?.querySelectorAll("[aria-colindex]").forEach((node) => {
      node.tabIndex = -1;
    });
  }

  /**
   * Get the currently focused grid cell
   * @returns {HTMLElement|null} The active cell element or null
   * @private
   */
  getActiveGridCell() {
    const active = document.activeElement;
    if (!active) return null;
    return active.closest?.("[aria-colindex]") || null;
  }

  /**
   * Get row index from a cell element
   * @param {HTMLElement} cell - The cell element
   * @returns {number|null} 1-based row index or null
   * @private
   */
  getRowIndex(cell) {
    const row = cell?.closest?.("[aria-rowindex]");
    if (!row) return null;
    const idx = parseInt(row.getAttribute("aria-rowindex"), 10);
    return Number.isInteger(idx) ? idx : null;
  }

  /**
   * Get column index from a cell element
   * @param {HTMLElement} cell - The cell element
   * @returns {number|null} 1-based column index or null
   * @private
   */
  getColIndex(cell) {
    const idx = parseInt(cell?.getAttribute?.("aria-colindex"), 10);
    return Number.isInteger(idx) ? idx : null;
  }

  /**
   * Find a cell by row and column coordinates
   * @param {number} rowIndex - 1-based row index
   * @param {number} colIndex - 1-based column index
   * @returns {HTMLElement|null} The cell element or null
   * @private
   */
  findCell(rowIndex, colIndex) {
    const row = this.bodyElement.querySelector(`[aria-rowindex="${rowIndex}"]`);
    if (!row) return null;

    let cell = row.querySelector(`[aria-colindex="${colIndex}"]`);

    // If cell not found and it's a metadata column, trigger onNavigate callback
    // (might be virtualized and needs to be rendered)
    if (!cell && colIndex > this.numBaseColumns && this.onNavigate) {
      this.onNavigate(colIndex);
      // Try again after callback
      cell = row.querySelector(`[aria-colindex="${colIndex}"]`);
    }

    return cell;
  }

  /**
   * Get the first row index in the grid
   * @returns {number} First row index (1-based)
   * @private
   */
  getFirstRowIndex() {
    const rows = this.bodyElement.querySelectorAll("[aria-rowindex]");
    if (rows.length === 0) return 1;
    const firstRow = rows[0];
    const idx = firstRow?.getAttribute("aria-rowindex");
    const parsed = parseInt(idx, 10);
    return Number.isInteger(parsed) ? parsed : 1;
  }

  /**
   * Get the last row index in the grid
   * @returns {number} Last row index (1-based)
   * @private
   */
  getLastRowIndex() {
    const rows = this.bodyElement.querySelectorAll("[aria-rowindex]");
    if (rows.length === 0) return 1;
    const lastRow = rows[rows.length - 1];
    const idx = lastRow?.getAttribute("aria-rowindex");
    const parsed = parseInt(idx, 10);
    return Number.isInteger(parsed) ? parsed : rows.length;
  }

  /**
   * Get total number of columns
   * @returns {number} Total column count
   */
  getTotalColumns() {
    return this.totalColumns;
  }

  /**
   * Update total columns count (useful when columns change dynamically)
   * @param {number} newTotal - New total column count
   */
  updateTotalColumns(newTotal) {
    this.totalColumns = newTotal;
  }
}
