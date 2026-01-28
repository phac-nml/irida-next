import { Controller } from "@hotwired/stimulus";
import debounce from "debounce";

/**
 * TableController
 *
 * Ensures a focused table cell is visible within a horizontally scrollable
 * container, accounting for left-side sticky columns that can overlay content.
 * Provides enhanced accessibility features and respects user motion preferences.
 *
 * @example Basic Usage
 *   <tbody data-controller="table" data-action="focusin->table#handleCellFocus">
 *
 * @notes
 * - Behavior respects user's reduced motion preferences
 * - Performance optimized with debouncing and caching
 * - Accessible with semantic HTML and keyboard navigation
 * - No horizontal scrolling occurs for sticky cells
 */
export default class TableController extends Controller {
  static #STICKY_PADDING = 8;
  static #DEBOUNCE_DELAY = 100;
  static #VERTICAL_PADDING = 16;
  // Selector for truly interactive elements (excludes grid cells that only have tabindex for navigation)
  static #INTERACTIVE_ELEMENT_SELECTOR =
    "a[href], button:not([disabled]), input:not([disabled]), select:not([disabled]), textarea:not([disabled])";

  #lastFocusedCell = null;
  #scrollerCache = new WeakMap();
  #stickyCache = new WeakMap();
  #prefersReducedMotion = false;
  #debouncedHandleFocus = null;
  #isResettingFocus = false;

