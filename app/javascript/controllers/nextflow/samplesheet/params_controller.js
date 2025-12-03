import { Controller } from "@hotwired/stimulus";
import {
  createHiddenInput,
  formDataToJsonParams,
  normalizeParams,
} from "utilities/form";

// Handles submitting the samplesheet params to render the samplesheet once the nextflow dialog opens
export default class extends Controller {
  static values = {
    fields: { type: Array },
  };

  static targets = ["samplesheetParamsForm"];
  static outlets = ["selection"];

  connect() {
    this.boundAmendForm = this.amendForm.bind(this);

    this.samplesheetParamsFormTarget.addEventListener(
      "turbo:before-fetch-request",
      this.boundAmendForm,
    );
  }

  amendForm(event) {
    const formData = new FormData(this.samplesheetParamsFormTarget);
    event.detail.fetchOptions.body = JSON.stringify(this.#toJson(formData));
    event.detail.fetchOptions.headers["Content-Type"] = "application/json";

    event.detail.resume();
  }

  #toJson(formData) {
    let params = formDataToJsonParams(formData);

    if (this.hasSelectionOutlet) {
      normalizeParams(
        params,
        "sample_ids[]",
        this.selectionOutlet.getOrCreateStoredItems(),
        0,
      );
    }
    if (this.fieldsValue) {
      normalizeParams(params, "fields[]", this.fieldsValue, 0);
    }
    return params;
  }

  // triggered when nextflow/samplesheet/params/schema_controller connects
  submitSamplesheetParams(schema) {
    const fragment = document.createDocumentFragment();

    fragment.appendChild(createHiddenInput("schema", JSON.stringify(schema)));

    this.samplesheetParamsFormTarget.appendChild(fragment);
    this.samplesheetParamsFormTarget.requestSubmit();
  }
}
