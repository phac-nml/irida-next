import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // # indicates private attribute or method
  // see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/Private_properties
  #storageKey = null;

  static targets = ["rowSelection", "count", "selectAll"];
  static outlets = ["action-link"];

  static values = {
    storageKey: {
      type: String,
    },
    total: Number,
  };

  connect() {
    this.#storageKey =
      this.storageKeyValue ||
      `${location.protocol}//${location.host}${location.pathname}${location.search}`;

    this.element.setAttribute("data-controller-connected", "true");

    const storageValue = this.#getStoredSamples();

    if (storageValue) {
      this.#updateUI(storageValue);
      this.updateSelectionCounts(storageValue.length);
    } else {
      this.save([]);
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

  updateSelectionCounts(count) {
    this.countTarget.innerText = count;
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
    this.updateSelectionCounts(newStorageValue.length);
    this.#updateSelectAllCB(newStorageValue.length);
  }

  #updateUI(ids) {
    this.rowSelectionTargets.map((row) => {
      row.checked = ids.indexOf(row.value) > -1;
    });
    this.#updateActionLinks(ids.length);
    this.updateSelectionCounts(ids.length);
    this.#updateSelectAllCB(ids.length);
  }

  #getStoredSamples() {
    return JSON.parse(sessionStorage.getItem(this.#storageKey)) || [];
  }

  #updateActionLinks(count) {
    this.actionLinkOutlets.forEach((outlet) => {
      outlet.setDisabled(count);
    });
  }

  #updateSelectAllCB(total) {
    this.selectAllTarget.checked = this.totalValue === total;
  }
}
