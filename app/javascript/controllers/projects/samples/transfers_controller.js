import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field"];

  static values = {
    fieldName: String,
    storageKey: {
      type: String,
      default: location.protocol + "//" + location.host + location.pathname,
    },
  };

  connect() {
    const storageValues = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue)
    );

    for (const storageValue of storageValues) {
      const element = document.createElement("input");
      element.type = "hidden";
      element.id = this.fieldNameValue;
      element.name = this.fieldNameValue;
      element.value = storageValue;
      this.fieldTarget.appendChild(element);
    }
  }

  clear() {
    sessionStorage.removeItem(this.storageKeyValue);
  }
}
