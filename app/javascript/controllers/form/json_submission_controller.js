import { Controller } from "@hotwired/stimulus";
import { formDataToJsonParams, normalizeParams } from "utilities/form";

export default class extends Controller {
  static targets = ["form"];
  static outlets = ["selection"];
  static values = {
    fieldName: String,
    clearSelection: Boolean,
  };

  submitForm(event) {
    event.preventDefault();
    event.stopPropagation();

    const formData = new FormData(this.formTarget);
    const jsonObject = this.#toJson(formData);

    fetch(this.formTarget.action, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "text/vnd.turbo-stream.html",
      },
      body: JSON.stringify(jsonObject),
    })
      .then((r) => r.text())
      .then((html) => Turbo.renderStreamMessage(html))
      .finally(() => {
        if (this.clearSelectionValue) {
          this.selectionOutlet.clear();
        }
      });
  }

  #toJson(formData) {
    let params = formDataToJsonParams(formData);

    normalizeParams(
      params,
      this.fieldNameValue,
      this.selectionOutlet.getStoredItems(),
      0,
    );

    return params;
  }
}
