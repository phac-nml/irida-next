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

  static targets = ["samplesheetParamsForm", "properties"];
  static outlets = ["selection"];

  // properties target connects before the connect() would fire, so removed connect() and added its logic here
  propertiesTargetConnected() {
    this.boundAmendForm = this.amendForm.bind(this);

    this.samplesheetParamsFormTarget.addEventListener(
      "turbo:before-fetch-request",
      this.boundAmendForm,
    );
    this.#submitSamplesheetParams();
  }

  disconnect() {
    this.samplesheetParamsFormTarget.removeEventListener(
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
    return params;
  }

  #submitSamplesheetParams() {
    const fragment = document.createDocumentFragment();

    fragment.appendChild(
      createHiddenInput("properties", this.propertiesTarget.innerHTML),
    );

    this.samplesheetParamsFormTarget.appendChild(fragment);
    this.samplesheetParamsFormTarget.requestSubmit();
  }
}
