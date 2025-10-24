import { Controller } from "@hotwired/stimulus";

/**
 * Tabs Controller
 *
 * Implements W3C ARIA Authoring Practices Guide tab pattern with automatic activation.
 * Provides keyboard navigation (arrow keys, Home, End) and accessible tab switching.
 * Supports optional URL hash syncing for bookmarkable tabs and browser back/forward navigation.
 *
 * @class TabsController
 * @extends Controller
 *
 * @example Basic Usage
 * <nav data-controller="pathogen--tabs" data-pathogen--tabs-default-index-value="0">
 *   <div role="tablist">
 *     <button role="tab" data-pathogen--tabs-target="tab">Tab 1</button>
 *     <button role="tab" data-pathogen--tabs-target="tab">Tab 2</button>
 *   </div>
 *   <div data-pathogen--tabs-target="panel">Panel 1</div>
 *   <div data-pathogen--tabs-target="panel">Panel 2</div>
 * </nav>
 *
 * @example With URL Sync (Bookmarkable Tabs)
 * <nav data-controller="pathogen--tabs"
 *      data-pathogen--tabs-sync-url-value="true"
 *      data-pathogen--tabs-default-index-value="0">
 *   <div role="tablist">
 *     <button role="tab" id="overview-tab" data-pathogen--tabs-target="tab">Overview</button>
 *     <button role="tab" id="settings-tab" data-pathogen--tabs-target="tab">Settings</button>
 *   </div>
 *   <div id="overview-panel" data-pathogen--tabs-target="panel">Panel 1</div>
 *   <div id="settings-panel" data-pathogen--tabs-target="panel">Panel 2</div>
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
   * @property {Boolean} syncUrl - Whether to sync tab selection with URL hash (default: false)
   */
  static values = {
    defaultIndex: { type: Number, default: 0 },
    syncUrl: { type: Boolean, default: false },
  };

  /**
   * Private field for storing bound hash change handler
   * @type {Function|null}
   * @private
   */
  #boundHandleHashChange = null;

  /**
   * Private field for storing bound turbo render handler
   * @type {Function|null}
   * @private
   */
  #boundHandleTurboRender = null;

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

      // Determine initial tab index
      let initialIndex = this.defaultIndexValue;

      // If URL sync is enabled, check for hash in URL
      if (this.syncUrlValue) {
        const hashIndex = this.#getTabIndexFromHash();
        if (hashIndex !== -1) {
          initialIndex = hashIndex;
        }

        // Listen for hash changes (back/forward navigation)
        this.#boundHandleHashChange = this.#handleHashChange.bind(this);
        window.addEventListener("hashchange", this.#boundHandleHashChange);

        // Listen for Turbo render events to restore tab selection after page morphs
        // This is critical because Turbo morphing does NOT call disconnect/connect
        this.#boundHandleTurboRender = this.#handleTurboRender.bind(this);
        document.addEventListener("turbo:render", this.#boundHandleTurboRender);
      }

      // Select the initial tab
      const validatedIndex = this.#validateDefaultIndex(initialIndex);
      this.#selectTabByIndex(validatedIndex);

      // Add initialization markers
      this.element.classList.add("tabs-initialized");
    } catch (error) {
      console.error("[pathogen--tabs] Error during initialization:", error);
    }
    this.element.dataset.controllerConnected = "true";
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
   * Gets the orientation of the tablist
   * @private
   * @returns {string} 'horizontal' or 'vertical'
   */
  #getOrientation() {
    const tablist = this.element.querySelector('[role="tablist"]');
    return tablist?.getAttribute("aria-orientation") || "horizontal";
  }

  /**
   * Handles keyboard navigation
   * Supports Arrow Left/Right (horizontal) or Up/Down (vertical), Home, End keys
   * Navigation direction adapts to aria-orientation attribute
   *
   * @param {KeyboardEvent} event - The keyboard event
   * @returns {void}
   */
  handleKeyDown(event) {
    try {
      const isVertical = this.#getOrientation() === "vertical";

      // Map keys based on orientation
      const handlers = {
        [isVertical ? "ArrowUp" : "ArrowLeft"]: () =>
          this.#navigateToPrevious(event),
        [isVertical ? "ArrowDown" : "ArrowRight"]: () =>
          this.#navigateToNext(event),
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
    // Remove hash change listener if URL sync is enabled
    if (this.syncUrlValue) {
      if (this.#boundHandleHashChange) {
        window.removeEventListener("hashchange", this.#boundHandleHashChange);
      }
      if (this.#boundHandleTurboRender) {
        document.removeEventListener("turbo:render", this.#boundHandleTurboRender);
      }
    }

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
   * @param {boolean} updateUrl - Whether to update the URL hash (default: true)
   * @returns {void}
   */
  #selectTabByIndex(index, updateUrl = true) {
    // Defensive checks for morph scenarios
    if (!this.hasTabTarget || !this.hasPanelTarget) {
      return;
    }

    if (index < 0 || index >= this.tabTargets.length) {
      return;
    }

    // Update all tabs
    this.tabTargets.forEach((tab, i) => {
      if (!tab) return; // Skip if tab doesn't exist

      const isSelected = i === index;

      // Update ARIA attributes
      tab.setAttribute("aria-selected", String(isSelected));

      // Update roving tabindex
      tab.tabIndex = isSelected ? 0 : -1;
    });

    // Update all panels
    this.panelTargets.forEach((panel, i) => {
      if (!panel) return; // Skip if panel doesn't exist

      const isVisible = i === index;

      // Update visibility
      // Note: Using classList.toggle with 'hidden' class (not inline styles)
      // is critical for Turbo Frame lazy loading. When 'hidden' is removed,
      // Turbo detects the frame is now visible and triggers automatic fetch.
      // CSS ensures visible panels display as block via [role="tabpanel"]:not(.hidden) rule.
      panel.classList.toggle("hidden", !isVisible);

      // Update ARIA hidden state
      panel.setAttribute("aria-hidden", String(!isVisible));

      // Turbo Frame lazy loading happens automatically when panel becomes visible
      // No explicit intervention needed - Turbo handles it when 'hidden' class is removed
    });

    // Update URL hash if sync is enabled
    if (this.syncUrlValue && updateUrl) {
      this.#updateUrlHash(index);
    }

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

  /**
   * Gets the tab ID for URL hash
   * Uses the tab's ID if available, otherwise uses the panel's ID, or falls back to index
   * @private
   * @param {number} index - The tab index
   * @returns {string} The hash identifier
   */
  #getTabHash(index) {
    // Defensive checks
    if (!this.hasTabTarget || !this.hasPanelTarget) {
      return `tab-${index}`;
    }

    const tab = this.tabTargets[index];
    const panel = this.panelTargets[index];

    // Prefer tab ID, then panel ID, finally fall back to index
    if (tab?.id) {
      return tab.id;
    }
    if (panel?.id) {
      return panel.id;
    }
    return `tab-${index}`;
  }

  /**
   * Updates the URL hash with the selected tab
   * @private
   * @param {number} index - The tab index
   * @returns {void}
   */
  #updateUrlHash(index) {
    try {
      const hash = this.#getTabHash(index);
      const url = new URL(window.location.href);
      // Clear stale tab query params so subsequent submissions don't carry outdated values
      url.searchParams.delete("tab");
      url.hash = hash;

      // Use replaceState to avoid adding to browser history on every tab change
      window.history.replaceState(null, "", url.toString());
    } catch (error) {
      console.error("[pathogen--tabs] Error updating URL hash:", error);
    }
  }

  /**
   * Gets the tab index from the current URL hash
   * @private
   * @returns {number} The tab index, or -1 if not found
   */
  #getTabIndexFromHash() {
    try {
      const hash = window.location.hash.slice(1); // Remove the '#'
      if (!hash) {
        return -1;
      }

      // Ensure targets are available (defensive check for morph scenarios)
      if (!this.hasTabTarget || !this.hasPanelTarget) {
        return -1;
      }

      // Try to find tab by ID
      const tabIndex = this.tabTargets.findIndex(
        (tab) => tab && tab.id === hash,
      );
      if (tabIndex !== -1) {
        return tabIndex;
      }

      // Try to find panel by ID
      const panelIndex = this.panelTargets.findIndex(
        (panel) => panel && panel.id === hash,
      );
      if (panelIndex !== -1) {
        return panelIndex;
      }

      // Try to parse as tab-{index} format
      const match = hash.match(/^tab-(\d+)$/);
      if (match) {
        const index = parseInt(match[1], 10);
        if (index >= 0 && index < this.tabTargets.length) {
          return index;
        }
      }

      return -1;
    } catch (error) {
      console.error(
        "[pathogen--tabs] Error getting tab index from hash:",
        error,
      );
      return -1;
    }
  }

  /**
   * Handles browser hash change events (back/forward navigation)
   * @private
   * @returns {void}
   */
  #handleHashChange() {
    try {
      const hashIndex = this.#getTabIndexFromHash();
      if (hashIndex !== -1) {
        // Don't update URL again when responding to hash change
        this.#selectTabByIndex(hashIndex, false);
      }
    } catch (error) {
      console.error("[pathogen--tabs] Error handling hash change:", error);
    }
  }

  /**
   * Handles Turbo render events to restore tab selection after page morphs
   *
   * Critical: When Turbo morphs the page, Stimulus controllers do NOT disconnect/reconnect.
   * The controller instance persists while the DOM underneath changes. This means our
   * connect() method never runs again to restore tab selection from the URL hash.
   *
   * This handler re-synchronizes tab selection after a morph by:
   * 1. Re-validating targets (DOM may have changed during morph)
   * 2. Reading the URL hash (which survives the morph)
   * 3. Selecting the appropriate tab based on the hash
   * 4. Reloading frames in visible panels to get fresh translated content
   *
   * @private
   * @param {Event} event - The turbo:render event
   * @returns {void}
   */
  #handleTurboRender(event) {
    try {
      // Re-validate targets after morph in case DOM structure changed
      if (!this.#validateTargets()) {
        return;
      }

      // Restore tab selection from URL hash
      const hashIndex = this.#getTabIndexFromHash();
      if (hashIndex !== -1) {
        // Don't update URL again - we're restoring from it
        this.#selectTabByIndex(hashIndex, false);
      } else {
        // No hash found, use default index
        const validatedIndex = this.#validateDefaultIndex(this.defaultIndexValue);
        this.#selectTabByIndex(validatedIndex, false);
      }

      // Note: We don't reload frames here because:
      // 1. Frames with refresh="morph" are morphed during page morph (already translated)
      // 2. Reloading causes untranslated content to flash while frame fetches new content
      // 3. LocalTime processes morphed frame content via turbo:render event
    } catch (error) {
      console.error("[pathogen--tabs] Error handling turbo render:", error);
    }
  }

}
