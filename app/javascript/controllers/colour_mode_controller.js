import { Controller } from "@hotwired/stimulus";
import ThemeManager from "lib/theme-manager";

/**
 * Colour Mode Controller
 *
 * Handles theme switching between light, dark, and system preferences.
 * Provides accessibility features for theme changes.
 * Uses centralized ThemeManager for consistent theme logic.
 * Automatically syncs theme changes across browser tabs.
 * Responds to OS-level dark mode preference changes when in system mode.
 *
 * @example
 * <div data-controller="colour-mode">
 *   <input type="radio" data-colour-mode-target="system" value="system">
 *   <input type="radio" data-colour-mode-target="light" value="light">
 *   <input type="radio" data-colour-mode-target="dark" value="dark">
 * </div>
 */
export default class extends Controller {
  static targets = ["system", "light", "dark"];

  connect() {
    // Use singleton announcement element to prevent duplicates
    this.announcementElement = this.getOrCreateAnnouncementElement();
    this.initializeTheme();
    this.setupWatchers();
  }

  disconnect() {
    // Clean up watchers
    this.cleanupWatchers();
    // Don't remove announcement element - it may be shared
    // Let the browser's GC handle cleanup when page unloads
  }

  /**
   * Get or create a singleton announcement element
   * @returns {HTMLElement} The announcement element
   */
  getOrCreateAnnouncementElement() {
    const existingElement = document.getElementById("theme-announcer");

    if (existingElement) {
      return existingElement;
    }

    const element = document.createElement("div");
    element.id = "theme-announcer";
    element.setAttribute("aria-live", "polite");
    element.setAttribute("aria-atomic", "true");
    element.classList.add("sr-only");
    document.body.appendChild(element);

    return element;
  }

  /**
   * Initialize the theme based on ThemeManager
   */
  initializeTheme() {
    try {
      const theme = ThemeManager.getCurrentTheme();
      const target = this.getTargetForTheme(theme);

      if (target) {
        target.checked = true;
      }

      // Theme is already applied by inline script, no need to reapply
    } catch (error) {
      console.error("Failed to initialize theme:", error);
      // Fallback to system preference
      if (this.hasSystemTarget) {
        this.systemTarget.checked = true;
      }
    }
  }

  /**
   * Set up watchers for system preference and cross-tab sync
   */
  setupWatchers() {
    // Watch for system preference changes (only updates when in system mode)
    this.cleanupSystemWatch = ThemeManager.watchSystemPreference(() => {
      // Only update UI if we're in system mode
      if (ThemeManager.isSystemTheme()) {
        this.updateCheckedState();
      }
    });

    // Watch for theme changes in other tabs
    this.cleanupStorageWatch = ThemeManager.watchStorageChanges((theme) => {
      this.updateCheckedState();
      this.announceThemeChange(theme);
    });
  }

  /**
   * Clean up watchers
   */
  cleanupWatchers() {
    if (this.cleanupSystemWatch) {
      this.cleanupSystemWatch();
    }
    if (this.cleanupStorageWatch) {
      this.cleanupStorageWatch();
    }
  }

  /**
   * Update the checked state of radio buttons based on current theme
   */
  updateCheckedState() {
    const theme = ThemeManager.getCurrentTheme();
    const target = this.getTargetForTheme(theme);
    if (target) {
      target.checked = true;
    }
  }

  /**
   * Handle theme toggle
   * @param {Event} event - The change event
   */
  toggleTheme(event) {
    try {
      const theme = event.target.value;

      // Validate and set theme using ThemeManager
      if (!ThemeManager.setTheme(theme)) {
        this.announceError();
        return;
      }

      // Apply theme with transition coordination
      ThemeManager.applyTheme(theme, true);

      // Announce change to screen readers
      this.announceThemeChange(theme);
    } catch (error) {
      console.error("Failed to toggle theme:", error);
      this.announceError();
    }
  }

  /**
   * Announce theme changes to screen readers
   * @param {string} theme - The new theme
   */
  announceThemeChange(theme) {
    const themeText = this.getThemeText(theme);

    if (!themeText) {
      console.error(`Missing I18n translation for theme: ${theme}`);
      this.announcementElement.textContent = `${theme} theme activated`;
      return;
    }

    const activatedText =
      this.element.dataset.colourModeActivatedText ||
      this.element.dataset.colourModeChangedText;

    if (!activatedText) {
      console.error("Missing I18n translation for activated text");
      this.announcementElement.textContent = `${themeText} activated`;
      return;
    }

    this.announcementElement.textContent = activatedText.replace(
      "%{theme}",
      themeText,
    );
  }

  /**
   * Announce errors to screen readers
   */
  announceError() {
    const errorText =
      this.element.dataset.colourModeErrorText ||
      "An error occurred while changing the theme";
    this.announcementElement.textContent = errorText;
  }

  /**
   * Get the target element for a given theme
   * @param {string} theme - The theme to find
   * @returns {HTMLInputElement|null} The target element or null
   */
  getTargetForTheme(theme) {
    const { THEMES } = ThemeManager;

    switch (theme) {
      case THEMES.LIGHT:
        return this.hasLightTarget ? this.lightTarget : null;
      case THEMES.DARK:
        return this.hasDarkTarget ? this.darkTarget : null;
      case THEMES.SYSTEM:
      default:
        return this.hasSystemTarget ? this.systemTarget : null;
    }
  }

  /**
   * Get the localized text for a theme
   * @param {string} theme - The theme to get text for
   * @returns {string|null} The localized theme text or null
   */
  getThemeText(theme) {
    const { THEMES } = ThemeManager;

    const themeMap = {
      [THEMES.SYSTEM]: this.element.dataset.colourModeSystemText,
      [THEMES.LIGHT]: this.element.dataset.colourModeLightText,
      [THEMES.DARK]: this.element.dataset.colourModeDarkText,
    };

    return themeMap[theme] || null;
  }
}
