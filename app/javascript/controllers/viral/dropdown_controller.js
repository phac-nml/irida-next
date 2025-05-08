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
        this.triggerTarget.setAttribute("aria-expanded", "true");
        this.menuTarget.setAttribute("aria-hidden", "false");
        this.menuTarget.removeAttribute("hidden");
        this.menuTarget.setAttribute("tabindex", "0");
      },
      onHide: () => {
        this.triggerTarget.setAttribute("aria-expanded", "false");
        this.menuTarget.setAttribute("aria-hidden", "true");
        this.menuTarget.setAttribute("tabindex", "-1");
        this.menuTarget.setAttribute("hidden", "");
      },
    });

    this.boundHandleTriggerFocusOut = this.handleTriggerFocusOut.bind(this);

    this.element.setAttribute("data-controller-connected", "true");

    this.menuTarget.setAttribute("aria-hidden", "true");

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
