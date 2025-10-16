import { Controller } from "@hotwired/stimulus";

/**
 * Tabs Controller
 *
 * Implements W3C ARIA Authoring Practices Guide tab pattern with automatic activation.
 * Provides keyboard navigation (arrow keys, Home, End) and accessible tab switching.
 *
 * @class TabsController
 * @extends Controller
 *
 * @example
 * <nav data-controller="pathogen--tabs" data-pathogen--tabs-default-index-value="0">
 *   <div role="tablist">
 *     <button role="tab" data-pathogen--tabs-target="tab">Tab 1</button>
 *     <button role="tab" data-pathogen--tabs-target="tab">Tab 2</button>
 *   </div>
 *   <div data-pathogen--tabs-target="panel">Panel 1</div>
 *   <div data-pathogen--tabs-target="panel">Panel 2</div>
 * </nav>
 *
 * @see https://www.w3.org/WAI/ARIA/apg/patterns/tabs/
 */
export default class extends Controller {
  /**
   * Stimulus targets
   * @type {string[]}
   */
  static targets = ["tab", "panel"];

  /**
   * Stimulus values
   * @type {Object}
   * @property {Number} defaultIndex - Index of the initially selected tab (default: 0)
   */
  static values = {
    defaultIndex: { type: Number, default: 0 },
  };

  /**
   * Initializes the controller when it connects to the DOM
   * Sets up ARIA relationships and selects the default tab.
   *
   * @returns {void}
   */
  connect() {
    try {
      // Validate that we have matching tabs and panels
      if (!this.#validateTargets()) {
        return;
      }

      // Set up ARIA roles and relationships
      this.#setupARIA();

      // Select the default tab
      const defaultIndex = this.#validateDefaultIndex(this.defaultIndexValue);
      this.#selectTabByIndex(defaultIndex);

      // Add initialization marker class for CSS progressive enhancement
      this.element.classList.add("tabs-initialized");

      // Add test marker to indicate controller is connected
      this.element.dataset.controllerConnected = "true";
    } catch (error) {
      console.error("[pathogen--tabs] Error during initialization:", error);
    }
  }

  /**
   * Handles tab selection via click
   *
   * @param {Event} event - The click event
   * @returns {void}
   */
  selectTab(event) {
    try {
      const clickedTab = event.currentTarget;
      const tabIndex = this.tabTargets.indexOf(clickedTab);

      if (tabIndex === -1) {
        console.error("[pathogen--tabs] Clicked tab not found in targets");
        return;
      }

      this.#selectTabByIndex(tabIndex);
    } catch (error) {
      console.error("[pathogen--tabs] Error selecting tab:", error);
    }
  }

  /**
   * Handles keyboard navigation
   * Supports Arrow Left/Right, Home, End keys
   *
   * @param {KeyboardEvent} event - The keyboard event
   * @returns {void}
   */
  handleKeyDown(event) {
    try {
      const handlers = {
        ArrowLeft: () => this.#navigateToPrevious(event),
        ArrowRight: () => this.#navigateToNext(event),
        Home: () => this.#navigateToFirst(event),
        End: () => this.#navigateToLast(event),
      };

      const handler = handlers[event.key];
      if (handler) {
        event.preventDefault();
        handler();
      }
    } catch (error) {
      console.error("[pathogen--tabs] Error handling keyboard:", error);
    }
  }

  /**
   * Cleans up when controller disconnects from the DOM
   *
   * @returns {void}
   */
  disconnect() {
    // Remove initialization marker
    this.element.classList.remove("tabs-initialized");

    // Remove test marker
    delete this.element.dataset.controllerConnected;
  }

  // Private methods

  /**
   * Validates that tabs and panels are properly configured
   * @private
   * @returns {boolean} True if validation passes
   */
  #validateTargets() {
    if (this.tabTargets.length === 0) {
      console.error("[pathogen--tabs] At least one tab target is required");
      return false;
    }

    if (this.panelTargets.length === 0) {
      console.error("[pathogen--tabs] At least one panel target is required");
      return false;
    }

    if (this.tabTargets.length !== this.panelTargets.length) {
      console.error("[pathogen--tabs] Tab and panel counts must match", {
        tabs: this.tabTargets.length,
        panels: this.panelTargets.length,
      });
      return false;
    }

