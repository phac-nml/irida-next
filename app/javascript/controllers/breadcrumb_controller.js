// app/javascript/controllers/breadcrumb_controller.js
import { Controller } from "@hotwired/stimulus";

/**
 * 🍞 BreadcrumbController
 *
 * A responsive breadcrumb navigation that shows/hides crumbs based on available space.
 * - Always shows the last crumb (current page)
 * - Shows as many preceding crumbs as will fit
 * - Hides crumbs from first to last when space is constrained
 * - Manages dropdown items based on visible crumbs
 */
export default class extends Controller {
  static targets = ["list", "dropdownMenu"];

  // Private fields
  #resizeObserver = null;
  #CHEVRON_WIDTH = 16; // Width of the separator "›"

  connect() {
    // Use a ResizeObserver to monitor the size of the list element for greater accuracy
    this.#resizeObserver = new ResizeObserver(() => this.#calculateLayout());
    this.#resizeObserver.observe(this.listTarget);
  }

  disconnect() {
    if (this.#resizeObserver) {
      this.#resizeObserver.disconnect();
      this.#resizeObserver = null;
    }
  }

  /**
   * Calculates and applies the layout based on available space.
   * This function is designed to be idempotent and efficient.
   * @private
   */
  #calculateLayout() {
    const list = this.listTarget;
    const crumbs = Array.from(
      list.querySelectorAll('[data-breadcrumb-target="crumb"]'),
    );
    if (crumbs.length < 2) {
      this.#updateDropdown(new Set(crumbs.map((_, i) => i)));
      return; // No need to hide anything if there's only one or zero crumbs
    }

    // --- Measurement Phase ---
    // To measure crumbs accurately without causing flicker, we'll make the list
    // invisible, ensure all crumbs are displayed for measurement, then measure.
    list.style.visibility = "hidden";
    crumbs.forEach((crumb) => {
      crumb.style.display = "inline-flex";
    });
    const crumbWidths = crumbs.map((c) => c.getBoundingClientRect().width);
    const dropdownWidth = this.dropdownMenuTarget.getBoundingClientRect().width;
    list.style.visibility = ""; // Restore visibility

    // --- Calculation Phase ---
    const availableWidth = list.clientWidth;
    const lastCrumbIndex = crumbs.length - 1;
    let visibleCrumbs = new Set();

    // Pass 1: Calculate visibility assuming the dropdown is NOT present.
    let usedWidth = crumbWidths[lastCrumbIndex];
    const visibleInPass1 = new Set([lastCrumbIndex]);
    for (let i = lastCrumbIndex - 1; i >= 0; i--) {
      usedWidth += crumbWidths[i] + this.#CHEVRON_WIDTH;
      if (usedWidth <= availableWidth) {
        visibleInPass1.add(i);
      } else {
        break; // No more space
      }
    }

    // Pass 2: If any items are hidden, recalculate, allowing space for the dropdown.
    if (visibleInPass1.size < crumbs.length) {
      const availableWidthWithDropdown = availableWidth - dropdownWidth;
      usedWidth = crumbWidths[lastCrumbIndex];
      const visibleInPass2 = new Set([lastCrumbIndex]);
      for (let i = lastCrumbIndex - 1; i >= 0; i--) {
        usedWidth += crumbWidths[i] + this.#CHEVRON_WIDTH;
        if (usedWidth <= availableWidthWithDropdown) {
          visibleInPass2.add(i);
        } else {
          break; // No more space
        }
      }
      visibleCrumbs = visibleInPass2;
    } else {
      visibleCrumbs = visibleInPass1;
    }

    // --- DOM Update Phase ---
    // Apply the calculated visibility to the crumbs.
    crumbs.forEach((crumb, index) => {
      crumb.style.display = visibleCrumbs.has(index) ? "inline-flex" : "none";
    });

    this.#updateDropdown(visibleCrumbs);
  }

  /**
   * Updates the visibility of the dropdown and its items.
   * @private
   * @param {Set<number>} visibleCrumbs - Indices of visible crumbs
   */
  #updateDropdown(visibleCrumbs) {
    const dropdownItems = this.dropdownMenuTarget.querySelectorAll(
      '[data-breadcrumb-target="dropdownItem"]',
    );
    let hasHiddenItems = false;

    dropdownItems.forEach((item, index) => {
      if (visibleCrumbs.has(index)) {
        item.style.display = "none";
      } else {
        item.style.display = ""; // Use default display
        hasHiddenItems = true;
      }
    });

    // Show dropdown container if there are any hidden items
    this.dropdownMenuTarget.style.display = hasHiddenItems
      ? "inline-flex"
      : "none";
  }
}
