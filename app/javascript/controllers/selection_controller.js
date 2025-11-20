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

  togglePage(event) {
    const valuesToToggle = this.rowSelectionTargets.map((row) => row.value);
    this.#addOrRemove(event.target.checked, valuesToToggle);
  }

  toggle(event) {
    let valuesToToggle = [event.target.value];
    if (event.shiftKey && typeof this.#lastActiveCheckbox !== "undefined") {
      const startCheckbox = this.rowSelectionTargets.findIndex(
        (row) => row.id === this.#lastActiveCheckbox,
      );
      const endCheckbox = this.rowSelectionTargets.findIndex(
        (row) => row.id === event.target.id,
      );
      const [from, to] =
        startCheckbox < endCheckbox
          ? [startCheckbox, endCheckbox]
          : [endCheckbox, startCheckbox];
      valuesToToggle = this.rowSelectionTargets
        .slice(from, to + 1)
        .map((row) => row.value);
    }

    this.#addOrRemove(event.target.checked, valuesToToggle);
    this.#lastActiveCheckbox = event.target.id;
  }

  remove({ params: { id } }) {
    this.#addOrRemove(false, [id]);
  }

  clear() {
    this.update([]);
  }

  update(ids, announce = true) {
    if (!Array.isArray(ids)) {
      console.warn("SelectionController: ids must be an array");
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
      console.warn("Failed to parse stored selection items:", error);
    }

    // create default empty array
    this.update([], false);
    return [];
  }

  #addOrRemove(add, values) {
    let newStorageValue = this.getOrCreateStoredItems();
    if (add) {
      newStorageValue = [...new Set([...newStorageValue, ...values])];
    } else {
      newStorageValue = newStorageValue.filter(
        (value) => !values.includes(value),
      );
    }
    this.update(newStorageValue);
  }

  #updateUI(ids, announce) {
    try {
      this.rowSelectionTargets.map((row) => {
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
