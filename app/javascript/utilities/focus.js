/**
 * Checks if an element is visible in the DOM.
 * An element is considered visible if it is:
 * - Connected to the DOM
 * - Has an offsetParent (not hidden via CSS)
 * - Not display:none, visibility:hidden, or opacity:0
 * - Has client rects (has dimensions and is rendered)
 *
 * @param {HTMLElement} element - The element to check for visibility
 * @returns {boolean} True if the element is visible, false otherwise
 */
export function isVisible(element) {
  if (!element.isConnected || !element.offsetParent) return false;

  const style = window.getComputedStyle(element);
  if (
    style.display === "none" ||
    style.visibility === "hidden" ||
    style.opacity === "0"
  ) {
    return false;
  }

  return element.getClientRects().length > 0;
}

/**
 * Focuses an element once it becomes visible in the DOM.
 * Useful for focusing elements during CSS transitions or animations.
 * Uses requestAnimationFrame to efficiently poll for visibility.
 *
 * @param {HTMLElement} element - The element to focus
 * @param {Object} options - Configuration options
 * @param {number} options.maxFrames - Maximum animation frames to wait (default: 30, ~500ms at 60fps)
 * @param {FocusOptions} options.focusOptions - Options forwarded to HTMLElement.focus()
 *   (e.g. `{ focusVisible: true }` to force the visible focus indicator after a pointer-initiated action).
 * @returns {void}
 *
 * @example
 * // Focus a button after expanding a menu
 * focusWhenVisible(menuButton);
 *
 * @example
 * // Focus with custom timeout
 * focusWhenVisible(dialogCloseButton, { maxFrames: 60 });
 *
 * @example
 * // Force the visible focus indicator (e.g. when activating an error summary link)
 * focusWhenVisible(target, { focusOptions: { focusVisible: true } });
 */
export function focusWhenVisible(
  element,
  { maxFrames = 30, focusOptions } = {},
) {
  // maxFrames = 30 ≈ 500ms at 60fps - prevents infinite loop during CSS transitions
  if (!element) return;

  let frameCount = 0;

  const attempt = () => {
    if (isVisible(element)) {
      element.focus(focusOptions);
      return;
    }

    frameCount += 1;
    if (frameCount < maxFrames) {
      window.requestAnimationFrame(attempt);
    }
  };

  window.requestAnimationFrame(attempt);
}
