import { Controller } from "@hotwired/stimulus";

/**
 * MetadataTemplateDropdownController
 *
 * Handles a Flowbite dropdown for metadata template selection.
 * - Submits the form when the dropdown is shown (for live filtering or updating)
 * - Hides the dropdown when a successful Turbo form submission occurs elsewhere
 *
 * Stimulus Targets:
 * - trigger: The element that toggles the dropdown
 * - menu: The dropdown menu element
 * - form: The form to submit on dropdown show
 *
 * Usage:
 * <div data-controller="metadata-template-dd">
 *   <button data-metadata-template-dd-target="trigger">Open</button>
 *   <div data-metadata-template-dd-target="menu">
 *     <form data-metadata-template-dd-target="form">...</form>
 *   </div>
 * </div>
 */
export default class extends Controller {
  static targets = ["trigger", "menu", "form"];

  /** @type {Dropdown} Flowbite dropdown instance */
  #dropdown;
  /** @type {Function} Bound event handler for turbo:submit-end */
  #turboSubmitEndListener = this.#handleTurboSubmitEnd.bind(this);

  /**
   * Connects the controller, initializes the dropdown, and sets up event listeners.
   */
  connect() {
    this.#dropdown = new Dropdown(this.menuTarget, this.triggerTarget, {
      onShow: () => {
        // Auto-submit the form when dropdown is shown
        this.formTarget.requestSubmit();
      },
    });

    document.addEventListener("turbo:submit-end", this.#turboSubmitEndListener);
    this.element.setAttribute("data-controller-connected", "true");
  }

  /**
   * Disconnects the controller and cleans up event listeners.
   */
  disconnect() {
    document.removeEventListener(
      "turbo:submit-end",
      this.#turboSubmitEndListener,
    );
    if (this.#dropdown) {
      this.#dropdown.hide();
      this.#dropdown = null;
    }
  }

  /**
   * Handles Turbo form submission events.
   * Hides the dropdown if a successful submission occurs outside this form.
   *
   * @param {CustomEvent} event - The turbo:submit-end event
   * @private
   */
  #handleTurboSubmitEnd(event) {
    if (event.detail.success && event.target !== this.formTarget) {
      this.#dropdown?.hide();
    }
  }
}
