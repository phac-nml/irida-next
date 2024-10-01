import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "target"];
  connect() {
    new Tooltip(this.targetTarget, this.triggerTarget, {
      placement: "top",
      triggerType: "hover",
    });

    this.element.setAttribute("data-controller-connected", "true");
  }
}
