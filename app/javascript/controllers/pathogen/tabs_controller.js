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
   * Private field for storing bound Turbo render handler
   * @type {Function|null}
   * @private
   */
  #boundHandleTurboRender = null;

  /**
   * Private field for storing bound Turbo before-morph handler
   * @type {Function|null}
   * @private
   */
  #boundHandleBeforeMorph = null;

  /**
   * Private field for storing bound Turbo before-render handler
   * @type {Function|null}
   * @private
   */
  #boundHandleBeforeRender = null;

  /**
   * Private field for storing the currently selected index before morph
   * @type {number|null}
   * @private
   */
  #selectedIndexBeforeMorph = null;

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

      // Check if we preserved state from a morph
      if (this.#selectedIndexBeforeMorph !== null) {
        initialIndex = this.#selectedIndexBeforeMorph;
        this.#selectedIndexBeforeMorph = null;
      }
      // If URL sync is enabled, check for hash in URL
      else if (this.syncUrlValue) {
        const hashIndex = this.#getTabIndexFromHash();
        if (hashIndex !== -1) {
          initialIndex = hashIndex;
        }

        // Listen for hash changes (back/forward navigation)
        this.#boundHandleHashChange = this.#handleHashChange.bind(this);
        window.addEventListener("hashchange", this.#boundHandleHashChange);

        // Listen for Turbo morph events to re-select tab from hash
        this.#boundHandleTurboRender = this.#handleTurboRender.bind(this);
        this.#boundHandleBeforeMorph = this.#handleBeforeMorph.bind(this);
        this.#boundHandleBeforeRender = this.#handleBeforeRender.bind(this);

        // Listen to turbo:before-render to mark visible panel as permanent BEFORE morphing starts
        document.addEventListener("turbo:before-render", this.#boundHandleBeforeRender);

        // Listen to turbo:before-morph-element to preserve visibility during morph
        document.addEventListener("turbo:before-morph-element", this.#boundHandleBeforeMorph);

        // Listen to turbo:render which fires after morphing is complete
        document.addEventListener("turbo:render", this.#boundHandleTurboRender);
      }

      // Select the initial tab
      const validatedIndex = this.#validateDefaultIndex(initialIndex);
      this.#selectTabByIndex(validatedIndex);

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
   * Preserves selected tab index if this is part of a Turbo morph
   *
   * @returns {void}
   */
  disconnect() {
    // Store selected index before disconnect (for Turbo morph scenarios)
    // Find the currently selected tab
    const selectedTab = this.tabTargets.find((tab) =>
      tab.getAttribute("aria-selected") === "true"
    );
    if (selectedTab) {
      this.#selectedIndexBeforeMorph = this.tabTargets.indexOf(selectedTab);
    }

    // Remove hash change listener if URL sync is enabled
    if (this.syncUrlValue) {
      if (this.#boundHandleHashChange) {
        window.removeEventListener("hashchange", this.#boundHandleHashChange);
      }
      if (this.#boundHandleBeforeRender) {
        document.removeEventListener("turbo:before-render", this.#boundHandleBeforeRender);
      }
      if (this.#boundHandleBeforeMorph) {
        document.removeEventListener("turbo:before-morph-element", this.#boundHandleBeforeMorph);
      }
      if (this.#boundHandleTurboRender) {
        document.removeEventListener("turbo:morph", this.#boundHandleTurboRender);
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
      panel.classList.toggle("hidden", !isVisible);

      // Clear any inline display style that might have been forced
      // and force display:block for visible panels to override any CSS issues
      if (isVisible) {
        panel.style.display = 'block';
      } else {
        panel.style.display = '';
      }

      // Update ARIA hidden state
      panel.setAttribute("aria-hidden", String(!isVisible));

      // Force Turbo frames to reload if they're lazy and becoming visible
      if (isVisible) {
        const lazyFrames = panel.querySelectorAll('turbo-frame[loading="lazy"][src]');
        lazyFrames.forEach((frame) => {
          // Don't interfere with frames that are busy or already loaded
          // Just let Turbo handle it naturally when the panel becomes visible
        });
      }
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
      const tabIndex = this.tabTargets.findIndex((tab) => tab && tab.id === hash);
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
      console.error("[pathogen--tabs] Error getting tab index from hash:", error);
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
   * Handles Turbo before-render to prevent Turbo Frame auto-refresh in visible panels
   * This fires BEFORE Turbo starts morphing, allowing us to temporarily disable
   * the refresh attribute on frames so they don't auto-reload during morph
   * @private
   * @param {CustomEvent} event - The turbo:before-render event
   * @returns {void}
   */
  #handleBeforeRender(event) {
    try {
      // Find the currently visible panel
      const visiblePanel = this.panelTargets.find(panel => !panel.classList.contains('hidden'));

      if (visiblePanel) {

        // Mark all Turbo Frames in the visible panel as permanent to prevent morphing
        const frames = visiblePanel.querySelectorAll('turbo-frame');
        frames.forEach(frame => {
          if (frame.complete) {
            frame.setAttribute('data-turbo-permanent', '');
            frame.setAttribute('id', frame.id); // Ensure ID is present for matching
          }
        });
      }
    } catch (error) {
      console.error("[pathogen--tabs] Error handling before render:", error);
    }
  }

  /**
   * Handles Turbo before-morph-element to preserve panel visibility
   * This fires before Turbo morphs each element, allowing us to transfer
   * the visibility state from the old element to the new one
   * @private
   * @param {CustomEvent} event - The turbo:before-morph-element event
   * @returns {void}
   */
  #handleBeforeMorph(event) {
    try {
      const { target, detail } = event;
      const { newElement } = detail;

      // Check if this is one of our tab panels being morphed
      if (target.hasAttribute && target.hasAttribute('data-pathogen--tabs-target') &&
          target.getAttribute('data-pathogen--tabs-target') === 'panel') {

        // If the old panel is visible (not hidden), make sure the new one is too
        const isVisible = !target.classList.contains('hidden');

        if (isVisible && newElement.classList.contains('hidden')) {
          newElement.classList.remove('hidden');
          newElement.setAttribute('aria-hidden', 'false');
        }
      }
    } catch (error) {
      console.error("[pathogen--tabs] Error handling before morph:", error);
    }
  }

  /**
   * Handles Turbo morph/render events to restore tab selection from hash
   * This ensures that after a Turbo morph (e.g., language change), the correct
   * tab is selected based on the URL hash, even if the server renders a different default
   * @private
   * @returns {void}
   */
  #handleTurboRender() {
    try {
      // Remove permanent attribute from frames and reload them to get translated content
      this.panelTargets.forEach(panel => {
        const permanentFrames = panel.querySelectorAll('turbo-frame[data-turbo-permanent]');
        permanentFrames.forEach(frame => {
          frame.removeAttribute('data-turbo-permanent');

          // Only reload frames in visible panels to get translated content
          if (!panel.classList.contains('hidden') && frame.src) {
            frame.reload();
          }
        });
      });

      // Use setTimeout with a slight delay to ensure Turbo frames are fully settled
      // requestAnimationFrame is not enough because Turbo may still be processing frames
      setTimeout(() => {
        const hashIndex = this.#getTabIndexFromHash();
        if (hashIndex !== -1) {
          // Re-validate targets after morph
          if (!this.#validateTargets()) {
            console.error("[pathogen--tabs] Targets validation failed after morph");
            return;
          }

          // Don't update URL - it already has the hash
          this.#selectTabByIndex(hashIndex, false);

          // Verify the panel stays visible after a short delay
          setTimeout(() => {
            // Check actual visibility and force display:block if needed
            const visiblePanel = this.panelTargets.find(p => !p.classList.contains('hidden'));
            if (visiblePanel && window.getComputedStyle(visiblePanel).display === 'none') {
              visiblePanel.style.display = 'block';
            }
          }, 100);
        }
      }, 50); // Small delay to let Turbo finish processing
    } catch (error) {
      console.error("[pathogen--tabs] Error handling Turbo render:", error);
    }
  }
}
