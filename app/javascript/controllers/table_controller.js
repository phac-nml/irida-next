import { Controller } from "@hotwired/stimulus";

/**
 * TableController
 *
 * Ensures a focused table cell is visible within a horizontally scrollable
 * container, accounting for left-side sticky columns that can overlay content.
 *
 * Usage:
 *   <tbody data-controller="table" data-action="focusin->table#handleCellFocus">
 *
 * Notes:
 * - Behavior is immediate (no animation).
 * - If no horizontally scrollable ancestor exists, we bail rather than
 *   mutating the document scroller to avoid surprising page scrolls.
 */
export default class TableController extends Controller {
  // Class constant for extra padding (px) between a focused cell and the right edge
  // of the left sticky overlay.
  static get STICKY_PADDING() {
    return 8;
  }

  /**
   * Handle focus events from descendant cells and ensure visibility.
   *
   * Contract:
   * - event.target is inside a <td> or <th>.
   * - We only adjust horizontal scroll of the nearest scrollable ancestor.
   *
   * @param {FocusEvent} event
   */
  handleCellFocus(event) {
    const cell = event.target.closest("td, th");
    if (!cell) return;

    const scroller = this.#findHorizontalScroller(cell);
    // If no horizontal overflow container, nothing to adjust.
    if (!scroller) return;

    // Ensure the cell is generally visible within its containers.
    this.#scrollIntoView(cell);

    // Compute the right edge (in px, relative to scroller's left edge) of left sticky columns.
    const stickyRight = this.#leftStickyOverlayRight(cell);
    if (!(stickyRight > 0)) return;

    const scrollerRect = scroller.getBoundingClientRect();
    const stickyRightViewport = scrollerRect.left + stickyRight;

    const rect = cell.getBoundingClientRect();
    const padding = TableController.STICKY_PADDING; // px

    // If the cell's left edge is obscured by sticky columns, nudge horizontally into view.
    if (rect.left < stickyRightViewport + padding) {
      const delta = stickyRightViewport + padding - rect.left;
      this.#scrollBy(scroller, -delta);
    }

    // Also ensure the right edge is visible if it overflows the viewport of the scroller.
    const overflowRight = rect.right - scrollerRect.right;
    if (overflowRight > 0) {
      this.#scrollBy(scroller, overflowRight);
    }
  }

  /**
   * Find the nearest horizontally scrollable ancestor.
   * Returns null if none found (we intentionally do not default to the document scroller).
   * @param {Element} el
   * @returns {HTMLElement|null}
   */
  #findHorizontalScroller(el) {
    let node = el.parentElement;
    while (node && node !== document.body) {
      const style = getComputedStyle(node);
      const canScrollX =
        node.scrollWidth > node.clientWidth &&
        /(auto|scroll|overlay)/.test(style.overflowX || style.overflow);
      if (canScrollX) return node;
      node = node.parentElement;
    }
    return null;
  }

  /**
   * Compute the rightmost x (px from scroller's left edge) covered by left-pinned sticky cells in this row.
   * @param {HTMLElement} cell
   * @returns {number}
   */
  #leftStickyOverlayRight(cell) {
    const row = cell.closest("tr");
    if (!row) return 0;

    let maxRight = 0;
    for (const c of Array.from(row.children)) {
      const style = getComputedStyle(c);
      if (style.position !== "sticky") continue;

      const left = parseFloat(style.left);
      if (!Number.isFinite(left)) continue;

      const width = c.getBoundingClientRect().width;
      maxRight = Math.max(maxRight, left + width);
    }
    return maxRight;
  }

  /**
   * Scroll a target element into view with nearest block/inline alignment (no animation).
   * @param {Element} el
   */
  #scrollIntoView(el) {
    el.scrollIntoView({ block: "nearest", inline: "nearest" });
  }

  /**
   * Scroll a container horizontally by a delta, clamped to valid range.
   * No animation.
   * @param {HTMLElement} scroller
   * @param {number} dx - positive scrolls right, negative left (LTR semantics)
   */
  #scrollBy(scroller, dx) {
    if (dx === 0) return;

    // Clamp using scrollLeft to maintain consistent bounds across browsers.
    const min = 0;
    const max = Math.max(0, scroller.scrollWidth - scroller.clientWidth);
    const next = Math.min(max, Math.max(min, scroller.scrollLeft + dx));

    // Prefer scrollTo for better cross-browser behavior than setting scrollLeft directly.
    scroller.scrollTo({ left: next });
  }
}