  connect() {
    this.#prefersReducedMotion =
      window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches ?? false;

    this.#debouncedHandleFocus = debounce(
      this.#handleCellFocusInternal.bind(this),
      TableController.#DEBOUNCE_DELAY,
    );
  }

  disconnect() {
    this.#scrollerCache = new WeakMap();
    this.#stickyCache = new WeakMap();
    this.#lastFocusedCell = null;
    this.#debouncedHandleFocus?.clear();
  }

  /**
   * Public handler for focus events
   * @param {FocusEvent} event - The focus event from a table cell
   */
  handleCellFocus(event) {
    if (!event?.target?.closest) return;

    if (this.#isResettingFocus) {
      this.#isResettingFocus = false;
    } else if (this.#shouldResetFocusOnEntry(event)) {
      // Don't redirect focus when clicking on truly interactive elements (links, buttons, inputs)
      // This prevents interfering with button clicks, form submissions, etc.
      // Note: We intentionally exclude grid cells that only have tabindex for roving tabindex navigation
      if (
        !event.target.matches(TableController.#INTERACTIVE_ELEMENT_SELECTOR)
      ) {
        if (this.#focusFirstCellInTable(event.target.closest("table"), event)) {
          return;
        }
      }
    }

    this.#debouncedHandleFocus(event);
  }

  /**
   * Public handler for focusout events - resets tabindex when leaving table
   * @param {FocusEvent} event - The focusout event
   */
  handleCellBlur(event) {
    if (!event?.target?.closest) return;

    const table = event.target.closest("table");
    if (!table) return;

    // Check if focus is leaving the table entirely
    const relatedTarget = event.relatedTarget;
    if (relatedTarget && table.contains(relatedTarget)) {
      // Focus is moving within the table, don't reset
      return;
    }

    // Focus is leaving the table - reset roving tabindex to first cell
    this.#resetTabindexToFirstCell(table);
  }

  /**
   * Reset the roving tabindex to the first cell in the table
   * @param {HTMLTableElement} table
   */
  #resetTabindexToFirstCell(table) {
    const firstCell = table.querySelector(
      "thead th[aria-colindex], thead td[aria-colindex]",
    );
    if (!firstCell) return;

    // Directly reset all cells to tabindex=-1
    table.querySelectorAll("[aria-colindex]").forEach((cell) => {
      cell.tabIndex = -1;
    });

    // Set the first cell to tabindex=0
    firstCell.tabIndex = 0;

    const rowIndex = parseInt(
      firstCell.closest("[aria-rowindex]")?.getAttribute("aria-rowindex"),
      10,
    );
    const colIndex = parseInt(firstCell.getAttribute("aria-colindex"), 10);

    if (Number.isInteger(rowIndex) && Number.isInteger(colIndex)) {
      // Dispatch event to notify virtual-scroll controller to reset its focus state
      table.dispatchEvent(
        new CustomEvent("table:focus-reset", {
          bubbles: true,
          detail: { rowIndex, colIndex },
        }),
      );
    }
  }

  /**
   * Internal debounced handler for focus events
   * @param {FocusEvent} event
   */
  #handleCellFocusInternal(event) {
    const cell = event.target.closest("td, th");
    if (!cell || this.#lastFocusedCell === cell) return;

    this.#lastFocusedCell = cell;

    const scroller = this.#findHorizontalScroller(cell);
    if (!scroller) return;

    const scrollBehavior = this.#prefersReducedMotion ? "auto" : "smooth";

    cell.scrollIntoView({
      behavior: scrollBehavior,
      block: "nearest",
      inline: "nearest",
    });

    this.#ensureVerticalVisibility(cell, scroller);

    // Skip horizontal scrolling for sticky cells
    if (this.#isStickyCell(cell)) return;

    this.#handleHorizontalScrolling(cell, scroller);
  }

  /**
   * Handle horizontal scrolling logic for non-sticky cells
   * @param {HTMLElement} cell
   * @param {HTMLElement} scroller
   */
  #handleHorizontalScrolling(cell, scroller) {
    const stickyRight = this.#leftStickyOverlayRight(cell);
    if (stickyRight <= 0) return;

    const scrollerRect = scroller.getBoundingClientRect();
    const cellRect = cell.getBoundingClientRect();
    const stickyRightViewport = scrollerRect.left + stickyRight;
    const padding = TableController.#STICKY_PADDING;

    // If cell's left edge is obscured by sticky columns, nudge into view
    if (cellRect.left < stickyRightViewport + padding) {
      const delta = stickyRightViewport + padding - cellRect.left;
      this.#scrollBy(scroller, -delta);
    }

    // Ensure right edge is visible
    const overflowRight = cellRect.right - scrollerRect.right;
    if (overflowRight > 0) {
      this.#scrollBy(scroller, overflowRight);
    }
  }

  /**
   * Ensure the cell is fully visible vertically within the scroller
   * @param {HTMLElement} cell
   * @param {HTMLElement} scroller
   */
  #ensureVerticalVisibility(cell, scroller) {
    const cellRect = cell.getBoundingClientRect();
    const scrollerRect = scroller.getBoundingClientRect();

    const stickyHeaderHeight = this.#getStickyOverlayHeight(cell, "top");
    const stickyFooterHeight = this.#getStickyOverlayHeight(cell, "bottom");

    const effectiveTop = scrollerRect.top + stickyHeaderHeight;
    const effectiveBottom = scrollerRect.bottom - stickyFooterHeight;

    const isFirstRow = this.#isFirstRow(cell);
    const isLastRow = this.#isLastRow(cell);
    const topPadding = isFirstRow ? 0 : TableController.#VERTICAL_PADDING;
    const bottomPadding = isLastRow ? 0 : TableController.#VERTICAL_PADDING;

    const overflowBottom = cellRect.bottom - effectiveBottom + bottomPadding;
    if (overflowBottom > 0) {
      scroller.scrollTop += overflowBottom;
    }

    const overflowTop = effectiveTop - cellRect.top + topPadding;
    if (overflowTop > 0) {
      scroller.scrollTop -= overflowTop;
    }
  }

  /**
   * Determine whether focus just entered the table from outside
   * @param {FocusEvent} event
   * @returns {boolean}
   */
  #shouldResetFocusOnEntry(event) {
    const table = event.target.closest("table");
    if (!table) return false;

    const previous = event.relatedTarget;
    return !previous || !table.contains(previous);
  }

  /**
   * Move focus to the first focusable element in the table
   * @param {HTMLTableElement|null} table
   * @param {FocusEvent} event
   * @returns {boolean} True if focus was moved
   */
  #focusFirstCellInTable(table, event) {
    if (!table) return false;

    const firstCell = table.querySelector(
      "thead th[aria-colindex], thead td[aria-colindex], tbody th[aria-colindex], tbody td[aria-colindex]",
    );
    if (!firstCell) return false;

    const focusTarget =
      firstCell.querySelector(TableController.#INTERACTIVE_ELEMENT_SELECTOR) ||
      firstCell;
    if (focusTarget === event.target) return false;

    this.#lastFocusedCell = null;
    this.#isResettingFocus = true;

    // Directly reset all cells to tabindex=-1 and set first cell to tabindex=0
    table.querySelectorAll("[aria-colindex]").forEach((cell) => {
      cell.tabIndex = -1;
    });
    firstCell.tabIndex = 0;

    // Also notify virtual-scroll controller to update its internal state
    const rowIndex = parseInt(
      firstCell.closest("[aria-rowindex]")?.getAttribute("aria-rowindex"),
      10,
    );
    const colIndex = parseInt(firstCell.getAttribute("aria-colindex"), 10);

    if (Number.isInteger(rowIndex) && Number.isInteger(colIndex)) {
      table.dispatchEvent(
        new CustomEvent("table:focus-reset", {
          bubbles: true,
          detail: { rowIndex, colIndex },
        }),
      );
    }

    focusTarget.focus();
    return true;
  }

  /**
   * Check if a cell has sticky positioning
   * @param {HTMLElement} cell
   * @returns {boolean}
   */
  #isStickyCell(cell) {
    return getComputedStyle(cell).position === "sticky";
  }

  /**
   * Find the nearest horizontally scrollable ancestor
   * @param {Element} el
   * @returns {HTMLElement|null}
   */
  #findHorizontalScroller(el) {
    if (this.#scrollerCache.has(el)) {
      return this.#scrollerCache.get(el);
    }

    let node = el.parentElement;
    while (node && node !== document.body) {
      const style = getComputedStyle(node);
      const canScrollX =
        node.scrollWidth > node.clientWidth &&
        /(auto|scroll|overlay)/.test(style.overflowX || style.overflow);

      if (canScrollX) {
        this.#scrollerCache.set(el, node);
        return node;
      }
      node = node.parentElement;
    }

    this.#scrollerCache.set(el, null);
    return null;
  }

  /**
   * Compute the rightmost x covered by left-pinned sticky cells in this row
   * @param {HTMLElement} cell
   * @returns {number}
   */
  #leftStickyOverlayRight(cell) {
    const row = cell.closest("tr");
    if (!row) return 0;

    let maxRight = 0;
    for (const c of row.children) {
      const style = getComputedStyle(c);
      if (style.position !== "sticky") continue;

      const left = parseFloat(style.left);
      if (!Number.isFinite(left)) continue;

      maxRight = Math.max(maxRight, left + c.getBoundingClientRect().width);
    }

    return maxRight;
  }

  /**
   * Compute sticky overlay height at top or bottom
   * @param {HTMLElement} cell
   * @param {'top'|'bottom'} position
   * @returns {number}
   */
  #getStickyOverlayHeight(cell, position) {
    const table = cell.closest("table");
    if (!table) return 0;

    const cacheKey = position;
    if (this.#stickyCache.has(table)) {
      const cached = this.#stickyCache.get(table)[cacheKey];
      if (cached !== undefined) return cached;
    }

    const section =
      position === "top"
        ? table.querySelector("thead")
        : table.querySelector("tfoot");
    let height = 0;

    if (section) {
      const style = getComputedStyle(section);
      if (style.position === "sticky") {
        height = section.getBoundingClientRect().height;
      }
    }

    if (!this.#stickyCache.has(table)) {
      this.#stickyCache.set(table, {});
    }
    this.#stickyCache.get(table)[cacheKey] = height;

    return height;
  }

  /**
   * Determine if the cell is in the first visible row
   * @param {HTMLElement} cell
   * @returns {boolean}
   */
  #isFirstRow(cell) {
    const row = cell.closest("tr");
    const tbody = row?.closest("tbody");
    if (!tbody || !row) return false;

    return this.#findFirstVisibleRow(tbody) === row;
  }

  /**
   * Determine if the cell is in the last visible row
   * @param {HTMLElement} cell
   * @returns {boolean}
   */
  #isLastRow(cell) {
    const row = cell.closest("tr");
    const tbody = row?.closest("tbody");
    if (!tbody || !row) return false;

    return this.#findLastVisibleRow(tbody) === row;
  }

  /**
   * Find the first visible row in a tbody
   * @param {HTMLTableSectionElement} tbody
   * @returns {HTMLTableRowElement|null}
   */
  #findFirstVisibleRow(tbody) {
    for (const row of tbody.rows) {
      if (this.#isRowVisible(row)) return row;
    }
    return null;
  }

  /**
   * Find the last visible row in a tbody
   * @param {HTMLTableSectionElement} tbody
   * @returns {HTMLTableRowElement|null}
   */
  #findLastVisibleRow(tbody) {
    const rows = tbody.rows;
    for (let i = rows.length - 1; i >= 0; i--) {
      if (this.#isRowVisible(rows[i])) return rows[i];
    }
    return null;
  }

  /**
   * Check if a row is visible
   * @param {HTMLTableRowElement} row
   * @returns {boolean}
   */
  #isRowVisible(row) {
    const style = getComputedStyle(row);
    return (
      style.display !== "none" &&
      style.visibility !== "hidden" &&
      style.opacity !== "0"
    );
  }

  /**
   * Scroll a container horizontally by a delta
   * @param {HTMLElement} scroller
   * @param {number} dx - Positive scrolls right, negative left
   */
  #scrollBy(scroller, dx) {
    if (dx === 0) return;

    const max = Math.max(0, scroller.scrollWidth - scroller.clientWidth);
    const next = Math.min(max, Math.max(0, scroller.scrollLeft + dx));

    if (this.#prefersReducedMotion) {
      scroller.scrollLeft = next;
    } else {
      scroller.scrollTo({ left: next, behavior: "smooth" });
    }
  }
}
