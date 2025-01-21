import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "table",
    "processing",
    "submit",
    "error",
    "errorMessage",
    "form",
    "workflowAttributes",
  ];
  static values = {
    attachmentsError: { type: String },
    submissionError: { type: String },
  };

  #error_state = ["border-red-300", "dark:border-red-800"];

  #default_state = ["border-transparent"];

  // The samplesheet will use FormData, allowing us to create the inputs of a form without the associated DOM elements.
  // This will help alleviate render time issues encountered with workflows with large sample counts
  #formData = new FormData();

  connect() {
    this.#setInitialSamplesheetData();
  }

  #setInitialSamplesheetData() {
    const samples_workflow_attrs = JSON.parse(
      this.workflowAttributesTarget.innerText,
    );
    for (const index in samples_workflow_attrs) {
      for (const sample_attrs in samples_workflow_attrs[index]) {
        if (sample_attrs == "sample_id") {
          // specifically adds sample to form
          this.#setFormData(
            `workflow_execution[samples_workflow_executions_attributes][${index}][${sample_attrs}]`,
            samples_workflow_attrs[index][sample_attrs],
          );
          continue;
        }
        for (const property in samples_workflow_attrs[index][sample_attrs]) {
          // adds all remaining sample data to form (files, metadata, etc.)
          this.#setFormData(
            `workflow_execution[samples_workflow_executions_attributes][${index}][${sample_attrs}][${property}]`,
            samples_workflow_attrs[index][sample_attrs][property],
          );
        }
      }
    }
  }

  // handles changes to text and dropdown cells
  updateEditableSamplesheetData(event) {
    this.#setFormData(event.target.name, event.target.value);
  }

  // handles changes to metadata autofill and file cells
  updateAutofilledSamplesheetData({ detail: { content } }) {
    this.#setFormData(content.inputName, content.inputValue);
  }

  submitSamplesheet(event) {
    event.preventDefault();
    this.#enableProcessingState();

    // only file cells require an additional validation step. The rest of the cells are either autofilled or validation
    // of other required fields will be handled by the browser
    let readyToSubmit = this.#validateFileCells();

    if (!readyToSubmit) {
      this.#enableErrorState(this.attachmentsErrorValue);
      this.#disableProcessingState();
    } else {
      this.#combineFormData();
      fetch("/-/workflow_executions", {
        method: "POST",
        body: new URLSearchParams(this.#formData),
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }).then((response) => {
        this.#disableProcessingState();
        if (response.redirected && response.statusText == "OK") {
          window.location.href = response.url;
        } else {
          this.#enableErrorState(this.submissionErrorValue);
        }
      });
    }
  }

  #setFormData(inputName, inputValue) {
    this.#formData.set(inputName, inputValue);
  }

  #validateFileCells() {
    let readyToSubmit = true;
    const missingRequiredFileCells = document.querySelectorAll(
      "[data-file-missing='true']",
    );
    missingRequiredFileCells.forEach((fileCell) => {
      fileCell.classList.remove(...this.#default_state);
      fileCell.classList.add(...this.#error_state);
      readyToSubmit = false;
    });

    // revalidates file cells incase they need to be changed from error to default state
    if (!readyToSubmit) {
      const filledRequiredFileCells = document.querySelectorAll(
        "[data-file-missing='false']",
      );
      filledRequiredFileCells.forEach((fileCell) => {
        fileCell.classList.add(...this.#default_state);
        fileCell.classList.remove(...this.#error_state);
      });
    }
    return readyToSubmit;
  }

  // combines parameter form data with samplesheet form data
  #combineFormData() {
    const parameterData = new FormData(this.formTarget);
    for (const parameter of parameterData.entries()) {
      this.#setFormData(parameter[0], parameter[1]);
    }
  }
  #enableProcessingState() {
    this.submitTarget.disabled = true;
    if (this.hasTableTarget) {
      this.tableTarget.appendChild(
        this.processingTarget.content.cloneNode(true),
      );
    }
  }

  #disableProcessingState() {
    this.submitTarget.disabled = false;
    if (this.hasTableTarget) {
      this.tableTarget.removeChild(this.tableTarget.lastElementChild);
    }
  }

  #enableErrorState(message) {
    this.errorTarget.classList.remove("hidden");
    this.errorMessageTarget.innerHTML = message;
  }
}
