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
    featureFlag: { type: Boolean },
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

    if (this.featureFlagValue) {
      this.#sampleCount = this.selectionOutlet.getStoredItemsCount();
    }
    console.log(this.#sampleCount);
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

    if (!this.featureFlagValue) {
      const spinner = document.getElementById("pipeline-spinner");

      spinner.classList.remove("hidden");
      // Update the text inside spinner dialog
      spinner.innerHTML = spinner.innerHTML
        .replace(
          "COUNT_PLACEHOLDER",
          this.selectionOutlet.getOrCreateStoredItems().length,
        )
        .replace("WORKFLOW_NAME_PLACEHOLDER", params.workflowname)
        .replace("WORKFLOW_VERSION_PLACEHOLDER", params.workflowversion);

      const submitStart = Date.now();

      // for accessibility, show the spinner for a minimum of 3500ms
      const A11Y_TIMEOUT = 3500;
      document.addEventListener(
        "turbo:before-stream-render",
        (event) => {
          const ms = Date.now() - submitStart;

          // delay render for up to 3500ms
          if (ms < A11Y_TIMEOUT) {
            const defaultRender = event.detail.render;

            event.detail.render = function (streamElement) {
              setTimeout(() => {
                defaultRender(streamElement);
              }, A11Y_TIMEOUT - ms);
            };
          }
        },
        { once: true },
      );
    }
    this.formTarget.requestSubmit();
  }

  #toJson(formData) {
    const params = formDataToJsonParams(formData);

    // add sample_ids under the fieldNameValue key to the params
    if (this.featureFlagValue) {
      normalizeParams(params, this.fieldNameValue, this.#sampleCount, 0);
    } else {
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
