import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // # indicates private attribute or method
  // see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/Private_properties

  static targets = ["rowSelection"];
  static values = {
    storageKey: {
      type: String,
      default: `${location.protocol}//${location.host}${location.pathname}`,
    },
  };
  static outlets = ["action-link"];

  connect() {
    this.element.setAttribute("data-controller-connected", "true");

    const storageValue = this.#getStoredSamples();

    if (storageValue) {
      this.rowSelectionTargets.map((row) => {
        if (storageValue.indexOf(row.value) > -1) {
          row.checked = true;
        }
      });
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
    this.#addOrRemove(false, id.toString());
  }

  save(storageValue) {
    sessionStorage.setItem(
      this.storageKeyValue,
      JSON.stringify([...storageValue])
    );
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
  }

  #getStoredSamples() {
    return JSON.parse(sessionStorage.getItem(this.storageKeyValue)) || [];
  }

  #updateActionLinks(count) {
    this.actionLinkOutlets.forEach((outlet) => {
      outlet.setDisabled(count);
    });
  }
}
