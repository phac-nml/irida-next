import { Controller } from "@hotwired/stimulus";

// creates a table listing all selected metadata for deletion
export default class extends Controller {
  static targets = ["count"];

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

    if (storageValues && this.hasCountTarget) {
      if (storageValues.length == 1) {
        this.countTarget.innerHTML = this.countTarget.innerHTML.replace("COUNT_PLACEHOLDER", `${storageValues.length} sample`)
      } else {
        this.countTarget.innerHTML = this.countTarget.innerHTML.replace("COUNT_PLACEHOLDER", `${storageValues.length} samples`)
      }
    }
  }
}
