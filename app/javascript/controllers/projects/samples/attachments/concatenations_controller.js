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

    for (var i = 0; i < checkboxes.length; i++) {
      const value = checkboxes[i].value;
      if (value instanceof Array) {
        for (let arrayValue of value) {
          const element = document.createElement("input");
          element.type = "hidden";
          element.id = `${this.fieldNameValue}[${i}][]`;
          element.name = `${this.fieldNameValue}[${i}][]`;
          element.value = arrayValue;
          this.fieldTarget.appendChild(element);
        }
      } else {
        const element = document.createElement("input");
        element.type = "hidden";
        element.id = `${this.fieldNameValue}[${i}]`;
        element.name = `${this.fieldNameValue}[${i}]`;
        element.value = value;
        this.fieldTarget.appendChild(element);
      }
    }
  }
}
