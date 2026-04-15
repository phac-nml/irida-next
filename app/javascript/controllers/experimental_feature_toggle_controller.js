import { Controller } from "@hotwired/stimulus";

/**
 * Experimental Feature Toggle Controller
 *
 * Submits the parent form when the toggle checkbox changes.
 * Turbo intercepts the form submission and handles the response.
 *
 * @example
 * <form data-controller="experimental-feature-toggle">
 *   <input type="checkbox" data-action="change->experimental-feature-toggle#submit">
 * </form>
 */
export default class extends Controller {
  submit() {
    this.element.requestSubmit();
  }
}
