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
    this.workflowNameTarget.value = params.workflowname;
    this.workflowVersionTarget.value = params.workflowversion;

    let spinner = document.getElementById("pipeline-spinner");

    spinner.classList.remove("hidden");
    // Update the text inside spinner dialog
    spinner.innerHTML = spinner.innerHTML
      .replace("COUNT_PLACEHOLDER", this.selectionOutlet.getNumSelected())
      .replace("WORKFLOW_NAME_PLACEHOLDER", params.workflowname)
      .replace("WORKFLOW_VERSION_PLACEHOLDER", params.workflowversion);

    this.formTarget.requestSubmit();
  }
}
