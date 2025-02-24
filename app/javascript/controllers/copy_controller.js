/**
 * CopyController
 *
 * A Stimulus controller that handles copying text from a source element to the clipboard.
 * Provides visual feedback on success using a success icon and a hidden button label.
 *
 * Targets:
 * - source: the element containing the text to copy
 * - buttonLabel: the element that displays the button's label
 * - successIcon: the element that shows feedback after a successful copy action
 *
 * Usage in HTML:
 * <div data-controller="copy">
 *   <pre data-copy-target="source">Text to be copied</pre>
 *   <button data-action="click->copy#copy">
 *     <span data-copy-target="buttonLabel">Copy</span>
 *     <svg data-copy-target="successIcon" class="hidden">...icon SVG...</svg>
 *   </button>
 * </div>
 */
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "buttonLabel", "successIcon"];

  /**
   * Copy the text content of the source element to the clipboard.
   *
   * This method performs the following:
   * 1. Checks if the Clipboard API is supported.
   * 2. Ensures the source target exists.
   * 3. Retrieves and trims the text content from the source.
   * 4. Writes the content to the user's clipboard.
   * 5. Provides visual feedback upon success.
   *
   * Logs errors if the Clipboard API is missing, the source target is not found,
   * or the copy operation fails.
   */
  async copy() {
    if (!navigator.clipboard) {
      console.error("Clipboard API not available");
      return;
    }

    if (!this.hasSourceTarget) {
      console.error("Source target is missing");
      return;
    }

    const content = this.sourceTarget.textContent.trim();
    if (!content) {
      console.warn("No content available to copy");
      return;
    }

    try {
      await navigator.clipboard.writeText(content);
      this.showFeedback();
    } catch (err) {
      console.error("Failed to copy text:", err);
    }
  }

  /**
   * Show visual feedback after a successful copy.
   *
   * This method reveals a success icon and hides the button label.
   * After 2 seconds the success icon is hidden and the button label is restored.
   */
  showFeedback() {
    this.successIconTarget.classList.remove("hidden");
    this.buttonLabelTarget.classList.add("sr-only");
    setTimeout(() => {
      this.successIconTarget.classList.add("hidden");
      this.buttonLabelTarget.classList.remove("sr-only");
    }, 2000);
  }
}
