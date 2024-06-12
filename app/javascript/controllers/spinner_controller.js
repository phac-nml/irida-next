import { Controller } from "@hotwired/stimulus";

function preventEscapeListener(event) {
  if (event.key === "Escape") {
    event.preventDefault();
    event.stopPropagation();
  }
}

export default class extends Controller {
  static targets = ['submit'];

  submitStart() {
    document.addEventListener("keydown", preventEscapeListener, true);
    document.querySelector(".dialog--header").classList.add("opacity-20");
    document.querySelector(".dialog--section > *:not(:last-child)").classList.add("opacity-20");
    document.querySelector(".dialog--close").classList.add("hidden");
    document.querySelector("#spinner").classList.remove("hidden");
  }

  submitEnd() {
    document.removeEventListener("keydown", preventEscapeListener, true);
    document.querySelector(".dialog--header").classList.remove("opacity-20");
    document.querySelector(".dialog--section > *:not(:last-child)").classList.remove("opacity-20");
    document.querySelector(".dialog--close").classList.remove("hidden");
    document.querySelector("#spinner").classList.add("hidden");
  }
}
