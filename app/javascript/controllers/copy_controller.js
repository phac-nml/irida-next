/**
 * 📋 Copy Controller 📋
 *
 * A Stimulus controller that handles copying text from a source element to the clipboard.
 * Provides visual feedback on success using a success icon and a hidden button label.
 *
 * ✨ Targets:
 * - source: The element containing the text to copy
 * - buttonLabel: The element that displays the button's label
 * - successIcon: The element that shows feedback after a successful copy action
 *
 * 🔄 Values:
 * - feedbackDuration: Duration in ms to show success feedback (defaults to 2000ms)
 *
 * 🎯 Actions:
 * - copy: Copies the source text to clipboard
 *
 * 📝 Example Usage:
 * ```html
 * <div data-controller="copy" data-copy-feedback-duration-value="3000">
 *   <pre data-copy-target="source">Text to be copied</pre>
 *   <button data-action="copy#copy">
 *     <span data-copy-target="buttonLabel">Copy</span>
 *     <svg data-copy-target="successIcon" class="hidden">...icon SVG...</svg>
 *   </button>
 * </div>
 * ```
 */
import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "buttonLabel", "successIcon"];
  static values = {
    feedbackDuration: { type: Number, default: 2000 }
  };

  /**
   * 📋 Copy the text content of the source element to the clipboard.
   *
   * This method performs the following:
   * 1. Checks if the Clipboard API is supported
   * 2. Ensures the source target exists
   * 3. Retrieves and trims the text content from the source
   * 4. Writes the content to the user's clipboard
   * 5. Provides visual feedback upon success
   *
   * @returns {Promise<void>}
   */
  async copy() {
    // Early return if Clipboard API is not available
    if (!navigator.clipboard) {
      console.error("❌ Clipboard API not available");
      return;
    }

    // Validate that we have a source target
    if (!this.hasSourceTarget) {
      console.error("❌ Source target is missing");
      return;
    }

    // Get and validate content
    const content = this.sourceTarget.textContent.trim();
    if (!content) {
      console.warn("⚠️ No content available to copy");
      return;
    }

    try {
      await navigator.clipboard.writeText(content);
      this.showFeedback();
    } catch (err) {
      console.error("❌ Failed to copy text:", err);
    }
  }

  /**
   * ✅ Show visual feedback after a successful copy.
   *
   * This method:
   * 1. Reveals the success icon
   * 2. Hides the button label
   * 3. Restores the original state after the configured duration
   *
   * @private
   */
  showFeedback() {
    // Show success state
    this.successIconTarget.classList.remove("hidden");
    this.buttonLabelTarget.classList.add("sr-only");

    // Reset after duration
    setTimeout(() => {
      this.successIconTarget.classList.add("hidden");
      this.buttonLabelTarget.classList.remove("sr-only");
    }, this.feedbackDurationValue);
  }

  /**
   * 🔄 Connect lifecycle callback
   *
   * Validates that all required targets are present when the controller connects.
   */
  connect() {
    // Log connection for debugging in development
    if (typeof window !== 'undefined' && window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
      console.debug("📋 Copy controller connected");
    }

    // Validate targets
    if (!this.hasSourceTarget) {
      console.warn("⚠️ Copy controller missing source target");
    }

    if (!this.hasButtonLabelTarget) {
      console.warn("⚠️ Copy controller missing buttonLabel target");
    }

    if (!this.hasSuccessIconTarget) {
      console.warn("⚠️ Copy controller missing successIcon target");
    }
  }
}
