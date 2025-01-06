import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["table", "loading", "submit", "attachmentsError", "form"];

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
  }

  validateAttachments(event) {
    event.preventDefault();
    let readyToSubmit = true;
    const requiredFileCells = document.querySelectorAll(
      "[data-file-cell-required='true']",
    );
    requiredFileCells.forEach((fileCell) => {
      const firstChild = fileCell.firstElementChild;
      if (
        !firstChild ||
        firstChild.type != "hidden" ||
        !firstChild.value ||
        !firstChild.value.startsWith("gid://")
      ) {
        fileCell.classList.remove(...this.#default_state);
        fileCell.classList.add(...this.#error_state);
        readyToSubmit = false;
      } else {
        fileCell.classList.remove(...this.#error_state);
        fileCell.classList.add(...this.#default_state);
      }
    });

    if (!readyToSubmit) {
      this.attachmentsErrorTarget.classList.remove("hidden");
    } else {
      this.formTarget.requestSubmit();
    }
  }
}
