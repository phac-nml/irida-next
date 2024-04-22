import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="workflow-selection"
export default class extends Controller {
  static targets = ["workflow", "workflowName", "workflowVersion", "form"];

  selectWorkflow({ params }) {
    for (const workflow of this.workflowTargets) {
      if (
        params.workflowname !==
          workflow.dataset.workflowSelectionWorkflownameParam ||
        params.workflowversion !==
          workflow.dataset.workflowSelectionWorkflowversionParam
      ) {
        workflow.classList.add("hidden");
      } else {
        workflow.querySelector(".ws-default").classList.add("hidden");
        workflow.querySelector(".ws-loading").classList.remove("hidden");

        this.workflowNameTarget.value = params.workflowname;
        this.workflowVersionTarget.value = params.workflowversion;
      }
    }

    this.formTarget.requestSubmit();
  }
}
