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
        this.element.setAttribute("data-dropdown-open", "true");
        this.triggerTarget.setAttribute("aria-expanded", "true");
      },
      onHide: () => {
        this.element.removeAttribute("data-dropdown-open");
        this.triggerTarget.setAttribute("aria-expanded", "false");
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
