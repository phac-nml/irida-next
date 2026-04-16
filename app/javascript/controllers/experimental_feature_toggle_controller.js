import { Controller } from "@hotwired/stimulus";

/**
 * Experimental Feature Toggle Controller
 *
 * Submits the parent form when the toggle checkbox changes and keeps the
 * visual pill in sync with the checkbox state.
 *
 * @example
 * <form data-controller="experimental-feature-toggle">
 *   <input type="checkbox" data-experimental-feature-toggle-target="checkbox"
 *          data-action="change->experimental-feature-toggle#toggle">
 *   <span data-experimental-feature-toggle-target="pill"></span>
 * </form>
 */
export default class extends Controller {
  static targets = ["checkbox", "pill"];

  connect() {
    this.updatePill();
  }

  toggle() {
    this.updatePill();
    this.element.requestSubmit();
  }

  updatePill() {
    if (!this.hasPillTarget || !this.hasCheckboxTarget) return;
    const on = this.checkboxTarget.checked;
    this.pillTarget.classList.toggle("bg-primary-600", on);
    this.pillTarget.classList.toggle("dark:bg-primary-500", on);
    this.pillTarget.classList.toggle("bg-slate-200", !on);
    this.pillTarget.classList.toggle("dark:bg-slate-700", !on);
    this.pillTarget.classList.toggle("after:translate-x-5", on);
  }
}
