import { Controller } from "@hotwired/stimulus";
import { Dropdown } from "flowbite";

export default class extends Controller {
  static targets = ["button", "menu"];

  connect() {
    const dropdown = new Dropdown(this.menuTarget, this.buttonTarget);
  }
}
