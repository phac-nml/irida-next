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

  // 💡 Additional vertical padding for better visual spacing
  static get VERTICAL_PADDING() {
    return 16;
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

    // 🚀 Additional check to ensure cell is fully visible vertically within the scroller
    this.#ensureVerticalVisibility(cell, scroller);

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
   * Ensure the cell is fully visible vertically within the scroller.
   * This handles cases where tabbing to bottom rows doesn't bring them fully into view
   * and accounts for sticky footers and headers that may block visibility.
   *
   * @param {HTMLElement} cell - The focused cell
   * @param {HTMLElement} scroller - The scrollable container
   */
  #ensureVerticalVisibility(cell, scroller) {
    const cellRect = cell.getBoundingClientRect();
    const scrollerRect = scroller.getBoundingClientRect();

    // 💡 Find sticky overlay heights at top and bottom
    const stickyHeaderHeight = this.#topStickyOverlayHeight(cell, scroller);
    const stickyFooterHeight = this.#bottomStickyOverlayHeight(cell, scroller);

    // 📝 Calculate effective boundaries accounting for sticky overlays
    const effectiveTop = scrollerRect.top + stickyHeaderHeight;
    const effectiveBottom = scrollerRect.bottom - stickyFooterHeight;

    // 🚀 Check if this is the first or last row to adjust padding accordingly
    const isFirstRow = this.#isFirstRow(cell);
    const isLastRow = this.#isLastRow(cell);
    const topPadding = isFirstRow ? 0 : TableController.VERTICAL_PADDING;
    const bottomPadding = isLastRow ? 0 : TableController.VERTICAL_PADDING;

    // 💡 Check if cell is blocked by sticky footer or needs more breathing room at bottom
    const overflowBottom = cellRect.bottom - effectiveBottom + bottomPadding;
    if (overflowBottom > 0) {
      scroller.scrollTop += overflowBottom;
    }

    // 💡 Check if cell is blocked by sticky header or needs more breathing room at top
    const overflowTop = effectiveTop - cellRect.top + topPadding;
    if (overflowTop > 0) {
      scroller.scrollTop -= overflowTop;
    }
  }

  /**
   * Determine if the given cell is in the first row of its table body.
   *
   * @param {HTMLElement} cell - The focused cell
   * @returns {boolean} True if the cell is in the first row
   */
  #isFirstRow(cell) {
    const row = cell.closest("tr");
    const tbody = row?.closest("tbody");

    if (!tbody || !row) return false;

    // 📝 Find all visible rows in the tbody (not hidden by display:none or similar)
    const allRows = Array.from(tbody.querySelectorAll("tr")).filter((tr) => {
      const style = getComputedStyle(tr);
      return style.display !== "none" && style.visibility !== "hidden";
    });

    // 🚀 Check if this is the first visible row
    return allRows.length > 0 && allRows[0] === row;
  }

  /**
   * Determine if the given cell is in the last row of its table body.
   *
   * @param {HTMLElement} cell - The focused cell
   * @returns {boolean} True if the cell is in the last row
   */
  #isLastRow(cell) {
    const row = cell.closest("tr");
    const tbody = row?.closest("tbody");

    if (!tbody || !row) return false;

    // 📝 Find all visible rows in the tbody (not hidden by display:none or similar)
    const allRows = Array.from(tbody.querySelectorAll("tr")).filter((tr) => {
      const style = getComputedStyle(tr);
      return style.display !== "none" && style.visibility !== "hidden";
    });

    // 🚀 Check if this is the last visible row
    return allRows.length > 0 && allRows[allRows.length - 1] === row;
  }

  /**
   * Compute the height (px) of top-pinned sticky elements that could overlay the cell.
   * This includes table headers, filter controls, or other sticky top elements.
   *
   * @param {HTMLElement} cell - The focused cell
   * @param {HTMLElement} scroller - The scrollable container
   * @returns {number} Height in pixels of sticky top overlay
   */
  #topStickyOverlayHeight(cell, scroller) {
    const table = cell.closest("table");
    if (!table) return 0;

    let maxHeight = 0;

    // 📝 Check for sticky table header elements (thead, filter controls, etc.)
    const stickyElements = [
      ...table.querySelectorAll("thead"),
      ...scroller.querySelectorAll("[class*='sticky'][class*='top']"),
      ...scroller.querySelectorAll("[style*='position: sticky'][style*='top']"),
    ];

    for (const element of stickyElements) {
      const style = getComputedStyle(element);

      // 💡 Check if element is sticky positioned at top
      if (style.position === "sticky") {
        const top = parseFloat(style.top);

        // 🚀 If top is set (not auto), this is likely a sticky top element
        if (Number.isFinite(top)) {
          const height = element.getBoundingClientRect().height;
          maxHeight = Math.max(maxHeight, height);
        }
      }
    }

    return maxHeight;
  }

  /**
   * Compute the height (px) of bottom-pinned sticky elements that could overlay the cell.
   * This includes table footers, pagination controls, or other sticky bottom elements.
   *
   * @param {HTMLElement} cell - The focused cell
   * @param {HTMLElement} scroller - The scrollable container
   * @returns {number} Height in pixels of sticky bottom overlay
   */
  #bottomStickyOverlayHeight(cell, scroller) {
    const table = cell.closest("table");
    if (!table) return 0;

    let maxHeight = 0;

    // 📝 Check for sticky table footer elements (tfoot, pagination, etc.)
    const stickyElements = [
      ...table.querySelectorAll("tfoot"),
      ...scroller.querySelectorAll("[class*='sticky'][class*='bottom']"),
      ...scroller.querySelectorAll(
        "[style*='position: sticky'][style*='bottom']",
      ),
    ];

    for (const element of stickyElements) {
      const style = getComputedStyle(element);

      // 💡 Check if element is sticky positioned at bottom
      if (style.position === "sticky") {
        const bottom = parseFloat(style.bottom);

        // 🚀 If bottom is set (not auto), this is likely a sticky bottom element
        if (Number.isFinite(bottom)) {
          const height = element.getBoundingClientRect().height;
          maxHeight = Math.max(maxHeight, height);
        }
      }
    }

    return maxHeight;
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
