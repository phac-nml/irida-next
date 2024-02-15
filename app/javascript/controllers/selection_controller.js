import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // # indicates private attribute or method
  // see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/Private_properties
  #storageKey = null;

  static targets = ["rowSelection"];
  static outlets = ["action-link"];

  connect() {
    console.log('hi')
    // When you are first routed to a sample#show page, the path will not contain any query information about the
    // current tab. Because the path .../project/-/samples/sampleId and .../project/-/samples/sampleId?tab=files
    // want to handle the same stored checkboxes, a hidden div in views/projects/samples/attachments/_table
    // contains the sample ID in its class, and we check if that exists. If it exists and we're on the intial
    // path which doesn't contain the query, we hard-code add the query for the storageKey.
    if (document.getElementById('sampleId') &&
      location.pathname.endsWith(`/-/samples/${document.getElementById('sampleId').classList[0]}`)) {
      this.#storageKey = `${location.protocol}//${location.host}${location.pathname}?tab=files`;
    } else {
      this.#storageKey =
        this.element.dataset.storageKey ||
        `${location.protocol}//${location.host}${location.pathname}${location.search}`;
    }


    this.element.setAttribute("data-controller-connected", "true");

    const storageValue = this.#getStoredSamples();

    if (storageValue) {
      this.rowSelectionTargets.map((row) => {
        if (storageValue.indexOf(row.value) > -1) {
          row.checked = true;
        }
      });
      this.#updateActionLinks(storageValue.length);
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

  save(storageValue) {
    sessionStorage.setItem(this.#storageKey, JSON.stringify([...storageValue]));
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
    return JSON.parse(sessionStorage.getItem(this.#storageKey)) || [];
  }

  #updateActionLinks(count) {
    this.actionLinkOutlets.forEach((outlet) => {
      outlet.setDisabled(count);
    });
  }
}
