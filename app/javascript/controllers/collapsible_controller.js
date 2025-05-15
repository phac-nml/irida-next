import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["item", "icon"];

  toggle() {
    const isCollapsed = this.itemTarget.classList.contains("hidden");

    if (isCollapsed) {
      this.itemTarget.classList.remove("hidden");
      this.itemTarget.setAttribute("tabindex", "0");
      this.itemTarget.setAttribute("aria-hidden", "false");
      this.itemTarget.removeAttribute("hidden");
      this.#updateIcon(false);
    } else {
      this.itemTarget.classList.add("hidden");
      this.itemTarget.setAttribute("tabindex", "-1");
      this.itemTarget.setAttribute("aria-hidden", "true");
      this.itemTarget.setAttribute("hidden", "hidden");
      this.#updateIcon(true);
    }
  }

  #updateIcon(collapsed) {
    if (collapsed) {
      this.iconTarget.classList.remove("rotate-180");
      this.iconTarget.classList.add("rotate-0");
    } else {
      this.iconTarget.classList.remove("rotate-0");
      this.iconTarget.classList.add("rotate-180");
    }
  }
}
