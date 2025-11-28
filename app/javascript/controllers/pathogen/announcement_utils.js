/**
 * Pathogen Announcement Utility
 *
 * Shared utility module for screen reader announcements across pathogen controllers.
 * Provides a consistent API for creating temporary aria-live regions and announcing
 * messages to assistive technology users.
 *
 * @module pathogen/announcement_utils
 *
 * @example
 * import { announce } from './announcement_utils';
 *
 * // Basic announcement (polite)
 * announce('Dialog opened');
 *
 * // Assertive announcement (for errors, warnings)
 * announce('Error occurred', { politeness: 'assertive' });
 *
 * // With cleanup tracking
 * const cleanup = announce('Processing...', { trackCleanup: true });
 * // Later: cleanup(); // Manually cleanup if needed
 */

// Default cleanup delay (ms) - time to wait before removing announcement element
const DEFAULT_CLEANUP_DELAY = 1000;

// Track active announcements for manual cleanup
const activeAnnouncements = new Set();

/**
 * Creates a temporary aria-live region and announces a message to screen readers.
 *
 * @param {string} message - The message to announce (or I18n key if resolveI18n is true)
 * @param {Object} options - Configuration options
 * @param {string} [options.politeness='polite'] - ARIA live politeness level ('polite' | 'assertive' | 'off')
 * @param {boolean} [options.atomic=true] - Whether the region should be treated as atomic
 * @param {number} [options.cleanupDelay=DEFAULT_CLEANUP_DELAY] - Delay before removing element (ms)
 * @param {boolean} [options.trackCleanup=false] - Whether to return cleanup function for manual tracking
 * @param {Function} [options.resolveI18n] - Optional function to resolve I18n keys to messages
 * @returns {Function|void} Cleanup function if trackCleanup is true, otherwise void
 */
export function announce(message, options = {}) {
  const {
    politeness = "polite",
    atomic = true,
    cleanupDelay = DEFAULT_CLEANUP_DELAY,
    trackCleanup = false,
    resolveI18n = null,
  } = options;

  // Resolve I18n key if resolver provided
  const resolvedMessage = resolveI18n ? resolveI18n(message) : message;

  if (!resolvedMessage) {
    return trackCleanup ? () => {} : undefined;
  }

  try {
    // Create announcement element
    const announcement = document.createElement("div");
    announcement.setAttribute("aria-live", politeness);
    announcement.setAttribute("aria-atomic", String(atomic));
    announcement.className = "sr-only";
    announcement.textContent = resolvedMessage;

    // Add to page for screen readers
    document.body.appendChild(announcement);

    // Create cleanup function
    const cleanup = () => {
      try {
        if (announcement.parentNode) {
          document.body.removeChild(announcement);
        }
        if (trackCleanup) {
          activeAnnouncements.delete(cleanup);
        }
      } catch (error) {
        console.warn(
          "[pathogen/announcement_utils] Failed to remove announcement element:",
          error,
        );
      }
    };

    // Track cleanup if requested
    if (trackCleanup) {
      activeAnnouncements.add(cleanup);
    }

    // Schedule automatic cleanup
    const timeoutId = setTimeout(cleanup, cleanupDelay);

    // Return cleanup function if tracking requested
    if (trackCleanup) {
      return () => {
        clearTimeout(timeoutId);
        cleanup();
      };
    }
  } catch (error) {
    console.error(
      "[pathogen/announcement_utils] Failed to create announcement:",
      error,
    );
    return trackCleanup ? () => {} : undefined;
  }
}

/**
 * Cleans up all tracked announcements.
 * Useful for cleanup on page navigation or controller disconnect.
 */
export function cleanupAll() {
  activeAnnouncements.forEach((cleanup) => cleanup());
  activeAnnouncements.clear();
}
