import { Controller } from "@hotwired/stimulus";
import { Dropdown } from "flowbite";

export default class extends Controller {
  static targets = ["trigger", "menu"];
  static values = {
    position: String,
    trigger: String,
    skidding: Number,
    distance: Number,
  };

  connect() {
    new Dropdown(this.menuTarget, this.triggerTarget, {
      triggerType: this.triggerValue,
      offsetSkidding: this.skiddingValue,
      offsetDistance: this.distanceValue,
    });

    this.element.setAttribute("data-controller-connected", "true");
  }
}
