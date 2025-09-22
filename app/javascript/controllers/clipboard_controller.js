// A stimulus controller for copying text to the clipboard.
//
// Example:
//
// <div data-controller="clipboard">
//   <input type="text" data-clipboard-target="source">
//   <button data-action="clipboard#copy">Copy</button>
// </div>

import { Controller } from "@hotwired/stimulus";

/**
 * @class ClipboardController
 * @classdesc A stimulus controller for copying text to the clipboard.
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["button", "content"];

  #tooltip;

  contentTargetConnected() {
    if (this.hasButtonTarget && this.hasContentTarget) {
      this.#tooltip = new Tooltip(this.contentTarget, this.buttonTarget, {
        placement: "top",
        triggerType: "none",
      });
    }
  }

  contentTargetDisconnected() {
    if (this.#tooltip) {
      this.#tooltip.destroy();
      this.#tooltip = null;
    }
  }

  /**
   * Copies the text from the source to the clipboard.
   * @param {Event} e - The event object.
   * @returns {void}
   */
  async copy(e) {
    e.stopImmediatePropagation();

    if (!navigator.clipboard) {
      console.error("Clipboard API not available");
      return;
    }

    try {
      await navigator.clipboard.writeText(e.target.value);
      this.#notify();
    } catch (err) {
      console.error("Failed to copy text: ", err);
    }
  }

  /**
   * Notifies the user that the text has been copied.
   * @returns {void}
   * @private
   */
  #notify() {
    if (!this.#tooltip) return;

    this.#tooltip.show();
    this.buttonTarget.setAttribute("disabled", "");

    // Change the button to a checkmark for 1 second
    const originalContent = this.buttonTarget.innerHTML;
    this.buttonTarget.innerHTML = `
      <svg
        xmlns="http://www.w3.org/2000/svg"
        class="size-3"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M5 13l4 4L19 7"
        />
      </svg>
    `;

    setTimeout(() => {
      this.#tooltip.hide();
      this.buttonTarget.removeAttribute("disabled");
      this.buttonTarget.innerHTML = originalContent;
    }, 1000);
  }
}
