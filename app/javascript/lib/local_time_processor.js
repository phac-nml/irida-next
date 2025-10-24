/**
 * LocalTime Processor
 *
 * Handles locale resolution and processing of local-time elements in the DOM.
 * Supports Turbo Frame lazy loading and ensures correct translations are applied
 * based on the document's language attribute.
 *
 * @module LocalTimeProcessor
 */

/**
 * Resolves the current document locale to one that LocalTime supports
 *
 * Algorithm:
 * 1. Try the exact locale from <html lang> (e.g., "en-US")
 * 2. Try the base locale (e.g., "en" from "en-US")
 * 3. Fall back to LocalTime's defaultLocale if configured
 *
 * @param {Object} availableLocales - LocalTime.config.i18n object
 * @param {string} documentLang - Value from document.documentElement.lang
 * @param {string} [defaultLocale] - LocalTime.config.defaultLocale
 * @returns {string|null} The resolved locale or null if none found
 * @private
 */
export function resolveLocale(availableLocales, documentLang, defaultLocale) {
  const rawLocale = (documentLang || "").toLowerCase();
  const candidates = [];

  if (rawLocale) {
    candidates.push(rawLocale);
    const [baseLocale] = rawLocale.split("-");
    if (baseLocale && baseLocale !== rawLocale) {
      candidates.push(baseLocale);
    }
  } else if (defaultLocale) {
    candidates.push(defaultLocale);
  }

  return candidates.find((locale) => locale && availableLocales[locale]) || null;
}

/**
 * Processes LocalTime elements within a given root element
 *
 * This function:
 * - Finds all time[data-local] elements in the root
 * - Resolves the appropriate locale for LocalTime
 * - Configures LocalTime with the resolved locale
 * - Processes all time elements to display localized timestamps
 *
 * @param {HTMLElement|Document} [root=document] - The root element to search within
 * @returns {boolean} True if processing occurred, false otherwise
 *
 * @example
 * // Process entire document
 * processLocalTimes();
 *
 * @example
 * // Process within a specific frame
 * const frame = document.getElementById('my-turbo-frame');
 * processLocalTimes(frame);
 */
export function processLocalTimes(root = document) {
  // Guard: LocalTime library not loaded
  if (!window.LocalTime) return false;

  // Find all time elements that need processing
  const timeElements = root.querySelectorAll("time[data-local]");
  if (timeElements.length === 0) return false;

  // Resolve locale
  const availableLocales = window.LocalTime.config?.i18n || {};
  const documentLang = document.documentElement.lang;
  const defaultLocale = window.LocalTime.config?.defaultLocale;

  const resolvedLocale = resolveLocale(
    availableLocales,
    documentLang,
    defaultLocale,
  );

  // Guard: No suitable locale found
  if (!resolvedLocale) return false;

  // Configure and process
  window.LocalTime.config.locale = resolvedLocale;
  window.LocalTime.process(...timeElements);

  return true;
}

/**
 * Initializes LocalTime processing for Turbo events
 *
 * Sets up event listeners for:
 * - turbo:render - Processes entire document after page morphs
 * - turbo:frame-load - Processes within loaded frames
 * - turbo:before-stream-render - Processes within stream targets
 *
 * Call this function once during application initialization.
 *
 * @example
 * import { initializeLocalTimeProcessing } from './lib/local_time_processor';
 * initializeLocalTimeProcessing();
 */
export function initializeLocalTimeProcessing() {
  // Process entire document after Turbo renders
  document.addEventListener("turbo:render", () => {
    processLocalTimes();
  });

  // Process within Turbo Frames when they load
  document.addEventListener("turbo:frame-load", (event) => {
    const frame = event.target;
    if (frame instanceof HTMLElement) {
      processLocalTimes(frame);
    }
  });

  // Process within Turbo Stream targets
  document.addEventListener("turbo:before-stream-render", (event) => {
    const originalRender = event.detail.render;

    event.detail.render = (streamElement) => {
      originalRender(streamElement);

      // Find the target element
      const targetIdentifier =
        streamElement.target || streamElement.getAttribute?.("target");
      const target =
        streamElement.targetElement ||
        (targetIdentifier && document.getElementById(targetIdentifier)) ||
        (targetIdentifier &&
          document.querySelector(`[id="${targetIdentifier}"]`));

      processLocalTimes(target || document);
    };
  });
}
