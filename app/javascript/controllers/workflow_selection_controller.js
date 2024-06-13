import { Controller } from "@hotwired/stimulus";

function preventEscapeListener(event) {
  if (event.key === "Escape") {
    event.preventDefault();
    event.stopPropagation();
  }
}

// Connects to data-controller="workflow-selection"
export default class extends Controller {
  static targets = ["workflow", "workflowName", "workflowVersion", "form"];
  static outlets = ["selection"];

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
    document.addEventListener("keydown", preventEscapeListener, true);
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

        // Update the text inside ws_loading
        const wsLoading = workflow.querySelector(".ws-loading-text");
        wsLoading.textContent = wsLoading.textContent.replace(
          "COUNT_PLACEHOLDER",
          this.selectionOutlet.getNumSelected(),
        );
      }
    }

    this.formTarget.requestSubmit();
  }
}
