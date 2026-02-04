/**
 * StickyColumnManager
 *
 * Manages sticky column positioning for virtualized tables.
 * Handles left offset calculations and applies sticky positioning styles
 * to both header and body cells.
 *
 * Provides a centralized place for all sticky column logic, eliminating
 * repetitive style application code throughout the controller.
 *
 * @example
 *   import { StickyColumnManager } from "utilities/sticky_column_manager";
 *
 *   const stickyManager = new StickyColumnManager({
 *     columnWidths: [200, 150, 100],
 *     stickyCount: 2,
 *     headerZIndex: 20,
 *     bodyZIndex: 10
 *   });
 *
 *   // Apply to header cells
 *   headerCells.forEach((th, idx) => {
 *     stickyManager.applyToHeaderCell(th, idx);
 *   });
 *
 *   // Apply to body cells
 *   bodyCells.forEach((td, idx) => {
 *     stickyManager.applyToBodyCell(td, idx);
 *   });
 */
export class StickyColumnManager {
  /**
   * Create a sticky column manager
   * @param {Object} options - Configuration options
   * @param {number[]} options.columnWidths - Array of column widths in pixels
   * @param {number} options.stickyCount - Number of columns to make sticky
   * @param {number} [options.headerZIndex=20] - Z-index for sticky headers
   * @param {number} [options.bodyZIndex=10] - Z-index for sticky body cells
   */
  constructor(options) {
    this.columnWidths = options.columnWidths;
    this.stickyCount = options.stickyCount;
    this.headerZIndex = options.headerZIndex || 20;
    this.bodyZIndex = options.bodyZIndex || 10;
    this.stickyLeftOffsets = this.calculateLeftOffsets();
  }

  /**
   * Calculate left offsets for each sticky column
   * @returns {Array<number|null>} Left offset in pixels for each column (null for non-sticky)
   * @private
   */
  calculateLeftOffsets() {
    return this.columnWidths.map((_, idx) => {
      if (idx >= this.stickyCount) return null;
      return this.columnWidths.slice(0, idx).reduce((a, b) => a + b, 0);
    });
  }

  /**
   * Apply sticky positioning styles to a header cell
   * @param {HTMLElement} th - The header cell element
   * @param {number} index - Column index (0-based)
   */
  applyToHeaderCell(th, index) {
    const isSticky = index < this.stickyCount;
    const width = this.columnWidths[index];

    Object.assign(th.style, {
      display: "table-cell",
      boxSizing: "border-box",
      width: width ? `${width}px` : "",
    });

    if (isSticky) {
      Object.assign(th.style, {
        position: "sticky",
        top: "0px",
        left: `${this.stickyLeftOffsets[index]}px`,
        zIndex: String(this.headerZIndex),
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
  }

  /**
   * Apply sticky positioning styles to a body cell
   * @param {HTMLElement} td - The body cell element
   * @param {number} index - Column index (0-based)
   */
  applyToBodyCell(td, index) {
    const isSticky = index < this.stickyCount;
    const width = this.columnWidths[index];

    Object.assign(td.style, {
      display: "table-cell",
      boxSizing: "border-box",
      width: width ? `${width}px` : "",
    });

    if (isSticky) {
      Object.assign(td.style, {
        position: "sticky",
        left: `${this.stickyLeftOffsets[index]}px`,
        zIndex: String(this.bodyZIndex),
      });
      td.dataset.fixed = "true";
    } else {
      Object.assign(td.style, {
        position: "",
        left: "",
        zIndex: "",
      });
      td.dataset.fixed = "false";
    }
  }

  /**
   * Get total width of all sticky columns
   * @returns {number} Total width in pixels
   */
  getTotalWidth() {
    return this.columnWidths
      .slice(0, this.stickyCount)
      .reduce((acc, width) => acc + (width || 0), 0);
  }

  /**
   * Update column widths and recalculate offsets
   * Useful when columns are resized
   * @param {number[]} newColumnWidths - Updated array of column widths
   */
  updateColumnWidths(newColumnWidths) {
    this.columnWidths = newColumnWidths;
    this.stickyLeftOffsets = this.calculateLeftOffsets();
  }

  /**
   * Update sticky column count and recalculate offsets
   * Useful for responsive behaviour (e.g., fewer sticky columns on mobile)
   * @param {number} newStickyCount - New number of sticky columns
   */
  updateStickyCount(newStickyCount) {
    this.stickyCount = newStickyCount;
    this.stickyLeftOffsets = this.calculateLeftOffsets();
  }

  /**
   * Get left offset for a specific column
   * @param {number} index - Column index (0-based)
   * @returns {number|null} Left offset in pixels, or null if not sticky
   */
  getLeftOffset(index) {
    return this.stickyLeftOffsets[index] ?? null;
  }

  /**
   * Check if a column is sticky
   * @param {number} index - Column index (0-based)
   * @returns {boolean} True if column is sticky
   */
  isSticky(index) {
    return index < this.stickyCount;
  }
}
