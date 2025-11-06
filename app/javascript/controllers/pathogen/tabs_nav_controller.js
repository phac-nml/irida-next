import { Controller } from "@hotwired/stimulus";

/**
 * TabsNav Controller
 *
 * Implements W3C ARIA Authoring Practices Guide tab pattern with MANUAL activation.
 * Provides keyboard navigation (arrow keys, Home, End) for server-side navigation tabs.
 * Unlike pathogen--tabs (client-side), this uses anchor links that trigger full page loads.
 *
 * Key differences from automatic activation:
 * - Arrow keys move focus but DO NOT activate tabs
 * - Space/Enter keys are required to follow the link (activate the tab)
 * - Uses aria-current="page" instead of aria-selected
 * - No tab panels - each tab is a navigation link
 *
 * @class TabsNavController
 * @extends Controller
 *
 * @example Basic Usage
 * <%= render Pathogen::TabsNav.new(id: "project-nav", label: "Project filters") do |nav| %>
 *   <% nav.with_tab(
 *     id: "all-projects",
 *     text: "All Projects",
 *     href: projects_path,
 *     selected: !params[:personal]
 *   ) %>
 *   <% nav.with_tab(
 *     id: "my-projects",
 *     text: "My Projects",
 *     href: projects_path(personal: true),
 *     selected: params[:personal]
 *   ) %>
 * <% end %>
 *
 * @see https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
 */
export default class extends Controller {
  /**
   * Stimulus targets
   * @type {string[]}
   */
  static targets = ["tab"];

  /**
   * Initializes the controller when it connects to the DOM
   * Sets up roving tabindex for keyboard navigation.
   *
   * @returns {void}
   */
  connect() {
    try {
      // Validate that we have at least one tab
      if (!this.#validateTargets()) {
        return;
      }

      // Set up roving tabindex
      this.#setupTabindex();

      // Add initialization marker for testing
      this.element.dataset.controllerConnected = "true";
    } catch (error) {
      console.error("[pathogen--tabs-nav] Error during initialization:", error);
    }
  }

  /**
   * Handles keyboard navigation for tab links
   * Supports Arrow Left/Right, Home, End keys
   * Manual activation: focus does NOT activate tabs, only Space/Enter do
   *
   * @param {KeyboardEvent} event - The keyboard event
   * @returns {void}
   */
  handleKeydown(event) {
    try {
      const key = event.key;

      // Define handlers for each key
      const handlers = {
        ArrowLeft: () => this.#navigateToPrevious(event),
        ArrowRight: () => this.#navigateToNext(event),
        Home: () => this.#navigateToFirst(event),
        End: () => this.#navigateToLast(event),
      };

      const handler = handlers[key];

      // If we have a handler for this key, prevent default and execute
      if (handler) {
        event.preventDefault();
        handler();
      }

      // Note: Space and Enter are NOT handled here - they work naturally
      // with anchor links to follow the href (activate the tab)
    } catch (error) {
      console.error("[pathogen--tabs-nav] Error handling keyboard:", error);
    }
  }

  /**
   * Cleans up when controller disconnects from the DOM
   *
   * @returns {void}
   */
  disconnect() {
    // Remove test marker
    delete this.element.dataset.controllerConnected;
  }

  // Private methods

  /**
   * Validates that tabs are properly configured
   * @private
   * @returns {boolean} True if validation passes
   */
  #validateTargets() {
    if (!this.hasTabTarget) {
      console.error("[pathogen--tabs-nav] At least one tab target is required");
      return false;
    }

    return true;
  }

  /**
   * Sets up roving tabindex for keyboard navigation
   * Only the selected (current) tab should be in the tab sequence
   * @private
   * @returns {void}
   */
  #setupTabindex() {
    this.tabTargets.forEach((tab) => {
      // Check if this tab is the current page
      const isCurrent = tab.getAttribute("aria-current") === "page";

      // Set tabindex: 0 for current tab, -1 for others
      tab.setAttribute("tabindex", isCurrent ? "0" : "-1");
    });
  }

  /**
   * Navigates to the previous tab (with wrap-around)
   * @private
   * @param {KeyboardEvent} event - The keyboard event
   * @returns {void}
   */
  #navigateToPrevious(event) {
    const currentIndex = this.tabTargets.indexOf(event.currentTarget);
    const targetIndex =
      currentIndex === 0 ? this.tabTargets.length - 1 : currentIndex - 1;
    this.#focusTab(targetIndex);
  }

  /**
   * Navigates to the next tab (with wrap-around)
   * @private
   * @param {KeyboardEvent} event - The keyboard event
   * @returns {void}
   */
  #navigateToNext(event) {
    const currentIndex = this.tabTargets.indexOf(event.currentTarget);
    const targetIndex = (currentIndex + 1) % this.tabTargets.length;
    this.#focusTab(targetIndex);
  }

  /**
   * Navigates to the first tab
   * @private
   * @param {KeyboardEvent} event - The keyboard event
   * @returns {void}
   */
  #navigateToFirst(event) {
    this.#focusTab(0);
  }

  /**
   * Navigates to the last tab
   * @private
   * @param {KeyboardEvent} event - The keyboard event
   * @returns {void}
   */
  #navigateToLast(event) {
    this.#focusTab(this.tabTargets.length - 1);
  }

  /**
   * Moves focus to a tab at the specified index
   * Does NOT activate the tab (manual activation pattern)
   * User must press Space or Enter to follow the link
   * @private
   * @param {number} index - The tab index
   * @returns {void}
   */
  #focusTab(index) {
    if (index < 0 || index >= this.tabTargets.length) {
      return;
    }

    const tab = this.tabTargets[index];

    // Only move focus - do NOT activate the tab
    // Space/Enter will follow the link naturally
    tab.focus();
  }
}
