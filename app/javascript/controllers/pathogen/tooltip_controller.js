import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "target"];

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  disconnect() {
    this.#tooltip.destroy();
    this.#tooltip = null;
  }


  targetTargetConnected () {
    this.#tooltip = new Tooltip(this.targetTarget, this.triggerTarget, {
      placement: "top",
      triggerType: ["hover", "focus"],
    });
  }
}
