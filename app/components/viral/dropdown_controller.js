import { Controller } from "@hotwired/stimulus";
import { Dropdown } from "flowbite";

export default class extends Controller {
  static targets = ["trigger", "menu"];

  connect() {
    new Dropdown(this.menuTarget, this.triggerTarget);
  }
}
