// app/javascript/controllers/breadcrumb_controller.js
import { Controller } from "@hotwired/stimulus";

/**
 * @class BreadcrumbController
 * @classdesc 🍞 A responsive breadcrumb controller that intelligently hides
 * and shows breadcrumb items based on the available container width.
 *
 * This controller implements a robust, two-pass calculation strategy to ensure
 * pixel-perfect responsiveness without visual flicker.
 *
 * @property {HTMLElement} listTarget - The <ol> element containing the breadcrumbs.
 * @property {HTMLElement} dropdownMenuTarget - The <li> element that contains the overflow dropdown.
 */
export default class extends Controller {
  static targets = ["list", "dropdownMenu"];

  /**
   * The pixel width of the "›" separator between breadcrumbs.
   * @type {number}
   * @private
   */
  #CHEVRON_WIDTH = 16;

  /**
   * A small pixel buffer to prevent the breadcrumbs from appearing
   * too crowded before they collapse into the dropdown.
   * @type {number}
   * @private
   */
  #WIDTH_BUFFER = 20; // 20px of breathing room

  /**
   * The observer that triggers recalculation when the element size changes.
   * @type {ResizeObserver|null}
   * @private
   */
  #resizeObserver = null;

  connect() {
    this.#resizeObserver = new ResizeObserver(() => this.#updateLayout());
    this.#resizeObserver.observe(this.listTarget);
  }

  disconnect() {
    if (this.#resizeObserver) {
      this.#resizeObserver.disconnect();
      this.#resizeObserver = null;
    }
  }

  /**
   * Orchestrates the responsive layout calculation and DOM updates.
   * This is the entry point called by the ResizeObserver.
   * @private
   */
  #updateLayout() {
    const crumbs = Array.from(
      this.listTarget.querySelectorAll('[data-breadcrumb-target="crumb"]'),
    );

    if (crumbs.length < 2) {
      this.#updateDropdown(new Set()); // Hide all dropdown items if only 1 crumb
      return;
    }

    const measurements = this.#measureElements(crumbs);
    const visibleSet = this.#calculateVisibleSet(measurements);
    this.#render(crumbs, visibleSet);
  }

  /**
   * Measures the widths of all breadcrumbs, the dropdown, and the container.
   * It temporarily makes all crumbs visible to get accurate measurements without
   * causing visual flicker by using the `visibility` CSS property.
   *
   * @param {HTMLElement[]} crumbs - An array of the breadcrumb <li> elements.
   * @returns {{crumbWidths: number[], dropdownWidth: number, availableWidth: number}}
   * @private
   */
  #measureElements(crumbs) {
    this.listTarget.style.visibility = "hidden";
    crumbs.forEach((crumb) => {
      crumb.style.display = "inline-flex";
    });

    const crumbWidths = crumbs.map((c) => c.getBoundingClientRect().width);
    const dropdownWidth = this.dropdownMenuTarget.getBoundingClientRect().width;

    this.listTarget.style.visibility = ""; // Restore visibility

    return {
      crumbWidths,
      dropdownWidth,
      availableWidth: this.listTarget.clientWidth,
    };
  }

  /**
   * Calculates which breadcrumbs can be visible within the available width.
   * It performs a two-pass calculation:
   * 1. Assume the dropdown isn't needed and see what fits.
   * 2. If anything was hidden, recalculate with the dropdown's width included.
   *
   * @param {object} measurements - The measurement data.
   * @param {number[]} measurements.crumbWidths - Width of each crumb.
   * @param {number} measurements.dropdownWidth - Width of the dropdown.
   * @param {number} measurements.availableWidth - The container's width.
   * @returns {Set<number>} A Set containing the indices of visible crumbs.
   * @private
   */
  #calculateVisibleSet({ crumbWidths, dropdownWidth, availableWidth }) {
    const lastCrumbIndex = crumbWidths.length - 1;
    const calculate = (width, visibleSet) => {
      let usedWidth = crumbWidths[lastCrumbIndex];
      visibleSet.add(lastCrumbIndex);
      for (let i = lastCrumbIndex - 1; i >= 0; i--) {
        usedWidth += crumbWidths[i] + this.#CHEVRON_WIDTH;
        if (usedWidth <= width) {
          visibleSet.add(i);
        } else {
          break;
        }
      }
    };

    const initialVisibleSet = new Set();
    calculate(availableWidth - this.#WIDTH_BUFFER, initialVisibleSet);

    if (initialVisibleSet.size < crumbWidths.length) {
      const finalVisibleSet = new Set();
      calculate(
        availableWidth - dropdownWidth - this.#WIDTH_BUFFER,
        finalVisibleSet,
      );
      return finalVisibleSet;
    }

    return initialVisibleSet;
  }

  /**
   * Applies the calculated layout to the DOM, updating visibility and styles.
   *
   * @param {HTMLElement[]} crumbs - An array of the breadcrumb <li> elements.
   * @param {Set<number>} visibleSet - A Set containing the indices of visible crumbs.
   * @private
   */
  #render(crumbs, visibleSet) {
    // Update visibility of each crumb
    crumbs.forEach((crumb, index) => {
      crumb.style.display = visibleSet.has(index) ? "inline-flex" : "none";
    });

    // Handle truncation for the last crumb
    const lastCrumbIndex = crumbs.length - 1;
    const lastCrumb = crumbs[lastCrumbIndex];
    const lastCrumbTextElement = lastCrumb.querySelector(
      "span[aria-current='page']",
    );

    if (lastCrumbTextElement) {
      const isOnlyCrumbVisible =
        visibleSet.size === 1 && visibleSet.has(lastCrumbIndex);
      lastCrumb.classList.toggle("min-w-0", isOnlyCrumbVisible);
      lastCrumb.classList.toggle("shrink-0", !isOnlyCrumbVisible);
      lastCrumbTextElement.classList.toggle("truncate", isOnlyCrumbVisible);

      if (isOnlyCrumbVisible) {
        lastCrumbTextElement.setAttribute(
          "title",
          lastCrumbTextElement.textContent.trim(),
        );
      }
    }

    this.#updateDropdown(visibleSet);
  }

  /**
   * Updates the visibility of the dropdown menu and its items.
   *
   * @param {Set<number>} visibleSet - A Set containing the indices of visible crumbs.
   * @private
   */
  #updateDropdown(visibleSet) {
    const dropdownItems = this.dropdownMenuTarget.querySelectorAll(
      '[data-breadcrumb-target="dropdownItem"]',
    );
    let hasHiddenItems = false;

    dropdownItems.forEach((item, index) => {
      const isVisible = !visibleSet.has(index);
      item.style.display = isVisible ? "" : "none";
      if (isVisible) {
        hasHiddenItems = true;
      }
    });

    this.dropdownMenuTarget.style.display = hasHiddenItems
      ? "inline-flex"
      : "none";
  }
}
