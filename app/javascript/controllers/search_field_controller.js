import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input"]

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
        console.warn("🔍 SearchFieldController: Input target not found")
        return
      }

      // 🧹 Clear the input field
      this.inputTarget.value = ""

      // 🎨 Add visual feedback (optional)
      this.inputTarget.focus()

      // 🔄 Find the parent form
      const form = this.element.closest("form")
      if (!form) {
        console.error("❌ SearchFieldController: Parent form not found")
        return
      }

      // 🚀 Trigger form submission to refresh results
      // Using requestSubmit() for better control and compatibility
      form.requestSubmit()

      // ✅ Log success for debugging
      console.debug("✅ SearchFieldController: Search cleared successfully")

    } catch (error) {
      // 🚨 Comprehensive error handling
      console.error("💥 SearchFieldController: Error clearing search", {
        error: error.message,
        stack: error.stack,
        element: this.element,
        inputTarget: this.inputTarget
      })

      // 🛡️ Fallback: try to clear input even if form submission fails
      try {
        if (this.hasInputTarget) {
          this.inputTarget.value = ""
        }
      } catch (fallbackError) {
        console.error("💥 SearchFieldController: Fallback clear also failed", fallbackError)
      }
    }
  }

  /**
   * 🔍 Check if search field has content
   *
   * @returns {boolean} True if the search field has a value
   */
  get hasSearchContent() {
    return this.hasInputTarget && this.inputTarget.value.trim().length > 0
  }

  /**
   * 🎯 Initialize controller
   *
   * Sets up any initial state or event listeners
   */
  connect() {
    console.debug("🔗 SearchFieldController: Connected", {
      hasInputTarget: this.hasInputTarget,
      hasSearchContent: this.hasSearchContent
    })
  }

  /**
   * 🚪 Cleanup when controller disconnects
   */
  disconnect() {
    console.debug("🔌 SearchFieldController: Disconnected")
  }
}
