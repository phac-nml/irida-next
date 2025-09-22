import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "target"];

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  targetTargetConnected () {
    new Tooltip(this.targetTarget, this.triggerTarget, {
      placement: "top",
      triggerType: ["hover", "focus"],
    });
  }

  targetTargetDisconnected () {
    this.targetTarget.destroy();
  }
}
