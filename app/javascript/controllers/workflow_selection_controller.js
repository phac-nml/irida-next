import { Controller } from "@hotwired/stimulus";
import { formDataToJsonParams, normalizeParams } from "utilities/form";
import { handleFormResponse } from "../utilities/form";

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
  static values = {
    fieldName: String,
  };

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

    const formData = new FormData(this.formTarget);
    const jsonObject = this.#toJson(formData);

    Turbo.fetch(this.formTarget.action, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Accept: "text/vnd.turbo-stream.html, text/html, application/xhtml+xml",
      },
      credentials: "same-origin",
      body: JSON.stringify(jsonObject),
      redirect: "follow",
    }).then((response) => handleFormResponse(response));
  }

  #toJson(formData) {
    let params = formDataToJsonParams(formData);

    // add sample_ids under the fieldNameValue key to the params
    normalizeParams(
      params,
      this.fieldNameValue,
      this.selectionOutlet.getStoredItems(),
      0,
    );

    return params;
  }
}
