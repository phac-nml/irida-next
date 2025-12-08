/**
 * ThemeManager - Centralized theme management for IRIDA Next
 *
 * Handles theme detection, application, and synchronization across tabs.
 * Provides a single source of truth for dark/light/system theme logic.
 *
 * @example
 * import ThemeManager from './theme-manager';
 *
 * // Initialize theme on page load
 * ThemeManager.applyTheme(ThemeManager.getCurrentTheme());
 *
 * // Change theme
 * ThemeManager.setTheme('dark');
 *
 * // Watch for system preference changes
 * ThemeManager.watchSystemPreference((isDark) => {
 *   console.log('System preference changed:', isDark);
 * });
 */

const THEME_KEY = "theme";

const THEMES = {
  DARK: "dark",
  LIGHT: "light",
  SYSTEM: "system",
};

const ALLOWED_THEMES = Object.values(THEMES);

/**
 * Check if localStorage is available
 * @returns {boolean} True if localStorage is accessible
 */
function isLocalStorageAvailable() {
  try {
    const test = "__localStorage_test__";
    localStorage.setItem(test, test);
    localStorage.removeItem(test);
    return true;
  } catch (e) {
    return false;
  }
}

/**
 * Safely get a value from localStorage
 * @param {string} key - The key to retrieve
 * @returns {string|null} The stored value or null
 */
function getFromStorage(key) {
  if (!isLocalStorageAvailable()) {
    return null;
  }
  try {
    return localStorage.getItem(key);
  } catch (e) {
    console.error("Failed to read from localStorage:", e);
    return null;
  }
}

/**
 * Safely set a value in localStorage
 * @param {string} key - The key to store
 * @param {string} value - The value to store
 * @returns {boolean} True if successful
 */
function setInStorage(key, value) {
  if (!isLocalStorageAvailable()) {
    console.warn("localStorage is not available");
    return false;
  }
  try {
    localStorage.setItem(key, value);
    return true;
  } catch (e) {
    console.error("Failed to write to localStorage:", e);
    return false;
  }
}

/**
 * Debounce a function call
 * @param {Function} func - The function to debounce
 * @param {number} wait - Milliseconds to wait
 * @returns {Function} Debounced function
 */
function debounce(func, wait) {
  let timeout;
  return function executedFunction(...args) {
    const later = () => {
      clearTimeout(timeout);
      func(...args);
    };
    clearTimeout(timeout);
    timeout = setTimeout(later, wait);
  };
}

class ThemeManager {
  static THEMES = THEMES;
  static THEME_KEY = THEME_KEY;

  /**
   * Get the current theme from localStorage
   * @returns {string} The current theme (system, light, or dark)
   */
  static getCurrentTheme() {
    const stored = getFromStorage(THEME_KEY);
    return ALLOWED_THEMES.includes(stored) ? stored : THEMES.SYSTEM;
  }

  /**
   * Set the current theme and store in localStorage
   * @param {string} theme - The theme to set
   * @returns {boolean} True if successful
   */
  static setTheme(theme) {
    if (!ALLOWED_THEMES.includes(theme)) {
      console.error(`Invalid theme: ${theme}. Must be one of:`, ALLOWED_THEMES);
      return false;
    }
    return setInStorage(THEME_KEY, theme);
  }

  /**
   * Check if the current theme is system preference
   * @param {string} [theme] - Optional theme to check, defaults to current
   * @returns {boolean} True if using system preference
   */
  static isSystemTheme(theme = null) {
    const currentTheme = theme !== null ? theme : this.getCurrentTheme();
    return currentTheme === THEMES.SYSTEM;
  }

  /**
   * Check if dark mode is currently active
   * @param {string} [theme] - Optional theme to check, defaults to current
   * @returns {boolean} True if dark mode should be active
   */
  static isDarkMode(theme = null) {
    const currentTheme = theme !== null ? theme : this.getCurrentTheme();

    if (currentTheme === THEMES.DARK) {
      return true;
    }

    if (currentTheme === THEMES.LIGHT) {
      return false;
    }

    // System preference
    return window.matchMedia("(prefers-color-scheme: dark)").matches;
  }

  /**
   * Apply theme to the document
   * @param {string} theme - The theme to apply
   * @param {boolean} withTransition - Whether to coordinate CSS transitions
   */
  static applyTheme(theme, withTransition = false) {
    const isDark = this.isDarkMode(theme);
    const docEl = document.documentElement;

    // Prevent CSS transitions during theme change to avoid flash
    if (withTransition) {
      docEl.dataset.themeTransition = "true";
    }

    // Toggle theme classes
    docEl.classList.toggle(THEMES.DARK, isDark);
    docEl.classList.toggle(THEMES.LIGHT, !isDark);

    // Update color-scheme meta tag for native browser UI
    this.updateColorSchemeMeta(isDark);

    // Dispatch custom event for other components to react
    window.dispatchEvent(
      new CustomEvent("theme-changed", {
        detail: { theme, isDark },
      }),
    );

    // Remove transition flag after CSS transitions complete
    if (withTransition) {
      setTimeout(() => {
        delete docEl.dataset.themeTransition;
      }, 300);
    }
  }

  /**
   * Update the color-scheme meta tag
   * @param {boolean} isDark - Whether dark mode is active
   */
  static updateColorSchemeMeta(isDark) {
    let meta = document.querySelector('meta[name="color-scheme"]');

    if (!meta) {
      meta = document.createElement("meta");
      meta.name = "color-scheme";
      document.head.appendChild(meta);
    }

    meta.content = isDark ? "dark" : "light";
  }

  /**
   * Watch for system preference changes
   * @param {Function} callback - Called when system preference changes
   * @returns {Function} Cleanup function to remove listener
   */
  static watchSystemPreference(callback) {
    const mediaQuery = window.matchMedia("(prefers-color-scheme: dark)");

    // Debounce to prevent rapid updates
    const debouncedCallback = debounce((e) => {
      // Only call if currently using system preference
      if (this.isSystemTheme()) {
        callback(e.matches);
      }
    }, 150);

    mediaQuery.addEventListener("change", debouncedCallback);

    // Return cleanup function
    return () => {
      mediaQuery.removeEventListener("change", debouncedCallback);
    };
  }

  /**
   * Watch for storage changes (cross-tab sync)
   * @param {Function} callback - Called when theme changes in another tab
   * @returns {Function} Cleanup function to remove listener
   */
  static watchStorageChanges(callback) {
    const handler = (event) => {
      if (event.key === THEME_KEY) {
        // Re-read theme from storage (avoid stale closure)
        const newTheme = this.getCurrentTheme();
        callback(newTheme);
      }
    };

    window.addEventListener("storage", handler);

    // Return cleanup function
    return () => {
      window.removeEventListener("storage", handler);
    };
  }

  /**
   * Initialize theme management with all watchers
   * @returns {Function} Cleanup function to remove all listeners
   */
  static initialize() {
    // Apply initial theme
    this.applyTheme(this.getCurrentTheme());

    // Set up watchers
    const cleanupSystemWatch = this.watchSystemPreference((isDark) => {
      this.applyTheme(this.getCurrentTheme(), true);
    });

    const cleanupStorageWatch = this.watchStorageChanges((theme) => {
      this.applyTheme(theme, true);
    });

    // Return combined cleanup function
    return () => {
      cleanupSystemWatch();
      cleanupStorageWatch();
    };
  }
}

export default ThemeManager;
