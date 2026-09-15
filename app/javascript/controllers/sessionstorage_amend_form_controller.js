import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
  static targets = ["field"];

  static values = {
    fieldName: String,
    storageKey: String,
  };

  #hiddenInputs = [];

  get #storageKey() {
    return this.hasStorageKeyValue
      ? this.storageKeyValue
      : `${location.protocol}//${location.host}${location.pathname}`;
  }

  connect() {
    const storageValues = JSON.parse(sessionStorage.getItem(this.#storageKey));

    if (storageValues) {
      const fragment = document.createDocumentFragment();
      storageValues.forEach((value) => {
        const input = createHiddenInput(this.fieldNameValue, value);
        this.#hiddenInputs.push(input);
        fragment.appendChild(input);
      });
      this.fieldTarget.appendChild(fragment);
    }
  }

  disconnect() {
    this.#hiddenInputs.forEach((input) => input.remove());
    this.#hiddenInputs = [];
  }

  clear() {
    sessionStorage.removeItem(this.#storageKey);
  }
}
