import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "target"];

  #tooltip;

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  disconnect() {
    if (this.#tooltip) {
      this.#tooltip.destroy();
      this.#tooltip = null;
    }
  }

  targetTargetConnected () {
    this.#tooltip = new Tooltip(this.targetTarget, this.triggerTarget, {
      placement: "top",
      triggerType: ["hover", "focus"],
    });
  }
}
