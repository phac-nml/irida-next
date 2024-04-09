import { Controller } from "@hotwired/stimulus";

// creates a table listing all selected metadata for deletion
export default class extends Controller {
  static targets = ["summary"];

  static values = {
    storageKey: {
      type: String,
      default: location.protocol + "//" + location.host + location.pathname,
    },
    singular: {
      type: String
    },
    plural: {
      type: String
    }
  };

  connect() {
    const storageValues = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue)
    );

    if (storageValues && this.hasSummaryTarget) {
      if (storageValues.length == 1) {
        this.summaryTarget.innerHTML = this.singularValue
      } else {
        this.summaryTarget.innerHTML = this.pluralValue.replace("COUNT_PLACEHOLDER", storageValues.length)
      }
    }
  }
}
