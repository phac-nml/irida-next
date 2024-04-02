import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field", "nameInput", "sampleCount"];

  static values = {
    fieldName: String,
    storageKey: {
      type: String,
      default: `${location.protocol}//${location.host}${location.pathname}${location.search}`
    },
  };

  connect() {
    const storageValues = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue)
    );
    if (storageValues) {
      this.sampleCountTarget.innerHTML += ` ${storageValues.length}`
      for (const storageValue of storageValues) {
        const element = document.createElement("input");
        element.type = "hidden";
        element.name = "data_export[export_parameters[ids]][]";
        element.value = storageValue;
        this.fieldTarget.appendChild(element);
      }
    }
  }
  // Prevents an empty name input to be submitted as an empty string (we want nil)
  submit() {
    if (!this.nameInputTarget.value) {
      this.nameInputTarget.remove()
    }
  }

  clear() {
    sessionStorage.removeItem(this.storageKeyValue);
  }
}
