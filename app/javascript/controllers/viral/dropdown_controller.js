import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "menu"];
  static values = {
    position: String,
    trigger: String,
    skidding: Number,
    distance: Number,
  };

  connect() {
    this.dropdown = new Dropdown(this.menuTarget, this.triggerTarget, {
      triggerType: this.triggerValue,
      offsetSkidding: this.skiddingValue,
      offsetDistance: this.distanceValue,
      onShow: () => {
        this.menuTarget.setAttribute("aria-expanded", "true");
        this.menuTarget.removeAttribute("aria-hidden");
      },
      onHide: () => {
        this.menuTarget.setAttribute("aria-expanded", "false");
        this.menuTarget.removeAttribute("aria-hidden");
      },
    });

    this.boundHandleTriggerFocusOut = this.handleTriggerFocusOut.bind(this);

    this.element.setAttribute("data-controller-connected", "true");

    this.menuTarget.addEventListener(
      "focusout",
      this.boundHandleTriggerFocusOut,
    );
  }

  disconnect() {
    this.menuTarget.removeEventListener(
      "focusout",
      this.boundHandleTriggerFocusOut,
    );
  }

  handleTriggerFocusOut(event) {
    if (!this.menuTarget.contains(event.relatedTarget)) {
      this.dropdown.hide();
    }
  }
}
