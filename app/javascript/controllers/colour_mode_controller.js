import { Controller } from "@hotwired/stimulus";
import { announce } from "utilities/live_region";

/**
 * Colour Mode Controller
 *
 * Handles theme switching between light, dark, and system preferences.
 * Provides accessibility features for theme changes.
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
    this.announcementElement = document.createElement("div");
    this.announcementElement.setAttribute("aria-live", "polite");
    this.announcementElement.setAttribute("aria-atomic", "true");
    this.announcementElement.classList.add("sr-only");
    document.body.appendChild(this.announcementElement);

    this.initializeTheme();
  }

  disconnect() {
    if (this.announcementElement) {
      this.announcementElement.remove();
    }
  }

  /**
   * Initialize the theme based on localStorage or system preference
   */
  initializeTheme() {
    try {
      const theme = localStorage.getItem("theme");
      const target = this.getTargetForTheme(theme);
      if (target) {
        target.checked = true;
        this.updateTheme(theme);
      }
    } catch (error) {
      console.error("Failed to initialize theme:", error);
      // Fallback to system preference
      this.systemTarget.checked = true;
    }
  }

  /**
   * Handle theme toggle
   * @param {Event} event - The change event
   */
  toggleTheme(event) {
    try {
      const theme = event.target.value;
      localStorage.setItem("theme", theme);
      this.updateTheme(theme);
      this.announceThemeChange(theme);
    } catch (error) {
      console.error("Failed to toggle theme:", error);
      this.announceError();
    }
  }

  /**
   * Update the theme in the DOM
   * @param {string} theme - The theme to apply
   */
  updateTheme(theme) {
    const isDarkMode =
      theme === "dark" ||
      (theme === "system" &&
        window.matchMedia("(prefers-color-scheme: dark)").matches);

    document.documentElement.classList.toggle("dark", isDarkMode);
    document.documentElement.classList.toggle("light", !isDarkMode);
  }

  /**
   * Announce theme changes to screen readers
   * @param {string} theme - The new theme
   */
  announceThemeChange(theme) {
    const themeText = this.getThemeText(theme);
    announce(this.element.dataset.changedText.replace("%{theme}", themeText), {
      element: this.announcementElement,
    });
  }

  /**
   * Announce errors to screen readers
   */
  announceError() {
    announce(this.element.dataset.errorText, {
      element: this.announcementElement,
    });
  }

  /**
   * Get the target element for a given theme
   * @param {string} theme - The theme to find
   * @returns {HTMLInputElement|null} The target element or null
   */
  getTargetForTheme(theme) {
    switch (theme) {
      case "light":
        return this.lightTarget;
      case "dark":
        return this.darkTarget;
      case "system":
      default:
        return this.systemTarget;
    }
  }

  getThemeText(theme) {
    const themeMap = {
      system: this.element.dataset.systemText,
      light: this.element.dataset.lightText,
      dark: this.element.dataset.darkText,
    };
    return themeMap[theme] || theme;
  }
}
