import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field", "nameInput", "sampleCount"];

  static values = {
    storageKeys: {
      type: Array,
      default: []
    },
  };

  connect() {
    let storageValues = []
    for (let sessionStorageKey in sessionStorage) {
      // All current sample page sessionStorageKeys contain samples, and excludes any checked off attachments
      if (sessionStorageKey.includes("/samples") && !sessionStorageKey.includes("files")) {
        storageValues = storageValues.concat(JSON.parse(sessionStorage.getItem(sessionStorageKey)))
        this.storageKeysValue.push(sessionStorageKey)
      }
    }

    if (storageValues.length > 0) {
      this.sampleCountTarget.innerHTML = `${this.sampleCountTarget.innerHTML} ${storageValues.length}`
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
    this.storageKeysValue.forEach(this.clearKey)
  }

  clearKey(key) {
    sessionStorage.removeItem(key);
  }
}
