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

  #lastActiveCheckbox;
  /**
   * Called when the Stimulus controller connects to the DOM.
   * - Marks the element as connected for debugging/automation.
   * - Restores any stored selection from sessionStorage.
   * - Listens for Turbo "morph" events to re-sync UI after partial updates.
   */
  connect() {
    this.element.setAttribute("data-controller-connected", "true");

    this.boundOnMorph = this.onMorph.bind(this);

    this.update(this.getOrCreateStoredItems(), false);

    document.addEventListener("turbo:morph", this.boundOnMorph);
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.boundOnMorph);
  }

  onMorph() {
    this.update(this.getOrCreateStoredItems(), false);
  }

  /**
   * Toggle selection state for all rows on the current page.
   * When the page checkbox is checked, all row values are added to the selection;
   * when unchecked they are removed.
   * @param {Event} event - Change event from the page-level checkbox
   */
  togglePage(event) {
    const valuesToToggle = this.rowSelectionTargets.map((row) => row.value);
    this.#modifySelection(event.target.checked, valuesToToggle);
  }

  /**
   * Toggle a single row selection. Supports shift-click range selection.
   * - If shiftKey is pressed and there is a last active checkbox id recorded,
   *   calculate the range between the previous checkbox and the clicked one and
   *   toggle every checkbox in that range.
   * @param {Event} event - Change event from an individual row checkbox
   */
  toggle(event) {
    let valuesToToggle = [event.target.value];

    // Shift-click range selection — only when the previous active checkbox still exists
    if (event.shiftKey && typeof this.#lastActiveCheckbox !== "undefined") {
      const startIndex = this.rowSelectionTargets.findIndex(
        (row) => row.id === this.#lastActiveCheckbox,
      );
      const endIndex = this.rowSelectionTargets.findIndex(
        (row) => row.id === event.target.id,
      );

      // Only perform range selection when both indices are valid.
      // This prevents an out-of-range slice if the stored lastActiveCheckbox
      // no longer exists in the current rowSelectionTargets (e.g. after a partial update).
      if (startIndex > -1 && endIndex > -1) {
        // Determine lower/higher bounds for the range
        let low = Math.min(startIndex, endIndex);
        let high = Math.max(startIndex, endIndex);

        // If the clicked checkbox is being checked, exclude the clicked
        // checkbox from the range by moving the boundary inward.
        if (event.target.checked === false) {
          if (endIndex > startIndex) {
            high = high - 1;
          } else {
            low = low + 1;
          }
        }

        // Only build the list when the adjusted range is non-empty
        if (low <= high) {
          const indices = [];
          for (let i = low; i <= high; i++) indices.push(i);
          valuesToToggle = indices.map(
            (i) => this.rowSelectionTargets[i].value,
          );
        } else {
          valuesToToggle = [];
        }
      }
    }

    this.#modifySelection(event.target.checked, valuesToToggle);
    this.#lastActiveCheckbox = event.target.id;
  }

  /**
   * Remove a single id from the selection (used by action buttons or other code).
   * Receives a Stimulus action parameter object: { params: { id } }
   * @param {{params: {id: string}}} param0
   */
  remove({ params: { id } }) {
    this.#modifySelection(false, [id]);
  }

  clear() {
    this.update([]);
  }

  update(ids, announce = true) {
    if (!Array.isArray(ids)) {
      console.warn("SelectionController: ids must be an array");
      return;
    }
    // Persist selection and reflect changes in the UI
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
      console.warn("Failed to parse stored selection items:", error);
    }

    // create default empty array
    this.update([], false);
    return [];
  }

  /**
   * Modify the stored selection by adding or removing provided values, then
   * persist and update the UI.
   * @param {boolean} add - true to add values, false to remove
   * @param {Array<string>} values - array of ids to add or remove
   * @private
   */
  #modifySelection(add, values) {
    let newStorageValue = this.getOrCreateStoredItems();
    if (add) {
      // Use a Set to deduplicate values
      newStorageValue = [...new Set([...newStorageValue, ...values])];
    } else {
      newStorageValue = newStorageValue.filter(
        (value) => !values.includes(value),
      );
    }
    this.update(newStorageValue);
  }

  /**
   * Update all UI elements to reflect the current selection state.
   * This updates row checkboxes, action buttons, counts and the page-level
   * select-all checkbox state.
   * @param {Array<string>} ids - current selection ids
   * @param {boolean} announce - whether to announce via aria-live region
   * @private
   */
  #updateUI(ids, announce) {
    try {
      // Set checkbox checked states based on whether their value is included
      this.rowSelectionTargets.forEach((row) => {
        row.checked = ids.indexOf(row.value) > -1;
      });

      this.#updateActionButtons(ids.length);
      this.#updateCounts(ids.length, announce);
      this.#setSelectPageCheckboxValue();
    } catch (error) {
      console.error("selectionController: Failed to update UI", error);
    }
  }

  #updateActionButtons(count) {
    // Ensure outlets exist before iterating
    if (!this.actionButtonOutlets) return;

    this.actionButtonOutlets.forEach((outlet) => {
      // Outlet's setDisabled expects the number of selected items to decide
      // whether to enable/disable action buttons.
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
      this.selectedTarget.innerText = selected;
    }
    if (announce) {
      this.#announceSelectionStatus(selected);
    }
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
}
