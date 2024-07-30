import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // # indicates private attribute or method
  // see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/Private_properties
  #storageKey = null;
  #numSelected = 0;

  static targets = ["rowSelection", "selectAll", "selected"];
  static outlets = ["action-link"];

  static values = {
    storageKey: {
      type: String,
    },
    total: Number,
  };

  connect() {
    this.idempotentConnect();
  }

  idempotentConnect() {
    this.#storageKey =
      this.storageKeyValue ||
      `${location.protocol}//${location.host}${location.pathname}`;

    this.element.setAttribute("data-controller-connected", "true");

    const storageValue = this.getStoredSamples();

    if (storageValue) {
      this.#updateUI(storageValue);
      this.#numSelected = storageValue.length;
    } else {
      this.save([]);
    }

    this.#updateCounts(storageValue.length);
  }

  selectAllTargetConnected(target) {
    console.log("Select all reconnected");
    this.#setSelectAllCheckboxValue(this.#numSelected);
  }

  toggle(event) {
    this.#addOrRemove(event.target.checked, event.target.value);
  }

  remove({ params: { id } }) {
    this.#addOrRemove(false, id);
  }

  clear() {
    sessionStorage.removeItem(this.#storageKey);
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

  getStoredSamples() {
    return JSON.parse(sessionStorage.getItem(this.#storageKey)) || [];
  }

  #addOrRemove(add, storageValue) {
    const newStorageValue = this.getStoredSamples();

    if (add) {
      newStorageValue.push(storageValue);
    } else {
      const index = newStorageValue.indexOf(storageValue);
      if (index > -1) {
        newStorageValue.splice(index, 1);
      }
    }

    this.save(newStorageValue);
    this.#updateActionLinks(newStorageValue.length);
    this.#setSelectAllCheckboxValue(newStorageValue.length);
    this.#updateCounts(newStorageValue.length);
  }

  #updateUI(ids) {
    this.rowSelectionTargets.map((row) => {
      row.checked = ids.indexOf(row.value) > -1;
    });
    this.#updateActionLinks(ids.length);
    this.#setSelectAllCheckboxValue(ids.length);
    this.#updateCounts(ids.length);
  }

  #updateActionLinks(count) {
    this.actionLinkOutlets.forEach((outlet) => {
      outlet.setDisabled(count);
    });
  }

  #setSelectAllCheckboxValue(numSelected) {
    if (this.hasSelectAllTarget && this.totalValue > 0) {
      this.selectAllTarget.checked = this.totalValue === numSelected;
    }
  }

  #updateCounts(selected) {
    if (this.hasSelectedTarget) {
      this.selectedTarget.innerText = selected;
    }
  }
}
