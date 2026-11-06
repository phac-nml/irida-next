import { Controller } from "@hotwired/stimulus";

/**
 * Shows the full project URL as the path is edited.
 *
 * The preview is referenced by the input's aria-describedby rather than being
 * a live region, so screen readers read it on focus instead of on every key.
 */
export default class extends Controller {
  static targets = ["input", "path"];

  connect() {
    this.update();
    this.element.setAttribute("data-controller-connected", "true");
  }

  update() {
    this.pathTarget.textContent = this.inputTarget.value;
  }
}
