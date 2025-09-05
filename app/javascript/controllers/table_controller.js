import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

/**
 * TableController
 *
 * Ensures a focused table cell is visible within a horizontally scrollable
 * container, accounting for left-side sticky columns that can overlay content.
 * Provides enhanced accessibility features including screen reader announcements
 * and respects user motion preferences.
 *
 * @example Basic Usage
 *   <tbody data-controller="table" data-action="focusin->table#handleCellFocus">
 *
 * @example With Custom Configuration
 *   <tbody data-controller="table"
 *         data-table-vertical-padding-value="20"
 *         data-table-debounce-delay-value="150"
 *         data-action="focusin->table#handleCellFocus">
 *
 * @example With Accessibility Features
 *   <tbody data-controller="table"
 *         data-table-announce-navigation-value="true"
 *         data-action="focusin->table#handleCellFocus">
 *
 * @notes
 * - Behavior respects user's reduced motion preferences
 * - Includes comprehensive error handling and logging
 * - Performance optimized with debouncing and caching
 * - Fully accessible with ARIA announcements
 * - No horizontal scrolling occurs for sticky cells
 */
export default class TableController extends Controller {
  // 🎯 Stimulus values for configuration
  static values = {
    verticalPadding: { type: Number, default: 16 },
    debounceDelay: { type: Number, default: 100 },
    announceNavigation: { type: Boolean, default: false },
  };

  // 🎯 Stimulus targets for accessibility
  static targets = ["announcer"];

