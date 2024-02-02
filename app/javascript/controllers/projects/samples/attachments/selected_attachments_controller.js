import { Controller } from "@hotwired/stimulus";

//creates hidden fields within a form for selected files
export default class extends Controller {
  static targets = ["field"];

  static values = {
    fieldName: String,
    storageKey: {
      type: String,
      default: `${location.protocol}//${location.host}${location.pathname}${location.search}`,
    },
  };

  connect() {
    const storageValues = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue)
    );

    if (storageValues) {
      for (let [storageValueIndex, storageValue] of storageValues.entries()) {
        const value = JSON.parse(storageValue);

        if (value instanceof Array) {
          for (let arrayValue of value) {
            this.#addHiddenInput(
              `${this.fieldNameValue}[${storageValueIndex}][]`,
              arrayValue
            );
          }
        } else {
          this.#addHiddenInput(
            `${this.fieldNameValue}[${storageValueIndex}]`,
            value
          );
        }
      }
    }
  }

  clear(event) {
    if (event.detail.success) {
      sessionStorage.removeItem(this.storageKeyValue);
    }
  }

  #addHiddenInput(name, value) {
    const element = document.createElement("input");
    element.type = "hidden";
    element.id = value;
    element.name = name;
    element.value = value;
    element.ariaHidden = "true";
    this.fieldTarget.appendChild(element);
  }
}
