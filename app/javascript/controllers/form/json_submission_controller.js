import { Controller } from "@hotwired/stimulus";
import {
  formDataToJsonParams,
  normalizeParams,
  handleFormResponse,
} from "utilities/form";

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
    let method = "post";
    if (formData.get("_method")) {
      method = formData.get("_method");
      delete jsonObject._method;
    }

    Turbo.fetch(this.formTarget.action, {
      method: method.toUpperCase(),
      headers: {
        "Content-Type": "application/json",
        Accept: "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
      },
      credentials: "same-origin",
      body: JSON.stringify(jsonObject),
      redirect: "follow",
    })
      .then((response) => handleFormResponse(response))
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
