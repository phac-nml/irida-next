import { Controller } from "@hotwired/stimulus";
import Rails from "@rails/ujs";

export default class extends Controller {
  static targets = [
    "table",
    "loading",
    "submit",
    "error",
    "errorMessage",
    "form",
    "params",
  ];
  static values = {
    attachmentsError: { type: String },
    test: { type: String },
  };

  #formData = new FormData(this.formTarget);

  #error_state = ["border-red-300", "dark:border-red-800"];

  #default_state = ["border-transparent"];

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
    this.token = document.querySelector('meta[name="csrf-token"]').content;
    this.updateParams();
  }

  updateParams() {
    let params = JSON.parse(this.paramsTarget.innerText);
    // console.log(typeof params);
    // console.log(params);
    console.log("params");
    console.log(params);
    for (const property in params) {
      for (const nested_property in params[property]) {
        if (nested_property == "sample_id") {
          continue;
        }
        for (const third_property in params[property][nested_property]) {
          this.#formData.append(
            `workflow_execution[samples_workflow_executions_attributes][${property}][${nested_property}][${third_property}]`,
            params[property][nested_property][third_property],
          );
        }
      }
    }
    console.log(this.#formData);
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
      body: this.#formData,
      credentials: "same-origin",
      headers: {
        "X-CSRF-TOKEN": this.token,
      },
    }).then((response) => {
      if (response.redirected && response.statusText == "OK") {
        window.location.href = response.url;
      }
    });
  }
}
