import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="workflow-selection"
export default class extends Controller {
  static targets = ["workflow", "workflowName", "workflowVersion", "form"];

  #escapeListener = null;

  disconnect() {
    document.removeEventListener("keydown", this.#escapeListener);
  }

  selectWorkflow({ params }) {
    document.querySelector(".dialog--close").classList.add("hidden");

    // Add  an event listener for escape key and capture it
    this.#escapeListener = document.addEventListener("keydown", (e) => {
      if (e.key === "Escape") {
        e.preventDefault();
        e.stopPropagation();
      }
    });

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
