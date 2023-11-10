import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { required: { type: Number, default: 0 } };

  // # indicated private attribute or method
  // see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/Private_properties
  #classes = [
    "pointer-events-none",
    "cursor-not-allowed",
    "bg-slate-200",
    "text-slate-400",
  ];

  setDisabled(count = 0) {
    if (this.requiredValue > count) {
      this.element.classList.add(...this.#classes);
    } else {
      this.element.classList.remove(...this.#classes);
    }
  }
}
