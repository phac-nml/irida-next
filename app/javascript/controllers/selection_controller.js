import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["rowSelection", "selectPage", "selected", "status"];
  static outlets = ["action-button"];

  static values = {
    storageKey: {
      type: String,
    },
    total: Number,
    countMessageOne: String,
    countMessageOther: String,
  };

  connect() {
    this.element.setAttribute("data-controller-connected", "true");

    this.boundOnMorph = this.onMorph.bind(this);
    this.boundHandleKeydown = this.#handleKeydown.bind(this);

    this.update(this.getOrCreateStoredItems(), false);

    document.addEventListener("turbo:morph", this.boundOnMorph);
    this.element.addEventListener("keydown", this.boundHandleKeydown);
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.boundOnMorph);
    this.element.removeEventListener("keydown", this.boundHandleKeydown);
  }

  onMorph() {
    this.update(this.getOrCreateStoredItems(), false);
  }

  togglePage(event) {
    const newStorageValue = this.getOrCreateStoredItems();
    this.rowSelectionTargets.forEach((row) => {
      if (row.checked !== event.target.checked) {
        row.checked = event.target.checked;
        if (row.checked) {
          newStorageValue.push(row.value);
        } else {
          const index = newStorageValue.indexOf(row.value);
          if (index > -1) {
            newStorageValue.splice(index, 1);
          }
        }
      }
    });
    this.update(newStorageValue);
  }

  toggle(event) {
    this.#addOrRemove(event.target.checked, event.target.value);
  }

  remove({ params: { id } }) {
    this.#addOrRemove(false, id);
  }

  clear() {
    this.update([]);
  }

  update(ids, announce = true) {
    if (!Array.isArray(ids)) {
      return;
    }

    sessionStorage.setItem(this.#getStorageKey(), JSON.stringify(ids));
    this.#updateUI(ids, announce);
  }

  getOrCreateStoredItems() {
    try {
      const storedItems = JSON.parse(
        sessionStorage.getItem(this.#getStorageKey()),
      );
      if (Array.isArray(storedItems)) {
        return storedItems;
      }
    } catch (error) {
      // Ignore storage parse errors and fall back to defaults
    }

    // create default empty array
    this.update([], false);
    return [];
  }

  getStoredItemsCount() {
    return this.getOrCreateStoredItems().length;
  }

  #addOrRemove(add, storageValue) {
    const newStorageValue = this.getOrCreateStoredItems();
    if (add) {
      newStorageValue.push(storageValue);
    } else {
      const index = newStorageValue.indexOf(storageValue);
      if (index > -1) {
        newStorageValue.splice(index, 1);
      }
    }
    this.update(newStorageValue);
  }

  #updateUI(ids, announce) {
    try {
      this.rowSelectionTargets.forEach((row) => {
        const isSelected = ids.indexOf(row.value) > -1;
        row.checked = isSelected;
        this.#updateRowAriaSelected(row, isSelected);
      });
      this.#updateActionButtons(ids.length);
      this.#updateCounts(ids.length, announce);
      this.#setSelectPageCheckboxValue();
    } catch (error) {
      // Ignore UI update errors to avoid breaking interaction
    }
  }

  #updateActionButtons(count) {
    this.actionButtonOutlets.forEach((outlet) => {
      outlet.setDisabled(count);
    });
  }

  #setSelectPageCheckboxValue() {
    if (this.hasSelectPageTarget) {
      const uncheckedBoxes = this.rowSelectionTargets.filter(
        (row) => !row.checked,
      );
      this.selectPageTarget.checked = uncheckedBoxes.length === 0;
      this.selectPageTarget.indeterminate = !(
        uncheckedBoxes.length === 0 ||
        uncheckedBoxes.length === this.rowSelectionTargets.length
      );
    }
  }

  #updateCounts(selected, announce) {
    if (this.hasSelectedTarget) {
      this.selectedTarget.textContent = String(selected);
    }
    if (announce) {
      this.#announceSelectionStatus(selected);
    }
  }

  #updateRowAriaSelected(rowCheckbox, isSelected) {
    const row = rowCheckbox.closest('[role="row"]');
    if (!row) return;
    row.setAttribute("aria-selected", isSelected ? "true" : "false");
  }

  /**
   * 🔊 Announce current selection status to an aria-live region.
   *
   * - 🧮 Builds a localized message using one/other templates: "X of Y selected".
   * - 🧩 Reads values from data attributes (`countMessageOneValue`, `countMessageOtherValue`).
   * - ♿ Updates the component's hidden polite live region, falling back to `#sr-status` if absent.
   *
   * @param {number} selected - Current number of selected items.
   * @private
   */
  #announceSelectionStatus(selected) {
    // 🧮 Choose the correct i18n template based on count
    const messageTemplate =
      selected === 1 ? this.countMessageOneValue : this.countMessageOtherValue;

    // 🔁 Interpolate counts into the template
    const message = messageTemplate
      .replace("%{selected}", String(selected))
      .replace("%{total}", String(this.totalValue || 0));

    // 📣 Update local status region or fallback global live region
    if (this.hasStatusTarget) {
      this.statusTarget.textContent = message;
    } else {
      const globalStatus = document.querySelector("#sr-status");
      if (globalStatus) globalStatus.textContent = message;
    }
  }

  #getStorageKey() {
    return (
      this.storageKeyValue ||
      `${location.protocol}//${location.host}${location.pathname}`
    );
  }

  /**
   * Handle keyboard events for selection
   * @param {KeyboardEvent} event - The keydown event
   * @private
   */
  #handleKeydown(event) {
    // Ignore if actively editing a cell
    const activeElement = document.activeElement;
    if (activeElement?.dataset?.editing === "true") return;

    // Shift+Space: Select/deselect focused row
    if (event.key === " " && event.shiftKey && !event.ctrlKey) {
      event.preventDefault();
      this.#selectFocusedRow();
      return;
    }

    // Ctrl+A: Select/deselect all visible
    if (event.key === "a" && event.ctrlKey && !event.shiftKey) {
      event.preventDefault();
      this.#selectAllVisible();
      return;
    }
  }

  /**
   * Select or deselect the focused row
   * @private
   */
  #selectFocusedRow() {
    const focusedCell = document.activeElement.closest("[aria-colindex]");
    if (!focusedCell) return;

    const row = focusedCell.closest('[role="row"]');
    const checkbox = row?.querySelector(
      'input[type="checkbox"][data-selection-target="rowSelection"]',
    );

    if (checkbox) {
      checkbox.checked = !checkbox.checked;
      checkbox.dispatchEvent(new Event("input", { bubbles: true }));
    }
  }

  /**
   * Select or deselect all visible rows
   * @private
   */
  #selectAllVisible() {
    // Toggle all: if any unchecked, check all; if all checked, uncheck all
    const allChecked = this.rowSelectionTargets.every((cb) => cb.checked);
    const newCheckedState = !allChecked;

    this.rowSelectionTargets.forEach((cb) => {
      cb.checked = newCheckedState;
    });

    // Trigger update to sync with session storage
    const ids = newCheckedState
      ? this.rowSelectionTargets.map((cb) => cb.value)
      : [];
    this.update(ids);
  }
}
