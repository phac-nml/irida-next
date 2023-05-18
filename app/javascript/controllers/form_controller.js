import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field"];

  connect() {
    const fieldValues = [];
    const localStorageValue = localStorage.getItem(window.location);
    if (localStorageValue != null) {
      const dataMap = JSON.parse(localStorageValue);
      for (let [key, value] of dataMap) {
        if (value) {
          fieldValues.push(key);
        }
      }
      this.fieldTarget.value = JSON.stringify(fieldValues);
    }
  }
}
