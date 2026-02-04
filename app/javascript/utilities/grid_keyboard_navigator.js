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
 * Keymap summary (APG data grid):
 * - Arrow keys: move one cell
 * - Home/End: first/last column; Ctrl+Home/Ctrl+End: first/last row
 * - PageUp/PageDown: jump rows by pageJumpSize
 * - Enter/Space: activate cell (headers sort, links/buttons/cbs)
 * - Enter/F2/printable: enter edit mode on editable cells
 * - Tab: exits grid (roving tabindex keeps one tab stop)
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
  // Maximum number of focus attempts when navigating to virtualized cells
  static MAX_FOCUS_ATTEMPTS = 3;

  #focusedRowIndex;
  #focusedColIndex;
  #isNavigating;

  /**
   * Create a grid keyboard navigator
   * @param {Object} options - Configuration options
   * @param {HTMLElement} options.gridElement - The grid container element
   * @param {HTMLElement} options.bodyElement - The grid body element (tbody)
   * @param {HTMLElement} [options.rootElement] - Root element containing all grid rows/cells (e.g., table). Defaults to bodyElement.
   * @param {number} options.numBaseColumns - Number of non-virtualized columns
   * @param {number} options.totalColumns - Total number of columns (including metadata)
   * @param {number} [options.pageJumpSize=5] - Number of rows to jump on PageUp/PageDown
   * @param {Function} [options.onNavigate] - Async callback when navigating to row/column (for virtualization). Signature: (rowIndex, colIndex, attempt) => Promise<void>
   */
  constructor(options) {
    this.grid = options.gridElement;
    this.bodyElement = options.bodyElement;
    this.rootElement = options.rootElement || options.bodyElement;
    this.numBaseColumns = options.numBaseColumns || 0;
    this.totalColumns = options.totalColumns || 0;
    this.pageJumpSize = options.pageJumpSize || 5;
    this.onNavigate = options.onNavigate;

    this.#focusedRowIndex = null;
    this.#focusedColIndex = null;

    // Track when navigation is in progress to prevent focus reset during async operations
    this.#isNavigating = false;
  }

  get focusedRowIndex() {
    return this.#focusedRowIndex;
  }

  set focusedRowIndex(value) {
    this.#focusedRowIndex = value;
  }

  get focusedColIndex() {
    return this.#focusedColIndex;
  }

  set focusedColIndex(value) {
    this.#focusedColIndex = value;
  }

  get isNavigating() {
    return this.#isNavigating;
  }

  set isNavigating(value) {
    this.#isNavigating = value;
  }

  /**
   * Handle focusin events to restore tracked position when tabbing back into grid.
   * When the tracked cell is virtualized, tabIndex=0 is on the first visible cell.
   * This handler detects that case and navigates to the tracked position.
   * @param {FocusEvent} event - The focusin event
   */
  async handleFocusin(event) {
    const cell = event.target.closest?.("[aria-colindex]");
    if (!cell || !this.rootElement?.contains?.(cell)) return;

    // Don't interfere if cell is being edited
    if (cell.dataset.editing === "true") return;

    // Only restore position if focus came from OUTSIDE the grid (Tab navigation)
    // If relatedTarget is inside the grid, user is clicking/arrowing within - don't interfere
    const relatedTarget = event.relatedTarget;
    if (relatedTarget && this.rootElement?.contains?.(relatedTarget)) {
      return;
    }

    // Only act if we have a tracked position different from the focused cell
    if (
      !Number.isInteger(this.focusedRowIndex) ||
      !Number.isInteger(this.focusedColIndex)
    ) {
      return;
    }

    const currentRow = this.getRowIndex(cell);
    const currentCol = this.getColIndex(cell);

    // If focus landed on our tracked position, nothing to do
    if (
      currentRow === this.focusedRowIndex &&
      currentCol === this.focusedColIndex
    ) {
      return;
    }

    // Navigate to the tracked position (this handles virtualization)
    await this.navigateToCell(this.focusedRowIndex, this.focusedColIndex);
  }

  /**
   * Handle keydown events for grid navigation
   * @param {KeyboardEvent} event - The keydown event
   */
  async handleKeydown(event) {
    try {
      await this.#handleKeydownInternal(event);
    } catch (error) {
      // Log in development for debugging, silent in production
      if (
        typeof window !== "undefined" &&
        window.location?.hostname === "localhost"
      ) {
        console.warn("Grid navigation error:", error);
      }
    }
  }

  /**
   * Internal keydown handler implementation
   * @param {KeyboardEvent} event - The keydown event
   * @private
   */
  async #handleKeydownInternal(event) {
    const cell = event.target.closest("[aria-colindex]");
    if (!cell || !this.rootElement?.contains?.(cell)) return;

    const isEditing = cell.dataset.editing === "true";
    const ctrlOrMeta = event.ctrlKey || event.metaKey;
    const isArrowKey = [
      "ArrowRight",
      "ArrowLeft",
      "ArrowUp",
      "ArrowDown",
    ].includes(event.key);

    // Allow Ctrl+Arrow navigation even when editing (standard spreadsheet behaviour)
    const isCtrlArrow = ctrlOrMeta && isArrowKey;

    // If actively editing, ignore all keys EXCEPT Ctrl+Arrow (grid navigation escape hatch)
    if (isEditing && !isCtrlArrow) {
      return;
    }

    // If the currently focused cell (or any ancestor) is marked editing, block navigation
    // (unless it's Ctrl+Arrow which should navigate away from edit mode)
    const editingAncestor = cell.closest('[data-editing="true"]');
    if (editingAncestor && !isCtrlArrow) return;

    // If Ctrl+Arrow while editing, deactivate edit mode first (discard changes)
    if (isCtrlArrow && isEditing) {
      this.#deactivateEditModeForNavigation(cell);
    }

    // Check for edit activation keys on editable cells
    if (cell.dataset.editable === "true") {
      if (this.#isEditActivationKey(event)) {
        event.preventDefault();
        event.stopPropagation();
        this.#activateEditMode(cell, event);
        return;
      }
    }

    // Cell activation (Enter/Space) for non-editable interactions (sort, open link, toggle checkbox)
    if (
      (event.key === "Enter" || event.key === " ") &&
      !event.altKey &&
      !event.metaKey
    ) {
      // Let selection controller handle Shift+Space (row selection)
      if (event.key === " " && (event.shiftKey || event.ctrlKey)) return;

      const activated = this.#activateCell(cell, event);
      if (activated) {
        event.preventDefault();
        event.stopPropagation();
      }
      return;
    }

    // Let Tab move focus out of the grid (only arrow keys navigate within)
    if (event.key === "Tab") return;

    // Handle navigation keys
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

    const currentRow = this.getRowIndex(cell);
    const currentCol = this.getColIndex(cell);
    if (!Number.isInteger(currentRow) || !Number.isInteger(currentCol)) return;

    const currentRowElement = this.getRowElement(cell);
    const target = this.calculateTargetCell(
      event,
      currentRow,
      currentCol,
      currentRowElement,
    );

    if (target.row === currentRow && target.col === currentCol) return;

    if (event.key === "Home" && target.col === 1 && this.grid) {
      this.grid.scrollLeft = 0;
    }

    event.preventDefault();
    await this.navigateToCell(target.row, target.col, event);
  }

  /**
   * Handle double click events for grid interaction
   * @param {MouseEvent} event - The double click event
   */
  handleDblClick(event) {
    const cell = event.target.closest("[aria-colindex]");
    if (!cell || !this.bodyElement.contains(cell)) return;

    // Check if cell is editable
    if (cell.dataset.editable === "true") {
      event.preventDefault();
      event.stopPropagation();
      this.#activateEditMode(cell, event);
    }
  }

  /**
   * Calculate target cell coordinates based on key pressed
   * @param {KeyboardEvent} event - The keydown event
   * @param {number} currentRow - Current row index (1-based)
   * @param {number} currentCol - Current column index (1-based)
   * @returns {{row: number, col: number}} Target cell coordinates
   * @private
   */
  calculateTargetCell(event, currentRow, currentCol, currentRowElement) {
    let targetRow = currentRow;
    let targetCol = currentCol;

    const rowElements = this.getRowElements();
    const rowPosition = this.getRowPosition(rowElements, currentRowElement);
    const firstRow = this.getFirstRowIndex(rowElements);
    const lastRow = this.getLastRowIndex(rowElements);
    const lastCol = this.getLastColIndex(currentCol);
    const ctrlOrMeta = event.ctrlKey || event.metaKey;

    switch (event.key) {
      case "ArrowRight":
        targetCol = Math.min(lastCol, currentCol + 1);
        break;
      case "ArrowLeft":
        targetCol = Math.max(1, currentCol - 1);
        break;
      case "ArrowDown":
        if (rowPosition !== null) {
          const nextRow =
            rowElements[Math.min(rowElements.length - 1, rowPosition + 1)];
          targetRow = this.getRowIndexFromRow(nextRow) ?? currentRow;
        } else {
          targetRow = Math.min(lastRow, currentRow + 1);
        }
        break;
      case "ArrowUp":
        if (rowPosition !== null) {
          const prevRow = rowElements[Math.max(0, rowPosition - 1)];
          targetRow = this.getRowIndexFromRow(prevRow) ?? currentRow;
        } else {
          targetRow = Math.max(firstRow, currentRow - 1);
        }
        break;
      case "Home":
        targetCol = 1;
        if (ctrlOrMeta) targetRow = firstRow;
        break;
      case "End":
        targetCol = lastCol;
        if (ctrlOrMeta) targetRow = lastRow;
        break;
      case "PageUp":
        if (rowPosition !== null) {
          const nextPosition = Math.max(0, rowPosition - this.pageJumpSize);
          const nextRow = rowElements[nextPosition];
          targetRow = this.getRowIndexFromRow(nextRow) ?? currentRow;
        } else {
          targetRow = Math.max(firstRow, currentRow - this.pageJumpSize);
        }
        break;
      case "PageDown":
        if (rowPosition !== null) {
          const nextPosition = Math.min(
            rowElements.length - 1,
            rowPosition + this.pageJumpSize,
          );
          const nextRow = rowElements[nextPosition];
          targetRow = this.getRowIndexFromRow(nextRow) ?? currentRow;
        } else {
          targetRow = Math.min(lastRow, currentRow + this.pageJumpSize);
        }
        break;
    }

    return { row: targetRow, col: targetCol };
  }

  /**
   * Calculate target cell for Tab navigation.
   * Returns null to allow default Tab behaviour (leaving the grid).
   * @param {KeyboardEvent} event
   * @param {number} currentRow
   * @param {number} currentCol
   * @param {HTMLElement|null} currentRowElement
   * @returns {{row: number, col: number}|null}
   * @private
   */
  calculateTabTarget(event, currentRow, currentCol, currentRowElement) {
    const rowElements = this.getRowElements();
    const rowPosition = this.getRowPosition(rowElements, currentRowElement);
    const lastCol = this.getLastColIndex(currentCol);

    if (rowPosition === null || rowElements.length === 0) return null;

    if (event.shiftKey) {
      if (currentCol > 1) {
        return { row: currentRow, col: currentCol - 1 };
      }

      if (rowPosition > 0) {
        const prevRow = rowElements[rowPosition - 1];
        return {
          row: this.getRowIndexFromRow(prevRow) ?? currentRow,
          col: lastCol,
        };
      }

      return null;
    }

    if (currentCol < lastCol) {
      return { row: currentRow, col: currentCol + 1 };
    }

    if (rowPosition < rowElements.length - 1) {
      const nextRow = rowElements[rowPosition + 1];
      return { row: this.getRowIndexFromRow(nextRow) ?? currentRow, col: 1 };
    }

    return null;
  }

  /**
   * Navigate to a specific cell
   * @param {number} rowIndex - Target row index (1-based)
   * @param {number} colIndex - Target column index (1-based)
   */
  async navigateToCell(rowIndex, colIndex) {
    this.focusedRowIndex = rowIndex;
    this.focusedColIndex = colIndex;

    // Signal that navigation is in progress (prevents blur reset in table controller)
    this.isNavigating = true;
    this.#dispatchNavigationEvent("table:navigation-start");

    try {
      return await this.#attemptFocus(rowIndex, colIndex, 0);
    } finally {
      this.isNavigating = false;
      this.#dispatchNavigationEvent("table:navigation-end");
    }
  }

  /**
   * Dispatch a navigation event on the grid element
   * @param {string} eventName - Name of the event to dispatch
   * @private
   */
  #dispatchNavigationEvent(eventName) {
    const table = this.rootElement?.closest?.("table") || this.grid;
    table?.dispatchEvent?.(new CustomEvent(eventName, { bubbles: true }));
  }

  async #attemptFocus(rowIndex, colIndex, attempt) {
    let cell = this.findCell(rowIndex, colIndex);
    if (cell) {
      this.resetTabStops();
      cell.tabIndex = 0;
      cell.focus();
      return true;
    }

    if (this.onNavigate) {
      const ready = await this.onNavigate(rowIndex, colIndex, attempt);
      cell = this.findCell(rowIndex, colIndex);
      if (cell) {
        this.resetTabStops();
        cell.tabIndex = 0;
        cell.focus();
        return true;
      }

      // Retry up to MAX_FOCUS_ATTEMPTS times to allow virtualized cells to render
      const maxAttempts = this.constructor.MAX_FOCUS_ATTEMPTS;
      if (attempt < maxAttempts && ready !== false) {
        return this.#attemptFocus(rowIndex, colIndex, attempt + 1);
      }
    }

    return false;
  }

  /**
   * Apply roving tabindex pattern to the grid
   * Sets one cell to tabIndex=0, all others to tabIndex=-1
   * Also restores focus if the currently focused element is no longer in the DOM
   * (can happen when cells are destroyed and recreated during re-render)
   * Per APG pattern: only one focusable element in the grid is in the tab sequence
   * @param {number} [fallbackRowIndex] - Row to focus if no active cell
   * @param {number} [fallbackColIndex] - Column to focus if no active cell
   */
  applyRovingTabindex(fallbackRowIndex, fallbackColIndex) {
    // Check if the currently focused element is detached (e.g., destroyed during re-render)
    const activeElement = document.activeElement;
    const focusWasInGrid =
      activeElement && activeElement.closest?.("[aria-colindex]");
    const focusIsDetached =
      focusWasInGrid && !document.body.contains(activeElement);

    // Track if explicit coordinates were provided (vs. derived from active cell)
    const hasExplicitCoordinates =
      Number.isInteger(fallbackRowIndex) && Number.isInteger(fallbackColIndex);

    // If explicit fallback provided, prefer it; otherwise derive from active cell
    if (hasExplicitCoordinates) {
      this.focusedRowIndex = fallbackRowIndex;
      this.focusedColIndex = fallbackColIndex;
    } else {
      const activeCell = this.getActiveGridCell();
      if (activeCell) {
        this.focusedRowIndex = this.getRowIndex(activeCell);
        this.focusedColIndex = this.getColIndex(activeCell);
      }
    }

    // Default to first header cell (row 1, col 1) per APG single tab stop pattern
    const firstRowIndex = this.getFirstRowIndex();
    if (!this.focusedRowIndex)
      this.focusedRowIndex = fallbackRowIndex ?? firstRowIndex;
    if (!this.focusedColIndex) this.focusedColIndex = fallbackColIndex ?? 1;

    this.resetTabStops();

    let targetCell = this.findCell(this.focusedRowIndex, this.focusedColIndex);

    if (!targetCell) {
      // Check if we have valid tracked coordinates to preserve
      const hasTrackedPosition =
        Number.isInteger(this.focusedRowIndex) &&
        Number.isInteger(this.focusedColIndex);

      // Preserve tracked position when the cell is temporarily virtualized.
      // This ensures the user returns to their last position when tabbing back in.
      // Only truly fall back to first cell on initial load when no position is tracked.
      if (hasExplicitCoordinates || this.isNavigating || hasTrackedPosition) {
        const a11yCell =
          this.rootElement.querySelector("thead [aria-colindex]") ||
          this.bodyElement.querySelector("[aria-colindex]");
        if (a11yCell) {
          a11yCell.tabIndex = 0;

          // If focus was lost due to DOM removal, keep focus inside the grid
          if (focusIsDetached) {
            a11yCell.focus();
          }
        }
        // Don't update focusedRowIndex/focusedColIndex - preserve target for when user tabs back
        return;
      }

      // Fallback to first cell in grid (header row first, then body)
      // Only reached on initial load when no position has been tracked yet
      targetCell =
        this.rootElement.querySelector("thead [aria-colindex]") ||
        this.bodyElement.querySelector("[aria-colindex]");
    }

    if (targetCell) {
      targetCell.tabIndex = 0;
      this.focusedRowIndex = this.getRowIndex(targetCell);
      this.focusedColIndex = this.getColIndex(targetCell);

      // Restore focus if the previously focused element was destroyed during re-render
      // This prevents focus from escaping the grid when cells are recreated
      if (focusIsDetached) {
        targetCell.focus();
      }
    }
  }

  /**
   * Reset all gridcells to tabindex=-1
   * @private
   */
  resetTabStops() {
    this.rootElement?.querySelectorAll("[aria-colindex]").forEach((node) => {
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
    const row = this.rootElement.querySelector(`[aria-rowindex="${rowIndex}"]`);
    if (!row) return null;

    const directCell = row.querySelector(`[aria-colindex="${colIndex}"]`);
    if (directCell) return directCell;

    const isVirtualizedRow =
      typeof this.onNavigate === "function" &&
      row.dataset?.virtualScrollTarget === "row";

    if (isVirtualizedRow) return null;

    return this.findClosestCellInRow(row, colIndex);
  }

  /**
   * Find the closest available cell within a row when exact colindex is missing
   * (e.g., rows with colspans like footer rows).
   * @param {HTMLElement} row
   * @param {number} colIndex
   * @returns {HTMLElement|null}
   * @private
   */
  findClosestCellInRow(row, colIndex) {
    const cells = Array.from(row.querySelectorAll("[aria-colindex]"));
    if (cells.length === 0) return null;

    let bestCell = null;
    let bestDistance = Infinity;

    cells.forEach((cell) => {
      const idx = this.getColIndex(cell);
      if (!Number.isInteger(idx)) return;

      const distance = Math.abs(idx - colIndex);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestCell = cell;
      }
    });

    return bestCell || null;
  }

  /**
   * Get the first row index in the grid
   * @returns {number} First row index (1-based)
   * @private
   */
  getFirstRowIndex(rowElements = this.getRowElements()) {
    if (rowElements.length === 0) return 1;
    const firstRow = rowElements[0];
    const parsed = this.getRowIndexFromRow(firstRow);
    return Number.isInteger(parsed) ? parsed : 1;
  }

  /**
   * Get the last row index in the grid
   * @returns {number} Last row index (1-based)
   * @private
   */
  getLastRowIndex(rowElements = this.getRowElements()) {
    if (rowElements.length === 0) return 1;
    const lastRow = rowElements[rowElements.length - 1];
    const parsed = this.getRowIndexFromRow(lastRow);
    return Number.isInteger(parsed) ? parsed : rowElements.length;
  }

  /**
   * Get all rows that participate in grid navigation.
   * Includes header (thead) rows per APG data grid pattern, excludes footer (tfoot) rows.
   * @returns {HTMLElement[]} row elements in DOM order
   * @private
   */
  getRowElements() {
    const allRows = Array.from(
      this.rootElement?.querySelectorAll?.("[aria-rowindex]") || [],
    );

    // Include thead rows for navigation per APG pattern, exclude tfoot
    return allRows.filter((row) => !row.closest("tfoot"));
  }

  /**
   * Get row element for a cell.
   * @param {HTMLElement} cell
   * @returns {HTMLElement|null}
   * @private
   */
  getRowElement(cell) {
    return cell?.closest?.("[aria-rowindex]") || null;
  }

  /**
   * Get 1-based row index from a row element.
   * @param {HTMLElement|null} row
   * @returns {number|null}
   * @private
   */
  getRowIndexFromRow(row) {
    if (!row) return null;
    const idx = parseInt(row.getAttribute("aria-rowindex"), 10);
    return Number.isInteger(idx) ? idx : null;
  }

  /**
   * Get the row's position within the rowElements list.
   * @param {HTMLElement[]} rowElements
   * @param {HTMLElement|null} row
   * @returns {number|null}
   * @private
   */
  getRowPosition(rowElements, row) {
    if (!row || rowElements.length === 0) return null;
    const position = rowElements.indexOf(row);
    return position >= 0 ? position : null;
  }

  /**
   * Get the last column index in the grid
   * @param {number} fallbackColIndex - Column to fall back to when counts unknown
   * @returns {number} Last column index (1-based)
   * @private
   */
  getLastColIndex(fallbackColIndex) {
    if (Number.isInteger(this.totalColumns) && this.totalColumns > 0) {
      return this.totalColumns;
    }

    const colCount = parseInt(this.grid?.getAttribute?.("aria-colcount"), 10);
    if (Number.isInteger(colCount) && colCount > 0) return colCount;

    const rootColCount = parseInt(
      this.rootElement?.getAttribute?.("aria-colcount"),
      10,
    );
    if (Number.isInteger(rootColCount) && rootColCount > 0) return rootColCount;

    return fallbackColIndex || 1;
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

  /**
   * Check if key is an edit activation key (Enter)
   * @param {KeyboardEvent} event - The keydown event
   * @returns {boolean} True if key should activate edit mode
   * @private
   */
  #isEditActivationKey(event) {
    if (!event) return false;

    if (event.key === "Enter" || event.key === "F2") return true;

    // Printable characters (except Space) should also activate edit mode
    return (
      typeof event.key === "string" &&
      event.key.length === 1 &&
      event.key !== " " &&
      !event.ctrlKey &&
      !event.metaKey &&
      !event.altKey
    );
  }

  /**
   * Activate the focused cell's primary interaction.
   * - Column headers: activate sort link (Enter/Space)
   * - Cells with checkboxes: toggle checkbox (Space; also Enter if no better action)
   * - Cells with links/buttons: click (Enter)
   * @param {HTMLElement} cell
   * @param {KeyboardEvent} event
   * @returns {boolean}
   */
  #activateCell(cell, event) {
    if (!cell) return false;

    const isHeader = cell.getAttribute("role") === "columnheader";
    const checkbox = cell.querySelector('input[type="checkbox"]');
    const link = cell.querySelector("a[href]");
    const button = cell.querySelector("button:not([disabled])");

    if (event.key === " ") {
      // Prefer toggling checkbox on Space
      if (checkbox && !checkbox.disabled) {
        checkbox.click();
        return true;
      }
      // Allow Space to activate sort headers as button-like controls
      if (isHeader && link) {
        link.click();
        return true;
      }
      return false;
    }

    // Enter
    if (isHeader && link) {
      link.click();
      return true;
    }

    if (button) {
      button.click();
      return true;
    }

    if (link) {
      link.click();
      return true;
    }

    if (checkbox && !checkbox.disabled) {
      checkbox.click();
      return true;
    }

    return false;
  }

  /**
   * Activate edit mode on a cell
   * @param {HTMLElement} cell - The cell to activate edit mode on
   * @param {Event} event - The triggering event
   * @private
   */
  #activateEditMode(cell, event) {
    cell.dataset.editing = "true";
    cell.setAttribute("contenteditable", "true");
    cell.setAttribute("aria-readonly", "false");

    const seedText = this.#seedTextFromEvent(event);
    if (seedText) {
      cell.textContent = seedText;
    }

    // Focus the cell
    cell.focus();

    // Select all text in the cell to provide visual feedback
    // This ensures the cursor is visible and the user can start typing immediately
    const selection = window.getSelection();
    const range = document.createRange();
    range.selectNodeContents(cell);

    if (seedText) {
      range.collapse(false);
    }

    selection.removeAllRanges();
    selection.addRange(range);

    // Dispatch custom event for screen reader announcement
    cell.dispatchEvent(
      new CustomEvent("edit-mode-activated", { bubbles: true }),
    );
  }

  #seedTextFromEvent(event) {
    if (!event || typeof event.key !== "string") return "";

    if (
      event.key.length === 1 &&
      event.key !== " " &&
      !event.ctrlKey &&
      !event.metaKey &&
      !event.altKey
    ) {
      return event.key;
    }

    return "";
  }

  /**
   * Deactivate edit mode on a cell when navigating away via Ctrl+Arrow.
   * Dispatches a reset event so the editable cell controller can restore
   * original content before blur fires (avoiding confirm dialog).
   * @param {HTMLElement} cell - The cell to deactivate edit mode on
   * @private
   */
  #deactivateEditModeForNavigation(cell) {
    if (!cell) return;

    // Dispatch event to request content reset before deactivating
    // VirtualizedEditableCellController listens for this to restore original content
    cell.dispatchEvent(
      new CustomEvent("grid:navigation-reset", { bubbles: true }),
    );

    delete cell.dataset.editing;
    cell.setAttribute("contenteditable", "false");
    cell.removeAttribute("aria-readonly");

    // Dispatch event for screen reader announcement
    cell.dispatchEvent(
      new CustomEvent("edit-mode-deactivated", { bubbles: true }),
    );
  }
}
