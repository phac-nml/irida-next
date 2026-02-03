const SORT_FOCUS_STORAGE_KEY = "irida:virtual-scroll:pending-focus";
const SORT_FOCUS_TTL_MS = 5000;

export const focusMixin = {
  restorePendingFocusFromSessionStorage() {
    try {
      const storedFocusData = sessionStorage.getItem(SORT_FOCUS_STORAGE_KEY);
      if (!storedFocusData) return;

      const data = JSON.parse(storedFocusData);
      sessionStorage.removeItem(SORT_FOCUS_STORAGE_KEY);

      if (!data || typeof data !== "object") return;
      if (data.path && data.path !== window.location.pathname) return;
      if (
        !Number.isInteger(data.ts) ||
        Date.now() - data.ts > SORT_FOCUS_TTL_MS
      )
        return;

      if (Number.isInteger(data.row) && Number.isInteger(data.col)) {
        this.pendingFocusRow = data.row;
        this.pendingFocusCol = data.col;
        this.sortFocusToRestore = { row: data.row, col: data.col };
      }
    } catch {
      // Ignore storage errors
    }
  },

  setupSortFocusRestoration() {
    if (!this.sortFocusToRestore) return;

    this.boundRestoreSortFocusAfterLoad = () => {
      const target = this.sortFocusToRestore;
      if (!target) return;

      // Turbo may restore focus after our initial render; re-assert focus on load.
      requestAnimationFrame(() => {
        requestAnimationFrame(() => {
          this.focusCellIfNeeded(target.row, target.col);
        });
      });

      this.sortFocusToRestore = null;
    };

    this.lifecycle?.listen?.(
      document,
      "turbo:load",
      this.boundRestoreSortFocusAfterLoad,
      {
        once: true,
      },
    );

    this.lifecycle?.listen?.(
      document,
      "turbo:render",
      this.boundRestoreSortFocusAfterLoad,
      {
        once: true,
      },
    );

    // Fallback for cases where turbo:load doesn't fire (or fires before connect)
    const schedule =
      this.lifecycle?.timeout?.bind(this.lifecycle) || setTimeout;
    schedule(() => {
      if (this.sortFocusToRestore) {
        this.focusCellIfNeeded(
          this.sortFocusToRestore.row,
          this.sortFocusToRestore.col,
        );
        this.sortFocusToRestore = null;
      }
    }, 0);
  },

  focusCellIfNeeded(rowIndex, colIndex) {
    const tableElement = this.element.querySelector("table");
    const focusRoot = tableElement || this.bodyTarget;
    if (!focusRoot) return false;

    const row = focusRoot.querySelector(`[aria-rowindex="${rowIndex}"]`);
    const cell = row?.querySelector?.(`[aria-colindex="${colIndex}"]`);
    if (!cell) return false;

    const activeCell = document.activeElement?.closest?.("[aria-colindex]");
    if (activeCell === cell) return true;

    // Ensure roving tabindex points at the cell
    if (this.keyboardNavigator) {
      this.keyboardNavigator.focusedRowIndex = rowIndex;
      this.keyboardNavigator.focusedColIndex = colIndex;
      this.keyboardNavigator.applyRovingTabindex(rowIndex, colIndex);
    } else {
      focusRoot.querySelectorAll("[aria-colindex]").forEach((node) => {
        node.tabIndex = -1;
      });
      cell.tabIndex = 0;
    }
    cell.focus();

    return true;
  },

  rememberPendingFocusFromSortLink(link) {
    try {
      const headerCell = link.closest('[role="columnheader"][aria-colindex]');
      if (!headerCell) return;

      const col = parseInt(headerCell.getAttribute("aria-colindex"), 10);
      if (!Number.isInteger(col)) return;

      sessionStorage.setItem(
        SORT_FOCUS_STORAGE_KEY,
        JSON.stringify({
          path: window.location.pathname,
          ts: Date.now(),
          row: 1,
          col,
        }),
      );
    } catch {
      // Ignore storage errors
    }
  },

  rememberPendingFocusFromSortKeydown(event) {
    // When keyboard-navigation activates sorting, focus can be lost on Turbo refresh.
    // Store the currently focused column header so we can re-focus after render.
    if (!event || (event.key !== "Enter" && event.key !== " ")) return;

    const cell = event.target?.closest?.(
      '[role="columnheader"][aria-colindex]',
    );
    if (!cell || !this.element.contains(cell)) return;

    const link = cell.querySelector("a[href]");
    if (!link) return;

    // Only persist focus for Turbo replace navigations (sorting links)
    if (link.dataset?.turboAction !== "replace") return;

    this.rememberPendingFocusFromSortLink(link);
  },
};
