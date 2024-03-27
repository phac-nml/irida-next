import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field"];

  static values = {
    storageKeys: {
      type: Array,
      default: []
    }
  };

  updateParams() {
    this.#resetParams()
    let storageValues = []
    for (let sessionStorageKey in sessionStorage) {
      if (sessionStorageKey.includes("/samples")
        && sessionStorageKey.includes(`${location.protocol}//${location.host}`)
        && !sessionStorageKey.includes("files")) {
        storageValues = storageValues.concat(JSON.parse(sessionStorage.getItem(sessionStorageKey)))
      }
    }
    if (storageValues.length > 0) {
      for (const storageValue of storageValues) {
        const element = document.createElement("input");
        element.type = "hidden";
        element.name = "data_export[selected_samples[]";
        element.value = storageValue;
        this.fieldTarget.appendChild(element);
      }
      console.log(this.fieldTarget)
    }
  }

  // Resets field/selected samples when user opens and closes the create export modal without creating an export
  #resetParams() {
    this.fieldTarget.innerHTML = ""
  }
}
