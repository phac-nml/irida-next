import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  // # indicates private attribute or method
  // see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/Private_properties
  #numSelected = 0;

  static targets = ["rowSelection", "selectPage", "selected"];
  static outlets = ["action-button"];

  static values = {
    storageKey: {
      type: String,
      default: `${location.protocol}//${location.host}${location.pathname}`,
    },
    total: Number,
  };

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
    this.#updateActionButtons();
    this.#setSelectPageCheckboxValue();
  }

  rowSelectionTargetConnected(rowCheckbox) {
    console.log("rowSelectionTargetConnected", this.storageKeyValue);
    const storedValues = this.getStoredItems();
    rowCheckbox.checked = storedValues.indexOf(rowCheckbox.value) > -1;
  }

  selectedTargetConnected(target) {
    target.innerText = this.getStoredItems().length;
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
    this.selectedTarget.innerText = this.getStoredItems().length;
  }

  remove({ params: { id } }) {
    this.#addOrRemove(false, id);
  }

  clear() {
    sessionStorage.removeItem(this.storageKeyValue);
    this.#updateUI([]);
  }

  save(storageValue) {
    sessionStorage.setItem(
      this.storageKeyValue,
      JSON.stringify([...storageValue]),
    );
    this.#numSelected = storageValue.length;
  }

  update(ids) {
    this.save(ids);
    this.#updateRowSelectionTargets(ids);
    this.#updateUI(ids);
  }

  getNumSelected() {
    return this.getStoredItems().length;
  }

  getStoredItems() {
    return JSON.parse(sessionStorage.getItem(this.storageKeyValue)) || [];
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
    this.#updateActionButtons();
    if (this.hasSelectedTarget) {
      this.selectedTarget.innerText = ids.length;
    }
    this.#setSelectPageCheckboxValue();
  }

  #updateActionButtons() {
    const count = this.getNumSelected();
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
    }
  }

  #updateRowSelectionTargets(ids) {
    this.rowSelectionTargets.map((row) => {
      row.checked = ids.indexOf(row.value) > -1;
    });
  }
}
