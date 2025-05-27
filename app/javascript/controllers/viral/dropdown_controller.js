import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "menu"];
  static values = {
    position: String,
    trigger: String,
    skidding: Number,
    distance: Number,
  };

  initialize() {
    this.boundHandleTriggerFocusOut = this.handleTriggerFocusOut.bind(this);
  }

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  menuTargetConnected(element) {
    element.setAttribute("aria-hidden", "true");

    element.addEventListener("focusout", this.boundHandleTriggerFocusOut);
  }

  menuTargetDisconnected(element) {
    element.removeEventListener("focusout", this.boundHandleTriggerFocusOut);
  }

  triggerTargetConnected(element) {
    this.dropdown = new Dropdown(this.menuTarget, element, {
      triggerType: this.triggerValue,
      offsetSkidding: this.skiddingValue,
      offsetDistance: this.distanceValue,
      onShow: () => {
        this.triggerTarget.setAttribute("aria-expanded", "true");
        this.menuTarget.setAttribute("aria-hidden", "false");
        this.menuTarget.removeAttribute("hidden");
        this.menuTarget.setAttribute("tabindex", "0");
      },
      onHide: () => {
        this.triggerTarget.setAttribute("aria-expanded", "false");
        this.menuTarget.setAttribute("aria-hidden", "true");
        this.menuTarget.setAttribute("tabindex", "-1");
        this.menuTarget.setAttribute("hidden", "hidden");
      },
    });
  }

  handleTriggerFocusOut(event) {
    if (!this.menuTarget.contains(event.relatedTarget)) {
      this.dropdown.hide();
    }
  }
}
