import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from '../utilities/form';

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
        fragment.appendChild(createHiddenInput(this.fieldNameValue, value));
      });
      this.fieldTarget.appendChild(fragment);
    }
  }

  clear() {
    sessionStorage.removeItem(this.storageKeyValue);
  }
}