  // 🔒 Private constants
  static get #MIN_PADDING() {
    return 0;
  }
  static get #MAX_PADDING() {
    return 100;
  }
  static get #MIN_DEBOUNCE() {
    return 50;
  }
  static get #MAX_DEBOUNCE() {
    return 500;
  }
  static get #STICKY_PADDING() {
    return 8;
  }

  // 🎯 Performance and state tracking - Private field declarations
  #lastFocusedCell = null;
  #scrollerCache = new WeakMap();
  #stickyElementsCache = new WeakMap();
  #prefersReducedMotion = false;
  #debouncedHandleFocus = null;

  /**
   * Stimulus lifecycle: Initialize controller
   * Sets up debounced handlers and accessibility features
   */
  initialize() {
    try {
      // 🎭 Check for reduced motion preference
      this.#prefersReducedMotion =
        window.matchMedia?.("(prefers-reduced-motion: reduce)")?.matches ??
        false;

      // 🎯 Create debounced focus handler using lodash
      this.#debouncedHandleFocus = _.debounce(
        this.#handleCellFocusInternal.bind(this),
        this.debounceDelayValue,
      );

      // 🔊 Create accessibility announcer if not present
      this.#ensureAnnouncerExists();
    } catch (error) {
      this.#handleError("Failed to initialize TableController", error);
    }
  }

  /**
   * Stimulus lifecycle: Cleanup when controller is disconnected
   */
  disconnect() {
    try {
      this.#clearCaches();
      if (this.#debouncedHandleFocus) {
        this.#debouncedHandleFocus.cancel();
      }
    } catch (error) {
      this.#handleError("Error during TableController disconnect", error);
    }
  }

  /**
   * Public handler for focus events - validates input and delegates to debounced internal handler
   *
   * @param {FocusEvent} event - The focus event from a table cell
   * @throws {Error} If event is invalid or target is not within a table cell
   * @public
   */
  handleCellFocus(event) {
    try {
      // 🔍 Validate input parameters
      if (!event || !(event instanceof FocusEvent)) {
        throw new Error("Invalid event: expected FocusEvent");
      }

      if (!event.target || !event.target.closest) {
        throw new Error("Invalid event target: expected DOM element");
      }

      // 🎯 Delegate to debounced internal handler
      this.#debouncedHandleFocus(event);
    } catch (error) {
      this.#handleError("Error in handleCellFocus", error, { event });
    }
  }

  /**
   * Internal debounced handler for focus events from descendant cells
   *
   * @param {FocusEvent} event - The focus event from a table cell
   * @private
   */
  #handleCellFocusInternal(event) {
    try {
      const cell = event.target.closest("td, th");
      if (!cell) {
        return;
      }

      // 🔄 Check if this is the same cell as last focus (avoid redundant work)
      if (this.#lastFocusedCell === cell) {
        return;
      }
      this.#lastFocusedCell = cell;

      const scroller = this.#findHorizontalScroller(cell);
      if (!scroller) {
        return;
      }

      // 🎭 Respect reduced motion preferences
      const scrollOptions = this.#getScrollOptions();

      // 📢 Announce navigation if enabled
      this.#announceNavigation(cell);

      // 🔝 Ensure the cell is generally visible within its containers
      this.#scrollIntoView(cell, scrollOptions);

      // 📏 Additional check to ensure cell is fully visible vertically within the scroller
      this.#ensureVerticalVisibility(cell, scroller);

      // 🔒 Skip horizontal scrolling for sticky cells
      if (this.#isStickyCell(cell)) {
        return;
      }

      // 📏 Handle horizontal scrolling for non-sticky cells
      this.#handleHorizontalScrolling(cell, scroller);
    } catch (error) {
      this.#handleError("Error in internal cell focus handler", error, {
        cell: event.target,
      });
    }
  }

  /**
   * Handle horizontal scrolling logic for non-sticky cells
   *
   * @param {HTMLElement} cell - The focused cell
   * @param {HTMLElement} scroller - The scrollable container
   * @private
   */
  #handleHorizontalScrolling(cell, scroller) {
    try {
      // 📐 Compute the right edge (in px, relative to scroller's left edge) of left sticky columns
      const stickyRight = this.#leftStickyOverlayRight(cell);
      if (!(stickyRight > 0)) return;

      const scrollerRect = this.#getBoundingClientRectSafe(scroller);
      const cellRect = this.#getBoundingClientRectSafe(cell);

      if (!scrollerRect || !cellRect) return;

      const stickyRightViewport = scrollerRect.left + stickyRight;
      const padding = TableController.#STICKY_PADDING;

      // 👈 If the cell's left edge is obscured by sticky columns, nudge horizontally into view
      if (cellRect.left < stickyRightViewport + padding) {
        const delta = stickyRightViewport + padding - cellRect.left;
        this.#scrollBy(scroller, -delta);
      }

      // 👉 Also ensure the right edge is visible if it overflows the viewport of the scroller
      const overflowRight = cellRect.right - scrollerRect.right;
      if (overflowRight > 0) {
        this.#scrollBy(scroller, overflowRight);
      }
    } catch (error) {
      this.#handleError("Error in horizontal scrolling", error, {
        cell,
        scroller,
      });
    }
  }

  /**
   * Ensure the cell is fully visible vertically within the scroller.
   * Enhanced with better error handling and performance optimizations.
   *
   * @param {HTMLElement} cell - The focused cell
   * @param {HTMLElement} scroller - The scrollable container
   * @throws {Error} If cell or scroller are invalid
   * @private
   */
  #ensureVerticalVisibility(cell, scroller) {
    try {
      if (!this.#isValidElement(cell) || !this.#isValidElement(scroller)) {
        throw new Error("Invalid cell or scroller element");
      }

      const cellRect = this.#getBoundingClientRectSafe(cell);
      const scrollerRect = this.#getBoundingClientRectSafe(scroller);

      if (!cellRect || !scrollerRect) return;

      // 📏 Find sticky overlay heights at top and bottom (with caching)
      const stickyHeaderHeight = this.#getStickyOverlayHeight(
        cell,
        scroller,
        "top",
      );
      const stickyFooterHeight = this.#getStickyOverlayHeight(
        cell,
        scroller,
        "bottom",
      );

      // 📏 Calculate effective boundaries accounting for sticky overlays
      const effectiveTop = scrollerRect.top + stickyHeaderHeight;
      const effectiveBottom = scrollerRect.bottom - stickyFooterHeight;

      // 🎯 Check if this is the first or last row to adjust padding accordingly
      const isFirstRow = this.#isFirstRow(cell);
      const isLastRow = this.#isLastRow(cell);
      const verticalPadding = this.#getValidatedVerticalPadding();
      const topPadding = isFirstRow ? 0 : verticalPadding;
      const bottomPadding = isLastRow ? 0 : verticalPadding;

      // 📏 Check if cell is blocked by sticky footer or needs more breathing room at bottom
      const overflowBottom = cellRect.bottom - effectiveBottom + bottomPadding;
      if (overflowBottom > 0) {
        scroller.scrollTop += overflowBottom;
      }

      // 📏 Check if cell is blocked by sticky header or needs more breathing room at top
      const overflowTop = effectiveTop - cellRect.top + topPadding;
      if (overflowTop > 0) {
        scroller.scrollTop -= overflowTop;
      }
    } catch (error) {
      this.#handleError("Error ensuring vertical visibility", error, {
        cell,
        scroller,
      });
    }
  }

  // 🛠️ UTILITY METHODS

  /**
   * Get scroll options based on user's motion preferences
   * @returns {Object} Scroll options object
   * @private
   */
  #getScrollOptions() {
    return {
      behavior: this.#prefersReducedMotion ? "auto" : "smooth",
      block: "nearest",
      inline: "nearest",
    };
  }

  /**
   * Announce navigation to screen readers if enabled
   * @param {HTMLElement} cell - The focused cell
   * @private
   */
  #announceNavigation(cell) {
    if (!this.announceNavigationValue || !this.hasAnnouncerTarget) return;

    try {
      const row = cell.closest("tr");
      const table = cell.closest("table");
      const rowIndex =
        Array.from(table?.querySelectorAll("tr") || []).indexOf(row) + 1;
      const cellIndex = Array.from(row?.children || []).indexOf(cell) + 1;

      const announcement = `Moved to row ${rowIndex}, column ${cellIndex}`;
      this.announcerTarget.textContent = announcement;

      // Clear announcement after a brief delay
      setTimeout(() => {
        if (this.hasAnnouncerTarget) {
          this.announcerTarget.textContent = "";
        }
      }, 1000);
    } catch (error) {
      this.#handleError("Error announcing navigation", error, { cell });
    }
  }

  /**
   * Ensure accessibility announcer element exists
   * @private
   */
  #ensureAnnouncerExists() {
    if (this.hasAnnouncerTarget) return;

    const announcer = document.createElement("div");
    announcer.setAttribute("aria-live", "polite");
    announcer.setAttribute("aria-atomic", "true");
    announcer.setAttribute("data-table-target", "announcer");
    announcer.className =
      "sr-only absolute -left-[10000px] w-px h-px overflow-hidden";
    this.element.appendChild(announcer);
  }

  /**
   * Get validated vertical padding value
   * @returns {number} Validated padding value
   * @private
   */
  #getValidatedVerticalPadding() {
    const value = this.verticalPaddingValue;
    if (typeof value !== "number" || isNaN(value)) {
      return 16;
    }
    return Math.max(
      TableController.#MIN_PADDING,
      Math.min(TableController.#MAX_PADDING, value),
    );
  }

  /**
   * Safely get bounding client rect with error handling
   * @param {HTMLElement} element - Element to get rect for
   * @returns {DOMRect|null} Bounding rect or null if error
   * @private
   */
  #getBoundingClientRectSafe(element) {
    try {
      if (!this.#isValidElement(element)) return null;
      return element.getBoundingClientRect();
    } catch (error) {
      this.#handleError("Error getting bounding client rect", error, {
        element,
      });
      return null;
    }
  }

  /**
   * Check if element is valid and attached to DOM
   * @param {*} element - Element to validate
   * @returns {boolean} True if element is valid
   * @private
   */
  #isValidElement(element) {
    return (
      element &&
      element instanceof Element &&
      element.isConnected &&
      typeof element.getBoundingClientRect === "function"
    );
  }

  /**
   * Enhanced error handling with optional logging and context
   * @param {string} message - Error message
   * @param {Error} error - Original error
   * @param {Object} context - Additional context for debugging
   * @private
   */
  #handleError(message, error, context = {}) {
    const errorInfo = {
      message,
      error: error?.message || error,
      stack: error?.stack,
      context,
      timestamp: new Date().toISOString(),
      controller: "TableController",
    };

    // In development, we might want to throw, in production log silently
    if (process.env.NODE_ENV === "development") {
      console.warn(`TableController: ${message}`, errorInfo);
    }
  }

  /**
   * Clear all caches for performance and memory management
   * @private
   */
  #clearCaches() {
    this.#scrollerCache = new WeakMap();
    this.#stickyElementsCache = new WeakMap();
    this.#lastFocusedCell = null;
  }

  /**
   * Determine if the given cell is in the first visible row of its table body.
   * Enhanced with better error handling and caching.
   *
   * @param {HTMLElement} cell - The focused cell
   * @returns {boolean} True if the cell is in the first row
   * @throws {Error} If cell is invalid
   * @private
   */
  #isFirstRow(cell) {
    try {
      if (!this.#isValidElement(cell)) {
        throw new Error("Invalid cell element");
      }

      const row = cell.closest("tr");
      const tbody = row?.closest("tbody");

      if (!tbody || !row) return false;

      // 📋 Use cached result if available
      const cacheKey = `firstRow_${tbody.id || tbody.dataset.cacheKey || "default"}`;
      if (
        this.#scrollerCache.has(tbody) &&
        this.#scrollerCache.get(tbody)[cacheKey]
      ) {
        return this.#scrollerCache.get(tbody)[cacheKey] === row;
      }

      // 📏 Find all visible rows in the tbody (not hidden by display:none or similar)
      const allRows = Array.from(tbody.querySelectorAll("tr")).filter((tr) => {
        const style = getComputedStyle(tr);
        return (
          style.display !== "none" &&
          style.visibility !== "hidden" &&
          style.opacity !== "0"
        );
      });

      // 📏 Cache the first row for performance
      if (!this.#scrollerCache.has(tbody)) {
        this.#scrollerCache.set(tbody, {});
      }
      this.#scrollerCache.get(tbody)[cacheKey] = allRows[0] || null;

      // ✅ Check if this is the first visible row
      return allRows.length > 0 && allRows[0] === row;
    } catch (error) {
      this.#handleError("Error checking if first row", error, { cell });
      return false;
    }
  }

  /**
   * Determine if the given cell is in the last visible row of its table body.
   * Enhanced with better error handling and caching.
   *
   * @param {HTMLElement} cell - The focused cell
   * @returns {boolean} True if the cell is in the last row
   * @throws {Error} If cell is invalid
   * @private
   */
  #isLastRow(cell) {
    try {
      if (!this.#isValidElement(cell)) {
        throw new Error("Invalid cell element");
      }

      const row = cell.closest("tr");
      const tbody = row?.closest("tbody");

      if (!tbody || !row) return false;

      // 📏 Use cached result if available
      const cacheKey = `lastRow_${tbody.id || tbody.dataset.cacheKey || "default"}`;
      if (
        this.#scrollerCache.has(tbody) &&
        this.#scrollerCache.get(tbody)[cacheKey]
      ) {
        return this.#scrollerCache.get(tbody)[cacheKey] === row;
      }

      // 🔍 Find all visible rows in the tbody (not hidden by display:none or similar)
      const allRows = Array.from(tbody.querySelectorAll("tr")).filter((tr) => {
        const style = getComputedStyle(tr);
        return (
          style.display !== "none" &&
          style.visibility !== "hidden" &&
          style.opacity !== "0"
        );
      });

      // 📏 Cache the last row for performance
      if (!this.#scrollerCache.has(tbody)) {
        this.#scrollerCache.set(tbody, {});
      }
      this.#scrollerCache.get(tbody)[cacheKey] =
        allRows[allRows.length - 1] || null;

      // ✅ Check if this is the last visible row
      return allRows.length > 0 && allRows[allRows.length - 1] === row;
    } catch (error) {
      this.#handleError("Error checking if last row", error, { cell });
      return false;
    }
  }

  /**
   * Unified method to compute sticky overlay heights with caching and error handling
   *
   * @param {HTMLElement} cell - The focused cell
   * @param {HTMLElement} scroller - The scrollable container
   * @param {'top'|'bottom'} position - Whether to check top or bottom sticky elements
   * @returns {number} Height in pixels of sticky overlay
   * @private
   */
  #getStickyOverlayHeight(cell, scroller, position) {
    try {
      if (!this.#isValidElement(cell) || !this.#isValidElement(scroller)) {
        return 0;
      }

      const table = cell.closest("table");
      if (!table) return 0;

      // 📏 Check cache first
      const cacheKey = `stickyHeight_${position}_${table.id || "default"}`;
      if (this.#stickyElementsCache.has(table)) {
        const cached = this.#stickyElementsCache.get(table)[cacheKey];
        if (cached && Date.now() - cached.timestamp < 5000) {
          // 5 second cache
          return cached.value;
        }
      }

      let maxHeight = 0;
      const selectors =
        position === "top"
          ? [
              "thead",
              "[class*='sticky'][class*='top']",
              "[style*='position: sticky'][style*='top']",
            ]
          : [
              "tfoot",
              "[class*='sticky'][class*='bottom']",
              "[style*='position: sticky'][style*='bottom']",
            ];

      // 📏 Check for sticky elements
      const stickyElements = [
        ...table.querySelectorAll(selectors[0]),
        ...scroller.querySelectorAll(selectors[1]),
        ...scroller.querySelectorAll(selectors[2]),
      ];

      for (const element of stickyElements) {
        if (!this.#isValidElement(element)) continue;

        const style = getComputedStyle(element);
        if (style.position === "sticky") {
          const positionValue = parseFloat(style[position]);

          if (Number.isFinite(positionValue)) {
            const rect = this.#getBoundingClientRectSafe(element);
            if (rect) {
              maxHeight = Math.max(maxHeight, rect.height);
            }
          }
        }
      }

      // 💾 Cache the result
      if (!this.#stickyElementsCache.has(table)) {
        this.#stickyElementsCache.set(table, {});
      }
      this.#stickyElementsCache.get(table)[cacheKey] = {
        value: maxHeight,
        timestamp: Date.now(),
      };

      return maxHeight;
    } catch (error) {
      this.#handleError(
        `Error computing ${position} sticky overlay height`,
        error,
        { cell, scroller, position },
      );
      return 0;
    }
  }

  /**
   * Check if a cell has sticky positioning with enhanced validation.
   *
   * @param {HTMLElement} cell - The cell to check
   * @returns {boolean} True if the cell is sticky positioned
   * @throws {Error} If cell is invalid
   * @private
   */
  #isStickyCell(cell) {
    try {
      if (!this.#isValidElement(cell)) {
        throw new Error("Invalid cell element");
      }

      const style = getComputedStyle(cell);
      return style.position === "sticky";
    } catch (error) {
      this.#handleError("Error checking if cell is sticky", error, { cell });
      return false;
    }
  }

  /**
   * Find the nearest horizontally scrollable ancestor with enhanced error handling and caching.
   * Returns null if none found (we intentionally do not default to the document scroller).
   *
   * @param {Element} el - The element to find scroller for
   * @returns {HTMLElement|null} The scrollable container or null
   * @throws {Error} If element is invalid
   * @private
   */
  #findHorizontalScroller(el) {
    try {
      if (!this.#isValidElement(el)) {
        throw new Error("Invalid element for scroller search");
      }

      // 💾 Check cache first
      if (this.#scrollerCache.has(el)) {
        const cached = this.#scrollerCache.get(el);
        if (cached && this.#isValidElement(cached)) {
          return cached;
        }
      }

      let node = el.parentElement;
      while (node && node !== document.body && this.#isValidElement(node)) {
        const style = getComputedStyle(node);
        const canScrollX =
          node.scrollWidth > node.clientWidth &&
          /(auto|scroll|overlay)/.test(style.overflowX || style.overflow);

        if (canScrollX) {
          // 💾 Cache the result
          this.#scrollerCache.set(el, node);
          return node;
        }
        node = node.parentElement;
      }

      // 💾 Cache null result to avoid repeated searches
      this.#scrollerCache.set(el, null);
      return null;
    } catch (error) {
      this.#handleError("Error finding horizontal scroller", error, { el });
      return null;
    }
  }

  /**
   * Compute the rightmost x (px from scroller's left edge) covered by left-pinned sticky cells in this row.
   * Enhanced with better error handling and performance optimizations.
   *
   * @param {HTMLElement} cell - The cell to analyze
   * @returns {number} The rightmost x position of sticky cells
   * @throws {Error} If cell is invalid
   * @private
   */
  #leftStickyOverlayRight(cell) {
    try {
      if (!this.#isValidElement(cell)) {
        throw new Error("Invalid cell element");
      }

      const row = cell.closest("tr");
      if (!row) return 0;

      // 💾 Check cache first
      const cacheKey = `stickyOverlay_${row.id || "default"}`;
      if (this.#scrollerCache.has(row)) {
        const cached = this.#scrollerCache.get(row)[cacheKey];
        if (cached && Date.now() - cached.timestamp < 1000) {
          // 1 second cache
          return cached.value;
        }
      }

      let maxRight = 0;
      for (const c of Array.from(row.children)) {
        if (!this.#isValidElement(c)) continue;

        const style = getComputedStyle(c);
        if (style.position !== "sticky") continue;

        const left = parseFloat(style.left);
        if (!Number.isFinite(left)) continue;

        const rect = this.#getBoundingClientRectSafe(c);
        if (rect) {
          maxRight = Math.max(maxRight, left + rect.width);
        }
      }

      // 💾 Cache the result
      if (!this.#scrollerCache.has(row)) {
        this.#scrollerCache.set(row, {});
      }
      this.#scrollerCache.get(row)[cacheKey] = {
        value: maxRight,
        timestamp: Date.now(),
      };

      return maxRight;
    } catch (error) {
      this.#handleError("Error computing left sticky overlay", error, { cell });
      return 0;
    }
  }

  /**
   * Scroll a target element into view with enhanced options and error handling.
   *
   * @param {Element} el - The element to scroll into view
   * @param {Object} options - Scroll options (optional)
   * @throws {Error} If element is invalid
   * @private
   */
  #scrollIntoView(el, options = {}) {
    try {
      if (!this.#isValidElement(el)) {
        throw new Error("Invalid element for scrollIntoView");
      }

      const scrollOptions = {
        block: "nearest",
        inline: "nearest",
        behavior: this.#prefersReducedMotion ? "auto" : "smooth",
        ...options,
      };

      el.scrollIntoView(scrollOptions);
    } catch (error) {
      this.#handleError("Error scrolling element into view", error, {
        el,
        options,
      });
    }
  }

  /**
   * Scroll a container horizontally by a delta with enhanced error handling and validation.
   *
   * @param {HTMLElement} scroller - The scrollable container
   * @param {number} dx - Positive scrolls right, negative left (LTR semantics)
   * @throws {Error} If scroller is invalid or dx is not a number
   * @private
   */
  #scrollBy(scroller, dx) {
    try {
      if (!this.#isValidElement(scroller)) {
        throw new Error("Invalid scroller element");
      }

      if (typeof dx !== "number" || isNaN(dx)) {
        throw new Error("Invalid scroll delta: must be a number");
      }

      if (dx === 0) return;

      // 🔒 Clamp using scrollLeft to maintain consistent bounds across browsers
      const min = 0;
      const max = Math.max(0, scroller.scrollWidth - scroller.clientWidth);
      const next = Math.min(max, Math.max(min, scroller.scrollLeft + dx));

      // 🎭 Use appropriate scroll method based on motion preferences
      if (this.#prefersReducedMotion) {
        scroller.scrollLeft = next;
      } else {
        scroller.scrollTo({
          left: next,
          behavior: "smooth",
        });
      }
    } catch (error) {
      this.#handleError("Error scrolling container", error, { scroller, dx });
    }
  }
}
