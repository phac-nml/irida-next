import { Controller } from "@hotwired/stimulus";
import { Dropdown } from "flowbite";

export default class extends Controller {
  static targets = ["trigger", "menu"];
  static values = { position: String, trigger: String };

  connect() {
    new Dropdown(this.menuTarget, this.triggerTarget, {
      triggerType: this.triggerValue,
    });
  }
}
