/**
 * Utility helpers for managing ARIA live regions for screen reader announcements.
 *
 * These helpers provide a consistent way to announce dynamic content changes
 * to assistive technology users across all controllers.
 *
 * @see LiveRegionComponent for the server-rendered counterpart
 */

/** Default ID for the global fallback live region */
export const GLOBAL_LIVE_REGION_ID = "sr-status";

/**
 * Announces a message to screen readers via an ARIA live region.
 *
 * Prioritizes announcement targets in order:
 * 1. The provided element (e.g., a Stimulus target)
 * 2. A global live region with the default ID
 * 3. Creates a new global live region if none exists
 *
 * @param {string} message - The message to announce to screen readers
 * @param {Object} options - Configuration options
 * @param {HTMLElement|null} options.element - Preferred element to use for announcement
 * @param {string} options.politeness - ARIA live politeness level: "polite" or "assertive"
 * @returns {void}
 *
 * @example
 * // Using a Stimulus target
 * announce("Item added", { element: this.statusTarget });
 *
 * @example
 * // Using global fallback
 * announce("Form submitted successfully");
 *
 * @example
 * // Assertive announcement for errors
 * announce("Validation error", { politeness: "assertive" });
 */
export function announce(
  message,
  { element = null, politeness = "polite" } = {},
) {
  if (!message) return;

  const region = element || findOrCreateGlobalRegion(politeness);
  region.textContent = message;
}

/**
 * Finds an existing global live region or creates one if it doesn't exist.
 *
 * @param {string} politeness - ARIA live politeness level for newly created regions
 * @returns {HTMLElement} The live region element
 */
export function findOrCreateGlobalRegion(politeness = "polite") {
  const existing = document.querySelector(`#${GLOBAL_LIVE_REGION_ID}`);
  if (existing) return existing;

  return createLiveRegion({ id: GLOBAL_LIVE_REGION_ID, politeness });
}

/**
 * Creates a new ARIA live region element and appends it to the document body.
 *
 * @param {Object} options - Configuration options
 * @param {string} options.id - The ID for the live region element
 * @param {string} options.politeness - ARIA live politeness level: "polite" or "assertive"
 * @param {boolean} options.atomic - Whether the region should be announced as a whole
 * @returns {HTMLElement} The created live region element
 */
export function createLiveRegion({
  id = GLOBAL_LIVE_REGION_ID,
  politeness = "polite",
  atomic = true,
} = {}) {
  const region = document.createElement("div");
  region.id = id;
  region.setAttribute("role", "status");
  region.setAttribute("aria-live", politeness);
  if (atomic) {
    region.setAttribute("aria-atomic", "true");
  }
  region.className = "sr-only";
  document.body.appendChild(region);
  return region;
}

/**
 * Clears the content of a live region.
 * Useful when you need to reset the region before a new announcement.
 *
 * @param {HTMLElement|null} element - The live region element to clear
 * @returns {void}
 */
export function clearLiveRegion(element = null) {
  const region = element || document.querySelector(`#${GLOBAL_LIVE_REGION_ID}`);
  if (region) {
    region.textContent = "";
  }
}
