import { Controller } from "@hotwired/stimulus";

const focusRestoreKeys = new Set();

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
  static values = { featureKey: String };

  connect() {
    this.updatePill();
    this.restoreFocus();
  }

  toggle() {
    if (this.hasFeatureKeyValue) {
      focusRestoreKeys.add(this.featureKeyValue);
    }

    this.updatePill();
    this.element.requestSubmit();
  }

  restoreFocus() {
    if (!this.hasCheckboxTarget || !this.hasFeatureKeyValue) return;
    if (!focusRestoreKeys.has(this.featureKeyValue)) return;

    this.checkboxTarget.focus();
    focusRestoreKeys.delete(this.featureKeyValue);
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
