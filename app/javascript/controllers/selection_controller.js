import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // # indicates private attribute or method
  // see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/Private_properties
  #storageKey = null;
  #numSelected = 0;

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
    this.idempotentConnect();
  }

  idempotentConnect() {
    this.#storageKey =
      this.storageKeyValue ||
      `${location.protocol}//${location.host}${location.pathname}`;

    this.element.setAttribute("data-controller-connected", "true");

    const storageValue = this.getStoredItems();

    if (storageValue) {
      this.#numSelected = storageValue.length;
      this.#updateUI(storageValue);
    } else {
      this.save([]);
    }
  }

  togglePage(event) {
    const newStorageValue = this.getStoredItems();
    this.rowSelectionTargets.map((row) => {
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
    this.save(newStorageValue);
    this.#updateUI(newStorageValue);
  }

  toggle(event) {
    this.#addOrRemove(event.target.checked, event.target.value);
  }

  remove({ params: { id } }) {
    this.#addOrRemove(false, id);
  }

  clear() {
    sessionStorage.removeItem(this.#storageKey);
    this.#updateUI([]);
  }

  save(storageValue) {
    sessionStorage.setItem(this.#storageKey, JSON.stringify([...storageValue]));
    this.#numSelected = storageValue.length;
  }

  update(ids) {
    this.save(ids);
    this.#updateUI(ids);
  }

  getNumSelected() {
    return this.#numSelected;
  }

  getStoredItems() {
    return JSON.parse(sessionStorage.getItem(this.#storageKey)) || [];
  }

  #addOrRemove(add, storageValue) {
    const newStorageValue = this.getStoredItems();
    if (add) {
      newStorageValue.push(storageValue);
    } else {
      const index = newStorageValue.indexOf(storageValue);
      if (index > -1) {
        newStorageValue.splice(index, 1);
      }
    }
    this.save(newStorageValue);
    this.#updateUI(newStorageValue);
  }

  #updateUI(ids) {
    this.rowSelectionTargets.map((row) => {
      row.checked = ids.indexOf(row.value) > -1;
    });
    this.#updateActionButtons(ids.length);
    this.#updateCounts(ids.length);
    this.#setSelectPageCheckboxValue();
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

  #updateCounts(selected) {
    if (this.hasSelectedTarget) {
      this.selectedTarget.innerText = selected;
    }
    this.#announceSelectionStatus(selected);
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
}
