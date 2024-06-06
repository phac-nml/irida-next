import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field"];

  static values = {
    fieldName: String,
    storageKey: {
      type: String,
      default: `${location.protocol}//${location.host}${location.pathname}`,
    },
  };

  connect() {
    const storageValues = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue),
    );

    if (storageValues) {
      const fragment = document.createDocumentFragment();
      storageValues.forEach((value) => {
        fragment.appendChild(this.#createHiddenInput(value));
      });
      this.fieldTarget.appendChild(fragment);
    }
  }

  clear() {
    sessionStorage.removeItem(this.storageKeyValue);
  }

  #createHiddenInput(value) {
    const element = document.createElement("input");
    element.type = "hidden";
    element.name = this.fieldNameValue;
    element.value = value;
    return element;
  }
}
