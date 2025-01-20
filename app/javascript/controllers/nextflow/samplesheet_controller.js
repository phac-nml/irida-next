import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "table",
    "loading",
    "submit",
    "error",
    "errorMessage",
    "form",
    "workflowAttributes",
  ];
  static values = {
    attachmentsError: { type: String },
  };

  #error_state = ["border-red-300", "dark:border-red-800"];

  #default_state = ["border-transparent"];

  // The samplesheet will use FormData, allowing us to create the inputs of a form without the associated DOM elements.
  // This will help alleviate render time issues encountered with workflows with large sample counts
  #formData = new FormData(this.formTarget);

  connect() {
    this.element.addEventListener("turbo:submit-start", (event) => {
      this.submitTarget.disabled = true;
      if (this.hasTableTarget) {
        this.tableTarget.appendChild(
          this.loadingTarget.content.cloneNode(true),
        );
      }
    });

    this.element.addEventListener("turbo:submit-end", (event) => {
      this.submitTarget.disabled = false;
      if (this.hasTableTarget) {
        this.tableTarget.removeChild(this.tableTarget.lastElementChild);
      }
    });
    this.#setInitialFormData();
  }

  #setInitialFormData() {
    // attributes abbreviated to attrs
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

  updateEditableFormData(event) {
    this.#setFormData(event.target.name, event.target.value);
  }

  updateAutofilledFormData({ detail: { content } }) {
    this.#setFormData(content.inputName, content.inputValue);
  }

  #setFormData(inputName, inputValue) {
    this.#formData.set(inputName, inputValue);
  }

  validateForm(event) {
    event.preventDefault();
    let readyToSubmit = true;
    // const requiredFileCells = document.querySelectorAll(
    //   "[data-file-cell-required='true']",
    // );
    // requiredFileCells.forEach((fileCell) => {
    //   const firstChild = fileCell.firstElementChild;
    //   if (
    //     !firstChild ||
    //     firstChild.type != "hidden" ||
    //     !firstChild.value ||
    //     !firstChild.value.startsWith("gid://")
    //   ) {
    //     fileCell.classList.remove(...this.#default_state);
    //     fileCell.classList.add(...this.#error_state);
    //     readyToSubmit = false;
    //   } else {
    //     fileCell.classList.remove(...this.#error_state);
    //     fileCell.classList.add(...this.#default_state);
    //   }
    // });

    // if (!readyToSubmit) {
    //   this.errorTarget.classList.remove("hidden");
    //   this.errorMessageTarget.innerHTML = this.attachmentsErrorValue;
    // } else {
    //   this.formTarget.requestSubmit();
    // }
    fetch("/-/workflow_executions", {
      method: "POST",
      body: new URLSearchParams(this.#formData),
      credentials: "same-origin",
      headers: {
        "X-CSRF-TOKEN": document.querySelector('meta[name="csrf-token"]')
          .content,
        "Content-Type": "application/x-www-form-urlencoded",
      },
    }).then((response) => {
      if (response.redirected && response.statusText == "OK") {
        window.location.href = response.url;
      }
    });
  }
}
