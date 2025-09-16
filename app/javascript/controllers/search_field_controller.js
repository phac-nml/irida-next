import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static outlets = ["selection"];
  static targets = ["input", "clearButton", "submitButton"];

  /**
   * 🎯 Initialize controller
   *
   * Sets up any initial state or event listeners
   */
  connect() {
    console.debug("🔗 SearchFieldController: Connected", {
      hasInputTarget: this.hasInputTarget,
      hasSearchContent: this.hasSearchContent,
    });
  }

  /**
   * 🚪 Cleanup when controller disconnects
   */
  disconnect() {
    console.debug("🔌 SearchFieldController: Disconnected");
  }

  /**
   * 🧹 Clear search field and refresh results
   *
   * This method clears the search input and triggers a form submission
   * to refresh the search results. It includes comprehensive error handling
   * and user feedback.
   */
  clear() {
    try {
      // 🎯 Validate input target exists
      if (!this.hasInputTarget) {
        console.warn("🔍 SearchFieldController: Input target not found");
        return;
      }

      // 🧹 Clear the input field
      this.inputTarget.value = "";

      // 🎨 Add visual feedback (optional)
      this.updateFocus();

      // 🔄 Find the parent form
      const form = this.element.closest("form");
      if (!form) {
        console.error("❌ SearchFieldController: Parent form not found");
        return;
      }

      // ♻️ Toggle buttons: hide clear, show submit
      this.showSubmitHideClear();

      this.clearSelection();

      // 🚀 Trigger form submission to refresh results (so user sees cleared state)
      form.requestSubmit();

      // ✅ Log success for debugging
      console.debug("✅ SearchFieldController: Search cleared successfully");
    } catch (error) {
      // 🚨 Comprehensive error handling
      console.error("💥 SearchFieldController: Error clearing search", {
        error: error.message,
        stack: error.stack,
        element: this.element,
        inputTarget: this.inputTarget,
      });

      // 🛡️ Fallback: try to clear input even if form submission fails
      try {
        if (this.hasInputTarget) {
          this.inputTarget.value = "";
        }
      } catch (fallbackError) {
        console.error(
          "💥 SearchFieldController: Fallback clear also failed",
          fallbackError,
        );
      }
    }
  }

  clearSelection() {
    if (this.hasSelectionOutlet) {
      this.selectionOutlet.clear();
    }
  }

  /**
   * 🔍 Check if search field has content
   *
   * @returns {boolean} True if the search field has a value
   */
  get hasSearchContent() {
    return this.hasInputTarget && this.inputTarget.value.trim().length > 0;
  }

  /**
   * ⌨️ Handle user typing. Once the user modifies text after results (clear button visible),
   * we revert to showing the submit button again so they can run a new search.
   */
  handleInput() {
    this.updateButtons();
  }

  /**
   * 🔁 Update button visibility according to current input value.
   * Rule: If there is ANY text AND we have not yet submitted? We still show submit.
   * Clear button only shows when server indicated there are active results (initial state) AND
   * the user has not modified the input since (i.e., value matches original value). For simplicity
   * and because server re-renders on submit, we just show clear button when input has content on connect
   * and hide it as soon as user types.
   */
  updateButtons() {
    if (!this.hasInputTarget) return;

    // If user is typing (input event), always show submit and hide clear.
    // Clear button persists only until first keystroke after connect.
    if (this.hasClearButtonTarget && this.hasSubmitButtonTarget) {
      this.showSubmitHideClear();
    }
  }

  showSubmitHideClear() {
    if (this.hasSubmitButtonTarget)
      this.submitButtonTarget.classList.remove("hidden");
    if (this.hasClearButtonTarget)
      this.clearButtonTarget.classList.add("hidden");
  }

  showClearHideSubmit() {
    if (this.hasClearButtonTarget)
      this.clearButtonTarget.classList.remove("hidden");
    if (this.hasSubmitButtonTarget)
      this.submitButtonTarget.classList.add("hidden");
  }

  /**
   * 🔍 Update focus to the search field
   */
  updateFocus() {
    if (this.hasInputTarget) this.inputTarget.focus();
  }

  /**
   * Add data-turbo-permanent attribute to inputTarget on focusin.
   * Prevents background page refresh from clearing inputTarget during interaction.
   */
  onFocusin(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.inputTarget.setAttribute("data-turbo-permanent", "");
    }
  }

  /**
   * Remove data-turbo-permanent attribute from inputTarget on focusin
   */
  onFocusout(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.inputTarget.removeAttribute("data-turbo-permanent");
    }
  }
}
