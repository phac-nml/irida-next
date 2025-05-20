import { Controller } from "@hotwired/stimulus";

/**
 * 🎮 Controls the behavior of sidebar menu items, particularly for handling active states and interactions.
 * Works in conjunction with the collapsible controller for expandable menu items.
 */
export default class extends Controller {
  static targets = ["trigger"];

  /**
   * 🚀 Initializes the controller when it's connected to the DOM.
   * Sets up initial state and event listeners.
   */
  connect() {
    // Add any initialization code here if needed
  }

  /**
   * 🔄 Handles the click event on the sidebar item.
   * Prevents default behavior if the item is disabled.
   * @param {Event} event - The click event
   */
  onClick(event) {
    if (this.element.hasAttribute('data-disabled')) {
      event.preventDefault();
      event.stopPropagation();
    }
  }

  /**
   * 📝 Updates the active state of the sidebar item.
   * @param {boolean} isActive - Whether the item should be marked as active
   */
  setActive(isActive) {
    if (isActive) {
      this.element.classList.add('active');
      this.element.setAttribute('aria-current', 'page');
    } else {
      this.element.classList.remove('active');
      this.element.removeAttribute('aria-current');
    }
  }
}
