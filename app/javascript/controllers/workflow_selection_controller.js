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
    unavailableLabel: String,
    sampleCount: Number,
  };

  connect() {
    console.log(this.sampleCountValue);
    this.boundAmendForm = this.amendForm.bind(this);
    this.boundOnSuccess = this.onSuccess.bind(this);

    this.formTarget.addEventListener(
      "turbo:before-fetch-request",
      this.boundAmendForm,
    );

    this.formTarget.addEventListener("turbo:submit-end", this.boundOnSuccess);

    document.addEventListener("turbo:submit-end", preventEscapeListener);

    this.updateWorkflowAvailability();
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

  selectWorkflow(event) {
    if (event.currentTarget.getAttribute("aria-disabled") === "true") {
      return;
    }

    const { params } = event;
    this.preventClosingDialog();
    this.pipelineIdTarget.value = params.pipelineid;
    this.workflowVersionTarget.value = params.workflowversion;

    this.formTarget.requestSubmit();
  }

  updateWorkflowAvailability() {
    const workflowsByState = [];

    this.workflowTargets.forEach((workflow) => {
      const disabledMessage = this.disabledMessage(workflow);
      const isDisabled = disabledMessage.length > 0;
      const limitMessage = workflow.querySelector(
        "[data-workflow-selection-limit-message]",
      );

      this.setDisabledState(workflow, isDisabled);

      if (limitMessage) {
        limitMessage.classList.toggle("hidden", !isDisabled);
        limitMessage.textContent = disabledMessage;
      }

      workflowsByState.push({ workflow, isDisabled });
    });

    this.reorderWorkflows(workflowsByState);
  }

  disabledMessage(workflow) {
    const minSamplesConfigured =
      workflow.dataset.workflowSelectionMinSamplesConfigured === "true";
    const maxSamplesConfigured =
      workflow.dataset.workflowSelectionMaxSamplesConfigured === "true";
    const minimumSamples = Number.parseInt(
      workflow.dataset.workflowSelectionMinSamples ?? "0",
      10,
    );
    const maximumSamples = Number.parseInt(
      workflow.dataset.workflowSelectionMaxSamples ?? "-1",
      10,
    );

    if (minSamplesConfigured && this.sampleCountValue < minimumSamples) {
      return workflow.dataset.workflowSelectionMinSamplesMessage;
    }

    if (
      maxSamplesConfigured &&
      maximumSamples > 0 &&
      this.sampleCountValue > maximumSamples
    ) {
      return workflow.dataset.workflowSelectionMaxSamplesMessage;
    }

    return "";
  }

  setDisabledState(workflow, disabled) {
    workflow.setAttribute("aria-disabled", disabled.toString());
  }

  reorderWorkflows(workflowsByState) {
    if (workflowsByState.length === 0) {
      return;
    }

    const list = workflowsByState[0].workflow.closest("ul");
    if (!list) {
      return;
    }

    const enabledRows = [];
    const disabledRows = [];

    workflowsByState.forEach(({ workflow, isDisabled }) => {
      const row = workflow.closest("li");
      if (!row) {
        return;
      }

      if (isDisabled) {
        disabledRows.push(row);
      } else {
        enabledRows.push(row);
      }
    });

    list
      .querySelectorAll("[data-workflow-selection-divider]")
      .forEach((divider) => divider.remove());

    enabledRows.forEach((row) => list.appendChild(row));

    if (disabledRows.length > 0) {
      list.appendChild(this.createUnavailableDivider());
      disabledRows.forEach((row) => list.appendChild(row));
    }
  }

  createUnavailableDivider() {
    const divider = document.createElement("li");
    divider.dataset.workflowSelectionDivider = "true";
    divider.className = "pt-2";

    const container = document.createElement("div");
    container.className =
      "flex items-center gap-2 text-xs font-semibold uppercase tracking-wide text-slate-500 dark:text-slate-400";

    const leadingRule = document.createElement("span");
    leadingRule.className = "h-px flex-1 bg-slate-200 dark:bg-slate-700";

    const label = document.createElement("span");
    label.textContent = this.unavailableLabelValue;

    const trailingRule = document.createElement("span");
    trailingRule.className = "h-px flex-1 bg-slate-200 dark:bg-slate-700";

    container.append(leadingRule, label, trailingRule);
    divider.appendChild(container);

    return divider;
  }

  #toJson(formData) {
    const params = formDataToJsonParams(formData);

    // add sample_ids under the fieldNameValue key to the params
    normalizeParams(params, this.fieldNameValue, this.sampleCountValue, 0);

    return params;
  }
}
