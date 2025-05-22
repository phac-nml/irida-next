import { Controller } from "@hotwired/stimulus";

/**
 * 🎮 Controls the behavior of collapsible/expandable UI elements.
 *
 * This controller manages the state of a toggleable section,
 * ensuring ARIA attributes are correctly updated for accessibility
 * and visual cues (like icons) reflect the current state.
 *
 * @example
 * <div data-controller="collapsible">
 *   <button type="button" data-action="click->collapsible#toggle" data-collapsible-target="button">
 *     Toggle Me
 *     <span data-collapsible-target="icon">➡️</span>
 *   </button>
 *   <div data-collapsible-target="item" class="hidden" aria-hidden="true">
 *     Collapsible content goes here!
 *   </div>
 * </div>
 */
export default class extends Controller {
  /**
   * 🎯 Defines the DOM elements this controller interacts with.
   * @static
   * @property {HTMLElement} itemTarget - The content element that will be shown or hidden.
   * @property {HTMLElement} iconTarget - An optional icon element that visually indicates the collapsed/expanded state (e.g., a chevron).
   * @property {HTMLButtonElement} buttonTarget - The button element that triggers the toggle action.
   */
  static targets = ["item", "icon", "button"];

  /**
   * 🚀 Initializes the controller when it's connected to the DOM.
   * Sets the initial `aria-expanded` state on the button and updates
   * the icon to match the initial visibility of the collapsible item.
   */
  connect() {
    // Check if the collapsible item is initially hidden (collapsed)
    const isInitiallyCollapsed = this.itemTarget.classList.contains("hidden");

    // 🗣️ Set initial ARIA state for screen readers
    if (this.hasButtonTarget) {
      this.buttonTarget.setAttribute("aria-expanded", isInitiallyCollapsed ? "false" : "true");
    }

    // 🔄 Ensure the icon reflects the initial state
    this.#updateIcon(isInitiallyCollapsed);
  }

  /**
   * 🔄 Toggles the visibility of the collapsible item.
   *
   * When called, this method checks if the `itemTarget` is currently hidden:
   * - If hidden (collapsed): It expands the item, updates ARIA attributes (`aria-hidden`, `aria-expanded`),
   *   removes the `hidden` HTML attribute, and updates the icon.
   * - If visible (expanded): It collapses the item, updates ARIA attributes,
   *   adds the `hidden` HTML attribute, and updates the icon.
   */
  toggle(event) {
    if (event) {
      event.preventDefault();
      event.stopPropagation();
    }

    const isCollapsed = this.itemTarget.classList.contains("hidden") || 
                      this.itemTarget.hasAttribute("hidden");

    if (isCollapsed) {
      // ✨ Expanding the item
      this.itemTarget.classList.remove("hidden");
      this.itemTarget.setAttribute("aria-hidden", "false");
      this.itemTarget.removeAttribute("hidden");

      if (this.hasButtonTarget) {
        this.buttonTarget.setAttribute("aria-expanded", "true");
      }
      this.#updateIcon(false);
      
      // Dispatch event for other controllers to listen to
      this.dispatch("expanded", { target: this.element });
    } else {
      // 🙈 Collapsing the item
      this.itemTarget.classList.add("hidden");
      this.itemTarget.setAttribute("aria-hidden", "true");
      this.itemTarget.setAttribute("hidden", "");

      if (this.hasButtonTarget) {
        this.buttonTarget.setAttribute("aria-expanded", "false");
      }
      this.#updateIcon(true);
      
      // Dispatch event for other controllers to listen to
      this.dispatch("collapsed", { target: this.element });
    }
  }

  /**
   * 🎨 Updates the visual state of the icon (e.g., rotating a chevron).
   * This is a private method, indicated by the `#` prefix.
   *
   * @private
   * @param {boolean} collapsed - True if the item is now collapsed, false if expanded.
   */
  #updateIcon(collapsed) {
    // 🛡️ Guard clause: Do nothing if there's no icon target
    if (!this.hasIconTarget) return;

    // 🤔 Determine if the icon *should* have the 'rotate-180' class (expanded state)
    const wantsRotate180 = !collapsed;
    // 👀 Check if the icon *currently* has the 'rotate-180' class
    const hasRotate180 = this.iconTarget.classList.contains("rotate-180");

    // Apply rotation only if the current state doesn't match the desired state
    if (wantsRotate180 && !hasRotate180) {
      this.iconTarget.classList.remove("rotate-0");
      this.iconTarget.classList.add("rotate-180");
    } else if (!wantsRotate180 && hasRotate180) {
      this.iconTarget.classList.remove("rotate-180");
      this.iconTarget.classList.add("rotate-0");
    }
  }
}
