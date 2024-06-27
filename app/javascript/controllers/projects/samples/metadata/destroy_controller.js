import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
  static targets = ["field"];

  static values = {
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
      for (const storageValue of storageValues) {
        this.fieldTarget.appendChild(
          createHiddenInput(`sample[metadata][${storageValue}]`, "")
        );
      }
    }
  }

  clear() {
    sessionStorage.removeItem(this.storageKeyValue);
  }
}
