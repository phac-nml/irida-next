import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["input", "clearButton", "submitButton"];

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
      this.inputTarget.focus();

      // 🔄 Find the parent form
      const form = this.element.closest("form");
      if (!form) {
        console.error("❌ SearchFieldController: Parent form not found");
        return;
      }

      // ♻️ Toggle buttons: hide clear, show submit
      this.showSubmitHideClear();

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

  /**
   * 🔍 Check if search field has content
   *
   * @returns {boolean} True if the search field has a value
   */
  get hasSearchContent() {
    return this.hasInputTarget && this.inputTarget.value.trim().length > 0;
  }

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

    // 🧹 Set up form submission listener to clear selection
    this.#setupFormSubmissionListener();
  }

  /**
   * 🚪 Cleanup when controller disconnects
   */
  disconnect() {
    console.debug("🔌 SearchFieldController: Disconnected");
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
   * 🚀 Handle form submission and clear current selection
   *
   * This method is called when the search form is submitted.
   * It clears the current selection before the search proceeds.
   */
  handleSubmit() {
    try {
      console.debug("🚀 SearchFieldController: Form submission started");

      // 🧹 Clear current selection by finding the selection controller
      this.#clearSelection();

      // 🎯 Update button states
      this.showClearHideSubmit();

      console.debug(
        "✅ SearchFieldController: Form submission handled successfully",
      );
    } catch (error) {
      console.error("💥 SearchFieldController: Error handling submit", {
        error: error.message,
        stack: error.stack,
        element: this.element,
      });

      // 🛡️ Continue with form submission even if clearing selection fails
      console.warn(
        "⚠️ SearchFieldController: Continuing with form submission despite error",
      );
    }
  }

  /**
   * 🧹 Clear current selection by finding the selection controller
   *
   * This method looks for a selection controller in the parent form
   * and calls its clear method to reset the current selection state.
   */
  #clearSelection() {
    try {
      // 🔍 Find the parent form
      const form = this.element.closest("form");
      if (!form) {
        console.warn("🔍 SearchFieldController: Parent form not found");
        return;
      }

      // 🎯 Look for selection controller in the form or its children
      let selectionController = null;

      // First, try to find selection controller in the form itself
      if (
        form.hasAttribute("data-controller") &&
        form.getAttribute("data-controller").includes("selection")
      ) {
        selectionController =
          this.application.getControllerForElementAndIdentifier(
            form,
            "selection",
          );
      }

      // If not found, look for selection controller in form children
      if (!selectionController) {
        const selectionElement = form.querySelector(
          "[data-controller*='selection']",
        );
        if (selectionElement) {
          selectionController =
            this.application.getControllerForElementAndIdentifier(
              selectionElement,
              "selection",
            );
        }
      }

      // If still not found, look for any element with selection controller in the document
      if (!selectionController) {
        const allSelectionElements = document.querySelectorAll(
          "[data-controller*='selection']",
        );
        for (const element of allSelectionElements) {
          const controller =
            this.application.getControllerForElementAndIdentifier(
              element,
              "selection",
            );
          if (controller && typeof controller.clear === "function") {
            selectionController = controller;
            break;
          }
        }
      }

      // 🧹 Clear selection if controller found
      if (
        selectionController &&
        typeof selectionController.clear === "function"
      ) {
        selectionController.clear();
        console.debug(
          "✅ SearchFieldController: Selection cleared via controller",
        );
      } else {
        console.warn("⚠️ SearchFieldController: No selection controller found");
      }
    } catch (error) {
      console.warn(
        "⚠️ SearchFieldController: Could not clear selection",
        error,
      );
    }
  }

  /**
   * 🧹 Public method to clear current selection
   *
   * This method can be called externally to clear the current selection.
   * Useful for other components that need to clear selection.
   */
  clearSelection() {
    this.#clearSelection();
  }

  /**
   * 🔍 Check if selection controller is available
   *
   * @returns {boolean} True if a selection controller is found and accessible
   */
  hasSelectionController() {
    try {
      const form = this.element.closest("form");
      if (!form) return false;

      // Check if form has selection controller
      if (
        form.hasAttribute("data-controller") &&
        form.getAttribute("data-controller").includes("selection")
      ) {
        return true;
      }

      // Check if any child has selection controller
      const selectionElement = form.querySelector(
        "[data-controller*='selection']",
      );
      return !!selectionElement;
    } catch (error) {
      console.warn(
        "⚠️ SearchFieldController: Error checking selection controller",
        error,
      );
      return false;
    }
  }

  /**
   * 🎯 Set up form submission listener to ensure selection is cleared
   *
   * This ensures that even if the button click handler doesn't fire,
   * the selection will still be cleared when the form is submitted.
   */
  #setupFormSubmissionListener() {
    try {
      const form = this.element.closest("form");
      if (form) {
        // 🧹 Clear selection on form submit (as a backup)
        form.addEventListener("submit", (event) => {
          // Small delay to ensure this runs before Turbo processes the form
          setTimeout(() => {
            this.#clearSelection();
          }, 0);
        });

        // 🧹 Also listen for Turbo events to ensure selection is cleared
        document.addEventListener("turbo:submit-start", (event) => {
          if (event.target === form) {
            this.#clearSelection();
          }
        });

        // 🧹 Listen for form submission events from the search field component
        this.element.addEventListener("submit", (event) => {
          this.#clearSelection();
        });

        console.debug(
          "✅ SearchFieldController: Form submission listeners added",
        );
      }
    } catch (error) {
      console.warn(
        "⚠️ SearchFieldController: Could not set up form listener",
        error,
      );
    }
  }
}
