import { Controller } from "@hotwired/stimulus";

/**
 * LanguageSelectionDropdownController
 *
 * Handles a Flowbite dropdown for language selection.
 *
 * Stimulus Targets:
 * - trigger: The element that toggles the dropdown
 * - menu: The dropdown menu element
 *
 * Usage:
 * <div data-controller="language-selection-dd">
 *   <button data-language-selection-dd-target="trigger">Open</button>
 *   <div data-language-selection-dd-target="menu">...</div>
 * </div>
 */
export default class extends Controller {
  static targets = ["trigger", "menu"];

  /** @type {Dropdown} Flowbite dropdown instance */
  #dropdown;

  /**
   * Connects the controller and initializes the dropdown.
   */
  connect() {
    this.#dropdown = new Dropdown(this.menuTarget, this.triggerTarget);
    this.element.setAttribute("data-controller-connected", "true");
  }

  /**
   * Disconnects the controller.
   */
  disconnect() {
    if (this.#dropdown) {
      this.#dropdown.hide();
      this.#dropdown = null;
    }
  }
}
