import { Controller } from "@hotwired/stimulus";

/**
 * Controller for handling inline editing functionality
 * @extends Controller
 */
export default class extends Controller {
  static targets = ["input", "newValue"];
  static values = {
    original: String,
  };

  /** @type {AbortController|null} */
  #abortController = null;

  connect() {
    try {
      this.inputTarget.focus();
    } catch (error) {
      console.error("Failed to focus/select input:", error);
    }
  }

  disconnect() {
    this.#cleanup();
  }

  /**
   * Submits the form
   * @private
   */
  submit() {
    try {
      this.element.requestSubmit();
    } catch (error) {
      console.error("Form submission failed:", error);
      // Fallback to reset if submission fails
      this.reset();
    }
  }

  /**
   * Resets the input to its original value
   * @private
   */
  reset() {
    this.inputTarget.value = this.originalValue;
    this.submit();
  }

  /**
   * Handles keyboard input events
   * @param {KeyboardEvent} event
   */
  inputKeydown(event) {
    if (!event?.key) return;

    switch (event.key) {
      case "Escape":
        this.reset();
        break;
      case "Tab":
        event.preventDefault();
        this.submit();
        break;
    }
  }

  /**
   * Handles blur events and shows confirmation dialog if value changed
   * @param {FocusEvent} event
   */
  async handleBlurEvent(event) {
    if (!this.#hasValueChanged()) {
      this.submit();
      return;
    }

    event.preventDefault();

    const dialog = this.element.querySelector("dialog");
    if (!dialog) {
      console.error("Dialog element not found");
      return;
    }

    this.#cleanup();
    this.#abortController = new AbortController();
    const signal = this.#abortController.signal;

    this.#updateNewValueTarget();

    try {
      await this.#showDialog(dialog, signal);
    } catch (error) {
      if (error.name === "AbortError") return;
      console.error("Dialog operation failed:", error);
      this.reset();
    }
  }

  /**
   * Updates the new value target
   * @private
   */
  #updateNewValueTarget() {
    if (this.hasNewValueTarget) {
      this.newValueTarget.textContent = this.inputTarget.value;
    }
  }

  /**
   * Shows the confirmation dialog and sets up event handlers
   * @private
   * @param {HTMLDialogElement} dialog
   * @param {AbortSignal} signal
   * @returns {Promise<void>}
   */
  async #showDialog(dialog, signal) {
    dialog.showModal();

    // Focus management for accessibility
    const cancelButton = dialog.querySelector('button[value="cancel"]');
    if (cancelButton) {
      requestAnimationFrame(() => cancelButton.focus());
    }

    const handleClick = (event) => {
      const button = event.target;
      if (button.value === "confirm") {
        this.submit();
      } else {
        this.reset();
      }
      dialog.close();
    };

    const handleKeydown = (event) => {
      if (event.key === "Escape") {
        dialog.close();
        this.inputTarget.focus();
      }
    };

    const handleClose = () => {
      this.#cleanup();
    };

    // Add event listeners with abort signal
    dialog.querySelectorAll("button").forEach((button) => {
      button.addEventListener("click", handleClick, { signal });
    });

    dialog.addEventListener("keydown", handleKeydown, { signal });
    dialog.addEventListener("close", handleClose, { signal });
  }

  /**
   * Checks if the input value has changed
   * @private
   * @returns {boolean}
   */
  #hasValueChanged() {
    return this.inputTarget.value !== this.originalValue;
  }

  /**
   * Cleans up event listeners
   * @private
   */
  #cleanup() {
    if (this.#abortController) {
      this.#abortController.abort();
      this.#abortController = null;
    }
  }
}
