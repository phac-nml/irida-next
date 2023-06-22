import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field"];
  static values = {
    storageKey: {
      type: String,
      default: location.protocol + "//" + location.host + location.pathname,
    },
  };

  connect() {
    const storageValue = sessionStorage.getItem(this.storageKeyValue);
    this.fieldTarget.value = storageValue;
  }
}
