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

    if (storageValues) {
      for (let [storageValueIndex, storageValue] of storageValues.entries()) {
        const value = JSON.parse(storageValue);

        if (value instanceof Array) {
          for (let arrayValue of value) {
            const element = document.createElement("input");
            element.type = "hidden";
            element.id = this.fieldNameValue + "[" + storageValueIndex + "][]";
            element.name =
              this.fieldNameValue + "[" + storageValueIndex + "][]";
            element.value = arrayValue;
            this.fieldTarget.appendChild(element);
          }
        } else {
          const element = document.createElement("input");
          element.type = "hidden";
          element.id = this.fieldNameValue + "[" + storageValueIndex + "]";
          element.name = this.fieldNameValue + "[" + storageValueIndex + "]";
          element.value = value;
          this.fieldTarget.appendChild(element);
        }
      }
    }
  }

  clear() {
    sessionStorage.removeItem(this.storageKeyValue);
  }
}
