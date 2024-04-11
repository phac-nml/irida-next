import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

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
      sessionStorage.getItem(this.storageKeyValue),
    );

    if (storageValues) {
      const chunked = _.chunk(storageValues, 100);
      const div = document.createElement("div");

      // iterate over each chunk and add the id's as hidden inputs to div. After each chunk, use a timeout to allow other code to run
      chunked.forEach((chunk) => {
        setTimeout(() => {
          chunk.forEach((value) => {
            div.appendChild(this.#createHiddenInput(value));
          });
        }, 100);
      });
      this.fieldTarget.appendChild(div);
    }
  }

  clear() {
    sessionStorage.removeItem(this.storageKeyValue);
  }

  #createHiddenInput(value) {
    const element = document.createElement("input");
    element.type = "hidden";
    element.id = this.fieldNameValue;
    element.name = this.fieldNameValue;
    element.value = value;
    return element;
  }
}
