import { Controller } from "@hotwired/stimulus";

//creates hidden fields within a form for selected files
export default class extends Controller {
  static targets = ["field"];

  static values = {
    fieldName: String,
  };

  connect() {
    const checkboxes = document.querySelectorAll(
      "input[name='attachment_ids[]']:checked"
    );

    for (let i = 0; i < checkboxes.length; i++) {
      const value = JSON.parse(checkboxes[i].value);
      if (value instanceof Array) {
        for (let arrayValue of value) {
          this.#addHiddenInput(`${this.fieldNameValue}[${i}][]`, arrayValue);
        }
      } else {
        this.#addHiddenInput(`${this.fieldNameValue}[${i}]`, value);
      }
    }
  }

  #addHiddenInput(name, value) {
    const element = document.createElement("input");
    element.type = "hidden";
    element.id = name;
    element.name = name;
    element.value = value;
    this.fieldTarget.appendChild(element);
  }
}
