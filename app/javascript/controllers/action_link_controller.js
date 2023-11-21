import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { required: { type: Number, default: 0 } };

  // # indicates private attribute or method
  // see https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Classes/Private_properties
  #event_classes = ["pointer-events-none", "cursor-not-allowed"];

  #default_colours = ["bg-slate-100", "text-slate-600"];

  #primary_colours = ["bg-primary-200", "text-slate-400", "border-primary-200"];

  setDisabled(count = 0) {
    if (this.requiredValue > count) {
      this.element.classList.add(...this.#event_classes);
      if (this.element.classList.contains("button--state-primary")) {
        this.element.classList.add(...this.#primary_colours);
      } else {
        this.element.classList.add(...this.#default_colours);
      }
    } else {
      this.element.classList.remove(...this.#event_classes);
      if (this.element.classList.contains("button--state-primary")) {
        this.element.classList.remove(...this.#primary_colours);
      } else {
        this.element.classList.remove(...this.#default_colours);
      }
    }
  }
}
