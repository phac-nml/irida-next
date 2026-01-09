import { Controller } from "@hotwired/stimulus";
import { formDataToJsonParams, normalizeParams } from "utilities/form";

function preventEscapeListener(event) {
  if (event.key === "Escape") {
    event.preventDefault();
    event.stopPropagation();
  }
}

// Connects to data-controller="workflow-selection"
export default class extends Controller {
  static targets = ["workflow", "pipelineId", "workflowVersion", "form"];
  static outlets = ["selection"];
  static values = {
    fieldName: String,
  };

  #sampleCount;

  connect() {
    this.boundAmendForm = this.amendForm.bind(this);
    this.boundOnSuccess = this.onSuccess.bind(this);

    this.formTarget.addEventListener(
      "turbo:before-fetch-request",
      this.boundAmendForm,
    );

    this.formTarget.addEventListener("turbo:submit-end", this.boundOnSuccess);

    document.addEventListener("turbo:submit-end", preventEscapeListener);

    this.#sampleCount = this.selectionOutlet.getStoredItemsCount();
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

    this.removeEscapeListener();
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

  removeEscapeListener() {
    document.removeEventListener("keydown", preventEscapeListener, true);
  }

  preventClosingDialog() {
    document.querySelector(".dialog--close").classList.add("hidden");
    document.addEventListener("keydown", preventEscapeListener, true);
  }

  selectWorkflow({ params }) {
    this.preventClosingDialog();
    this.pipelineIdTarget.value = params.pipelineid;
    this.workflowVersionTarget.value = params.workflowversion;

    this.formTarget.requestSubmit();
  }

  #toJson(formData) {
    const params = formDataToJsonParams(formData);

    // add sample_ids under the fieldNameValue key to the params
    normalizeParams(params, this.fieldNameValue, this.#sampleCount, 0);

    return params;
  }
}
