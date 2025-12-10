/**
 * VirtualScrollGeometry
 *
 * Handles all geometry calculations for virtual scrolling including:
 * - Binary search for finding columns at scroll positions (O(log n))
 * - Cumulative width caching for fast lookups (O(1))
 * - Visible range calculation with buffer zones
 *
 * This utility is pure computational logic with no DOM dependencies,
 * making it highly testable and reusable across different virtualization scenarios.
 *
 * @example
 *   import { VirtualScrollGeometry } from "utilities/virtual_scroll_geometry";
 *
 *   const geometry = new VirtualScrollGeometry([100, 150, 100, 200]);
 *   const column = geometry.findColumnAtPosition(250); // Returns 2
 *   const range = geometry.calculateVisibleRange(100, 500, 3); // { firstVisible: 0, lastVisible: 5 }
 */
export class VirtualScrollGeometry {
  /**
   * Create a geometry calculator
   * @param {number[]} columnWidths - Array of column widths in pixels
   */
  constructor(columnWidths) {
    this.columnWidths = columnWidths;
    this.cumulativeWidths = this.buildCumulativeCache();
  }

  /**
   * Build cumulative widths cache for fast binary search
   * Cache[i] = sum of widths from column 0 to i (inclusive)
   * @returns {number[]} Array of cumulative widths
   * @private
   */
  buildCumulativeCache() {
    const cache = [];
    let sum = 0;
    for (let i = 0; i < this.columnWidths.length; i++) {
      sum += this.columnWidths[i];
      cache.push(sum);
    }
    return cache;
  }

  /**
   * Find column index at a given scroll position using binary search
   * O(log n) instead of O(n) - critical for thousands of columns
   *
   * @param {number} scrollLeft - Scroll position in pixels
   * @returns {number} Column index at that position
   *
   * @example
   *   const geometry = new VirtualScrollGeometry([100, 100, 100]);
   *   geometry.findColumnAtPosition(150); // Returns 2
   */
  findColumnAtPosition(scrollLeft) {
    if (!this.cumulativeWidths || this.cumulativeWidths.length === 0) {
      return 0;
    }

    // Binary search for the first cumulative width > scrollLeft
    let left = 0;
    let right = this.cumulativeWidths.length - 1;

    while (left < right) {
      const mid = Math.floor((left + right) / 2);
      if (this.cumulativeWidths[mid] <= scrollLeft) {
        left = mid + 1;
      } else {
        right = mid;
      }
    }

    return left;
  }

  /**
   * Calculate cumulative width up to a given column index
   * O(1) lookup using cached cumulative widths
   *
   * @param {number} columnIndex - Column index (0-based)
   * @returns {number} Cumulative width in pixels from column 0 to columnIndex-1
   *
   * @example
   *   const geometry = new VirtualScrollGeometry([100, 100, 100]);
   *   geometry.cumulativeWidthTo(2); // Returns 200 (100 + 100)
   */
  cumulativeWidthTo(columnIndex) {
    if (columnIndex <= 0) return 0;
    if (columnIndex >= this.cumulativeWidths.length) {
      return this.cumulativeWidths[this.cumulativeWidths.length - 1] || 0;
    }
    return this.cumulativeWidths[columnIndex - 1] || 0;
  }

  /**
   * Calculate which columns are visible in the viewport
   *
   * @param {number} scrollLeft - Current scroll position in pixels
   * @param {number} viewportWidth - Width of the viewport in pixels
   * @param {number} bufferColumns - Number of columns to render outside viewport on each side
   * @returns {{firstVisible: number, lastVisible: number}} Range of visible column indices
   *
   * @example
   *   const geometry = new VirtualScrollGeometry([100, 100, 100, 100, 100]);
   *   const range = geometry.calculateVisibleRange(50, 300, 1);
   *   // Returns { firstVisible: 0, lastVisible: 5 }
   *   // (columns 0-2 are in viewport, +1 buffer on each side)
   */
  calculateVisibleRange(scrollLeft, viewportWidth, bufferColumns = 3) {
    // Find first visible column with buffer
    const firstVisible = Math.max(
      0,
      this.findColumnAtPosition(scrollLeft) - bufferColumns,
    );

    // Calculate how many columns fit in viewport using variable widths
    let visibleWidth = 0;
    let visibleCount = 0;

    for (let i = firstVisible; i < this.columnWidths.length; i++) {
      visibleWidth += this.columnWidths[i];
      visibleCount++;
      if (visibleWidth >= viewportWidth) break;
    }

    // Add buffer on both sides
    visibleCount += 2 * bufferColumns;

    const lastVisible = Math.min(
      this.columnWidths.length,
      firstVisible + visibleCount,
    );

    return { firstVisible, lastVisible };
  }

  /**
   * Get total width of all columns
   * @returns {number} Total width in pixels
   */
  getTotalWidth() {
    if (this.cumulativeWidths.length === 0) return 0;
    return this.cumulativeWidths[this.cumulativeWidths.length - 1];
  }

  /**
   * Update column widths and rebuild cache
   * Useful when columns are resized or measurements change
   *
   * @param {number[]} newColumnWidths - Updated array of column widths
   *
   * @example
   *   geometry.updateColumnWidths([120, 150, 100, 200]);
   */
  updateColumnWidths(newColumnWidths) {
    this.columnWidths = newColumnWidths;
    this.cumulativeWidths = this.buildCumulativeCache();
  }
}
