import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // # indicates private attribute or method
  // see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/Private_properties
  #storageKey = null;

  static targets = ["rowSelection", "selectAll", "total", "selected"];
  static outlets = ["action-link"];

  static values = {
    storageKey: {
      type: String,
    },
    total: Number,
    active: Boolean
  };

  connect() {
    if (this.activeValue) {
      this.#storageKey =
        this.storageKeyValue ||
        `${location.protocol}//${location.host}${location.pathname}${location.search}`;

      this.element.setAttribute("data-controller-connected", "true");

      const storageValue = this.#getStoredSamples();

      if (storageValue) {
        this.#updateUI(storageValue);
      } else {
        this.save([]);
      }

      this.#updatedCounts(storageValue.length);
    }
  }

  actionLinkOutletConnected(outlet) {
    const storageValue = this.#getStoredSamples();
    outlet.setDisabled(storageValue.length);
  }

  toggle(event) {
    this.#addOrRemove(event.target.checked, event.target.value);
  }

  remove({ params: { id } }) {
    id = JSON.stringify(id).replaceAll(",", ", ");
    this.#addOrRemove(false, id);
  }

  clear() {
    sessionStorage.removeItem(this.#storageKey);
  }

  save(storageValue) {
    sessionStorage.setItem(this.#storageKey, JSON.stringify([...storageValue]));
  }

  update(ids) {
    this.save(ids);
    this.#updateUI(ids);
  }

  #addOrRemove(add, storageValue) {
    const newStorageValue = this.#getStoredSamples();

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
    this.#updatedCounts(newStorageValue.length);
  }

  #updateUI(ids) {
    this.rowSelectionTargets.map((row) => {
      row.checked = ids.indexOf(row.value) > -1;
    });
    this.#updateActionLinks(ids.length);
    this.#setSelectAllCheckboxValue(ids.length);
    this.#updatedCounts(ids.length);
  }

  #getStoredSamples() {
    return JSON.parse(sessionStorage.getItem(this.#storageKey)) || [];
  }

  #updateActionLinks(count) {
    this.actionLinkOutlets.forEach((outlet) => {
      outlet.setDisabled(count);
    });
  }

  #setSelectAllCheckboxValue(total) {
    this.selectAllTarget.checked = this.totalValue === total;
  }

  #updatedCounts(selected) {
    this.totalTarget.innerText = this.totalValue;
    this.selectedTarget.innerText = selected;
  }
}
