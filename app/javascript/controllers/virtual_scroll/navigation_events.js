/**
 * Navigation Events Mixin for VirtualScrollController
 *
 * Handles table:navigation-start/end events from GridKeyboardNavigator.
 * These events coordinate focus management during async navigation to prevent
 * blur resets from interfering with keyboard navigation in virtualized tables.
 *
 * Key responsibilities:
 * - Track isNavigating state during async cell focus operations
 * - Prevent blur-triggered tabindex reset during navigation
 * - Handle table:focus-reset events for roving tabindex management
 * - Provide grace period after navigation to account for RAF-triggered renders
 */

const NAVIGATION_GRACE_PERIOD_MS = 150;

export const navigationEventsMixin = {
  /**
   * Set up navigation event listeners on connect
   * Call this from the controller's connect() method
   */
  setupNavigationEventListeners() {
    this._navigationState = {
      isNavigating: false,
      graceTimeout: null,
    };

    this.boundHandleNavigationStart = this._handleNavigationStart.bind(this);
    this.boundHandleNavigationEnd = this._handleNavigationEnd.bind(this);
    this.boundHandleCellBlur = this._handleCellBlur.bind(this);

    const table = this.element.querySelector("table");
    if (table) {
      this.lifecycle?.listen?.(
        table,
        "table:navigation-start",
        this.boundHandleNavigationStart,
      );
      this.lifecycle?.listen?.(
        table,
        "table:navigation-end",
        this.boundHandleNavigationEnd,
      );
      this.lifecycle?.listen?.(table, "focusout", this.boundHandleCellBlur);
    }
  },

  /**
   * Clean up navigation event state on disconnect
   * Call this from the controller's disconnect() method
   */
  cleanupNavigationEventListeners() {
    if (this._navigationState?.graceTimeout) {
      clearTimeout(this._navigationState.graceTimeout);
    }
    this._navigationState = null;
  },

  /**
   * Check if navigation is currently in progress
   * @returns {boolean}
   */
  get isNavigatingVirtualized() {
    return this._navigationState?.isNavigating ?? false;
  },

  /**
   * Handle navigation start event - prevents blur reset during async navigation
   */
  _handleNavigationStart() {
    if (!this._navigationState) return;

    // Clear any pending grace timeout
    if (this._navigationState.graceTimeout) {
      clearTimeout(this._navigationState.graceTimeout);
      this._navigationState.graceTimeout = null;
    }
    this._navigationState.isNavigating = true;
  },

  /**
   * Handle navigation end event - allows blur reset again after grace period
   * The grace period ensures RAF-triggered renders don't interfere with focus
   * after navigation completes but before the scroll handler settles
   */
  _handleNavigationEnd() {
    if (!this._navigationState) return;

    // Keep navigation protection active for a short grace period
    this._navigationState.graceTimeout = setTimeout(() => {
      if (this._navigationState) {
        this._navigationState.isNavigating = false;
        this._navigationState.graceTimeout = null;
      }
    }, NAVIGATION_GRACE_PERIOD_MS);
  },

  /**
   * Handle focusout events - resets tabindex when leaving table
   * Only resets if not during keyboard navigation
   * @param {FocusEvent} event
   */
  _handleCellBlur(event) {
    if (!event?.target?.closest) return;

    const table = event.target.closest("table");
    if (!table) return;

    // Don't reset during keyboard navigation (async cell focus in progress)
    if (this._navigationState?.isNavigating) return;

    // Check if focus is leaving the table entirely
    const relatedTarget = event.relatedTarget;
    if (relatedTarget && table.contains(relatedTarget)) {
      // Focus is moving within the table, don't reset
      return;
    }

    // Don't reset if the element losing focus was destroyed (virtualization re-render)
    // This prevents resetting focus when cells are removed and recreated during scrolling
    if (!document.body.contains(event.target)) {
      return;
    }

    // Focus is leaving the table - reset roving tabindex to first cell
    this._resetTabindexToFirstCell(table);
  },

  /**
   * Reset the roving tabindex when focus leaves the table.
   * Sets tabIndex=0 on either the tracked cell (if available) or the first cell.
   * Preserves the tracked position so user can return to it when tabbing back in.
   * @param {HTMLTableElement} table
   */
  _resetTabindexToFirstCell(table) {
    // Directly reset all cells to tabindex=-1
    table.querySelectorAll("[aria-colindex]").forEach((cell) => {
      cell.tabIndex = -1;
    });

    // Try to find the tracked cell first (preserves user's position for tab-back)
    const trackedRow = this.keyboardNavigator?.focusedRowIndex;
    const trackedCol = this.keyboardNavigator?.focusedColIndex;
    let targetCell = null;

    if (Number.isInteger(trackedRow) && Number.isInteger(trackedCol)) {
      const row = table.querySelector(`[aria-rowindex="${trackedRow}"]`);
      targetCell = row?.querySelector(`[aria-colindex="${trackedCol}"]`);
    }

    // Fall back to first header cell if tracked cell isn't rendered
    if (!targetCell) {
      targetCell = table.querySelector(
        "thead th[aria-colindex], thead td[aria-colindex]",
      );
    }

    if (targetCell) {
      targetCell.tabIndex = 0;
    }

    // Do NOT reset focusedRowIndex/focusedColIndex - preserve tracked position
    // so handleFocusin can restore it when user tabs back in
  },
};
