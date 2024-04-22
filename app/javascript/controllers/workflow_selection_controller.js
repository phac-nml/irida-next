import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="workflow-selection"
function preventEscapeListener(event) {
  if (event.key === "Escape") {
    event.preventDefault();
    event.stopPropagation();
  }
}

export default class extends Controller {
  static targets = ["workflow", "workflowName", "workflowVersion", "form"];

  #escapeListener = null;

  connect() {
    document.addEventListener("turbo:submit-end", preventEscapeListener);
  }

  disconnect() {
    this.removeEscapeListener();
  }

  removeEscapeListener() {
    document.removeEventListener("keydown", preventEscapeListener, true);
  }

  preventClosingDialog() {
    document.querySelector(".dialog--close").classList.add("hidden");
    this.#escapeListener = document.addEventListener(
      "keydown",
      preventEscapeListener,
      true,
    );
  }

  selectWorkflow({ params }) {
    this.preventClosingDialog();

    for (const workflow of this.workflowTargets) {
      if (
        params.workflowname !==
          workflow.dataset.workflowSelectionWorkflownameParam ||
        params.workflowversion !==
          workflow.dataset.workflowSelectionWorkflowversionParam
      ) {
        workflow.classList.add("hidden");
      } else {
        workflow.disabled = true;
        workflow.querySelector(".ws-default").classList.add("hidden");
        workflow.querySelector(".ws-loading").classList.remove("hidden");

        this.workflowNameTarget.value = params.workflowname;
        this.workflowVersionTarget.value = params.workflowversion;
      }
    }

    this.formTarget.requestSubmit();
  }
}
