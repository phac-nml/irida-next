import { Controller } from "@hotwired/stimulus";

function preventEscapeListener(event) {
  if (event.key === "Escape") {
    event.preventDefault();
    event.stopPropagation();
  }
}

export default class extends Controller {
  static targets = ["submit"];

  submitStart() {
    document.addEventListener("keydown", preventEscapeListener, true);
    const closeButton = document.querySelector(".dialog--close");
    const spinner = document.querySelector("#spinner");

    if (closeButton) {
      closeButton.classList.add("hidden");
    }

    if (spinner) {
      spinner.classList.remove("hidden");
    }
  }

  submitEnd() {
    document.removeEventListener("keydown", preventEscapeListener, true);
    const closeButton = document.querySelector(".dialog--close");
    const spinner = document.querySelector("#spinner");

    if (closeButton) {
      closeButton.classList.remove("hidden");
    }

    if (spinner) {
      spinner.classList.add("hidden");
    }
  }
}
