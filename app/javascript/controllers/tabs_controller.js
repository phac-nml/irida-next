// 🎯 Tabs Controller
// Handles keyboard navigation and tab interactions for accessible tab panels
// @see https://www.w3.org/WAI/ARIA/apg/patterns/tabs/

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tab", "panel"];
  static values = {
    tablistId: String,
  };

  connect() {
    // 🔍 Initialize tab state only if this is the first instance for this tablist
    if (!this.isInitialized) {
      this.selectedTab = this.tabTargets.find(
        (tab) => tab.getAttribute("aria-selected") === "true",
      );
      this.selectedTab?.focus();
      this.isInitialized = true;

      // Add keyboard event listener to the tablist
      this.element.addEventListener("keydown", this.handleKeydown.bind(this));
    }
  }

  disconnect() {
    // Clean up event listener
    this.element.removeEventListener("keydown", this.handleKeydown.bind(this));
  }

  // 🎮 Handle keyboard navigation
  // @param {KeyboardEvent} event - The keyboard event
  handleKeydown(event) {
    // Only handle keyboard events if the target is a tab
    if (!event.target.matches('[role="tab"]')) return;

    const tabs = this.tabTargets;
    const currentIndex = tabs.indexOf(event.target);

    switch (event.key) {
      case "ArrowLeft":
        event.preventDefault();
        this.focusPreviousTab(currentIndex);
        break;
      case "ArrowRight":
        event.preventDefault();
        this.focusNextTab(currentIndex);
        break;
      case "Home":
        event.preventDefault();
        this.focusFirstTab();
        break;
      case "End":
        event.preventDefault();
        this.focusLastTab();
        break;
      case "Enter":
      case " ":
        event.preventDefault();
        event.target.click();
        break;
    }
  }

  // 🎯 Select a tab and show its panel
  // @param {Event} event - The click event
  select(event) {
    // Let Turbo Drive handle the navigation and server-side state updates
    // The server will handle:
    // - Setting aria-selected states
    // - Managing tabindex values
    // - Showing/hiding panels
    // - Updating visual styles
  }

  // 🔄 Focus the previous tab
  // @param {number} currentIndex - The index of the current tab
  focusPreviousTab(currentIndex) {
    const tabs = this.tabTargets;
    const previousIndex = currentIndex > 0 ? currentIndex - 1 : tabs.length - 1;
    const previousTab = tabs[previousIndex];
    previousTab.focus();
  }

  // 🔄 Focus the next tab
  // @param {number} currentIndex - The index of the current tab
  focusNextTab(currentIndex) {
    const tabs = this.tabTargets;
    const nextIndex = currentIndex < tabs.length - 1 ? currentIndex + 1 : 0;
    const nextTab = tabs[nextIndex];
    nextTab.focus();
  }

  // 🏁 Focus the first tab
  focusFirstTab() {
    const firstTab = this.tabTargets[0];
    firstTab?.focus();
  }

  // 🏁 Focus the last tab
  focusLastTab() {
    const tabs = this.tabTargets;
    const lastTab = tabs[tabs.length - 1];
    lastTab?.focus();
  }
}