    return true;
  }

  /**
   * Validates and normalizes the default index value
   * @private
   * @param {number} index - The default index
   * @returns {number} Validated index (0 if invalid)
   */
  #validateDefaultIndex(index) {
    if (index < 0 || index >= this.tabTargets.length) {
      console.warn(
        `[pathogen--tabs] default_index ${index} out of bounds, using 0`,
      );
      return 0;
    }
    return index;
  }

  /**
   * Sets up ARIA attributes on tabs and panels
   * @private
   * @returns {void}
   */
  #setupARIA() {
    this.tabTargets.forEach((tab, index) => {
      const panel = this.panelTargets[index];

      // Ensure tab has required ARIA attributes
      if (!tab.hasAttribute("role")) {
        tab.setAttribute("role", "tab");
      }

      // Link tab to panel
      if (panel && panel.id) {
        tab.setAttribute("aria-controls", panel.id);
      }

      // Initial aria-selected (will be updated by selectTabByIndex)
      tab.setAttribute("aria-selected", "false");

      // Initial tabindex (will be updated by selectTabByIndex)
      tab.tabIndex = -1;
    });

    this.panelTargets.forEach((panel, index) => {
      const tab = this.tabTargets[index];

      // Ensure panel has required ARIA attributes
      if (!panel.hasAttribute("role")) {
        panel.setAttribute("role", "tabpanel");
      }

      // Link panel to tab
      if (tab && tab.id) {
        panel.setAttribute("aria-labelledby", tab.id);
      }

      // Initial hidden state (will be updated by selectTabByIndex)
      panel.setAttribute("aria-hidden", "true");
    });
  }

  /**
   * Selects a tab by index
   *
   * This method handles both tab selection state and panel visibility.
   * When a panel becomes visible (hidden class removed), any Turbo Frames
   * with loading="lazy" inside will automatically fetch their content.
   *
   * Turbo Frame Integration:
   * - Removing the 'hidden' class triggers Turbo's lazy loading mechanism
   * - Turbo automatically fetches frame content when it becomes visible
   * - Once loaded, Turbo caches the content (no refetch on revisit)
   * - No explicit fetch() or JavaScript handling needed
   *
   * @private
   * @param {number} index - The tab index to select
   * @returns {void}
   */
  #selectTabByIndex(index) {
    if (index < 0 || index >= this.tabTargets.length) {
      return;
    }

    // Update all tabs
    this.tabTargets.forEach((tab, i) => {
      const isSelected = i === index;

      // Update ARIA attributes
      tab.setAttribute("aria-selected", String(isSelected));

      // Update roving tabindex
      tab.tabIndex = isSelected ? 0 : -1;
    });

    // Update all panels
    this.panelTargets.forEach((panel, i) => {
      const isVisible = i === index;

      // Update visibility
      // Note: Using classList.toggle with 'hidden' class (not inline styles)
      // is critical for Turbo Frame lazy loading. When 'hidden' is removed,
      // Turbo detects the frame is now visible and triggers automatic fetch.
      panel.classList.toggle("hidden", !isVisible);

      // Update ARIA hidden state
      panel.setAttribute("aria-hidden", String(!isVisible));
    });

    // Turbo Frame lazy loading happens automatically here:
    // If the newly visible panel contains a <turbo-frame loading="lazy" src="...">,
    // Turbo will fetch the content immediately after the panel becomes visible.
    // The frame's fallback content (loading spinner) displays during fetch,
    // then morphs into the loaded content seamlessly.
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
    this.#focusAndSelectTab(targetIndex);
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
    this.#focusAndSelectTab(targetIndex);
  }

  /**
   * Navigates to the first tab
   * @private
   * @param {KeyboardEvent} event - The keyboard event
   * @returns {void}
   */
  #navigateToFirst(event) {
    this.#focusAndSelectTab(0);
  }

  /**
   * Navigates to the last tab
   * @private
   * @param {KeyboardEvent} event - The keyboard event
   * @returns {void}
   */
  #navigateToLast(event) {
    this.#focusAndSelectTab(this.tabTargets.length - 1);
  }

  /**
   * Focuses a tab and selects it (automatic activation pattern)
   * @private
   * @param {number} index - The tab index
   * @returns {void}
   */
  #focusAndSelectTab(index) {
    if (index < 0 || index >= this.tabTargets.length) {
      return;
    }

    const tab = this.tabTargets[index];

    // Move focus to the tab
    tab.focus();

    // Select the tab (automatic activation)
    this.#selectTabByIndex(index);
  }
}
