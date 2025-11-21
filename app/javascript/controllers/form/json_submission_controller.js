import { Controller } from "@hotwired/stimulus";
import { formDataToJsonParams, normalizeParams } from "../../utilities/form";

export default class extends Controller {
  static targets = ["form"];
  static outlets = ["selection"];
  static values = {
    fieldName: String,
    clearSelection: Boolean,
  };

  connect() {
    this.boundAmendForm = this.amendForm.bind(this);
    this.boundOnSuccess = this.onSuccess.bind(this);

    this.formTarget.addEventListener(
      "turbo:before-fetch-request",
      this.boundAmendForm,
    );

    this.formTarget.addEventListener("turbo:submit-end", this.boundOnSuccess);

    this.element.setAttribute("data-connected", true);
  }

  disconnect() {
    this.formTarget.removeEventListener(
      "turbo:before-fetch-request",
      this.boundAmendForm,
    );

    this.formTarget.removeEventListener(
      "turbo:submit-end",
      this.boundOnSuccess,
    );
  }

  amendForm(event) {
    const formData = new FormData(this.formTarget);
    event.detail.fetchOptions.body = JSON.stringify(this.#toJson(formData));
    event.detail.fetchOptions.headers["Content-Type"] = "application/json";

    event.detail.resume();
  }

  onSuccess(event) {
    if (event.detail.success && this.clearSelectionValue) {
      this.selectionOutlet.clear();
    }
  }

  #toJson(formData) {
    let params = formDataToJsonParams(formData);

    if (this.hasFieldNameValue && this.hasSelectionOutlet) {
      normalizeParams(
        params,
        this.fieldNameValue,
        this.selectionOutlet.getOrCreateStoredItems(),
        0,
      );
    }

    return params;
  }
}
