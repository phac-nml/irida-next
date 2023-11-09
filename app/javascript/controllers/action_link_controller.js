import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  #classes = [
    "pointer-events-none",
    "cursor-not-allowed",
    "bg-slate-200",
    "text-slate-400",
  ];

  setDisabled(disabled = true) {
    if (disabled) {
      this.element.classList.add(...this.#classes);
    } else {
      this.element.classList.remove(...this.#classes);
    }
  }
}
