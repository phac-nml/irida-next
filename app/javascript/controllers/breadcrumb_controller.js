// app/javascript/controllers/controller.js
import { Controller } from "@hotwired/stimulus";

/**
 * @class BreadcrumbController
 * @classdesc 🍞 A responsive breadcrumb controller that intelligently manages
 * breadcrumb visibility based on available container width.
 *
 * This controller implements a robust, two-pass calculation strategy:
 * 1. First calculates which breadcrumbs fit without a dropdown
 * 2. If overflow occurs, recalculates with dropdown width reserved
 *
 * The algorithm ensures pixel-perfect responsiveness by temporarily
 * making all elements visible during measurement calculations.
 *
 * @extends {Controller}
 * @property {HTMLElement} listTarget - The <ol> element containing all breadcrumb items
 * @property {HTMLElement} dropdownMenuTarget - The <li> element containing the overflow dropdown menu
 */
export default class extends Controller {
  static targets = ["list", "dropdownMenu"];

  /**
   * ResizeObserver instance that monitors container size changes
   * and triggers layout recalculation when needed.
   * @type {ResizeObserver|null}
   * @private
   */
  #resizeObserver = null;

  /**
   * Initializes the controller and sets up the ResizeObserver
   * to monitor container width changes.
   * @public
   */
  connect() {
    this.#resizeObserver = new ResizeObserver(() => this.#updateLayout());
    this.#resizeObserver.observe(this.listTarget);
  }

  /**
   * Cleans up the ResizeObserver when the controller is disconnected.
   * @public
   */
  disconnect() {
    if (this.#resizeObserver) {
      this.#resizeObserver.disconnect();
      this.#resizeObserver = null;
    }
  }

  /**
   * Orchestrates the responsive layout calculation and DOM updates.
   *
   * This method:
   * 1. Retrieves all breadcrumb elements
   * 2. Measures their dimensions
   * 3. Calculates which items should be visible
   * 4. Renders the final layout
   *
   * Called automatically by the ResizeObserver when container size changes.
   * @private
   */
  #updateLayout() {
    const crumbs = Array.from(
      this.listTarget.querySelectorAll('[data-breadcrumb-target="crumb"]'),
    );

    if (crumbs.length < 2) {
      this.#updateDropdown(new Set()); // Hide dropdown if insufficient items
      return;
    }

    const measurements = this.#measureElements(crumbs);
    const visibleSet = this.#calculateVisibleSet(measurements);
    this.#render(crumbs, visibleSet);
  }

  /**
   * Measures the dimensions of breadcrumb elements and container.
   *
   * Temporarily makes all breadcrumbs visible and removes truncation
   * from the last item to get accurate measurements.
   *
   * @param {HTMLElement[]} crumbs - Array of breadcrumb <li> elements
   * @returns {{crumbWidths: number[], dropdownWidth: number, availableWidth: number}} Measurement data
   * @private
   */
  #measureElements(crumbs) {
    crumbs.forEach((crumb) => {
      crumb.classList.remove("hidden");
    });
    const lastCrumbIndex = crumbs.length - 1;
    const lastCrumb = crumbs[lastCrumbIndex];
    lastCrumb.classList.remove("truncate");

    const crumbWidths = crumbs.map((c) => c.getBoundingClientRect().width);
    const dropdownWidth = this.dropdownMenuTarget.getBoundingClientRect().width;

    return {
      crumbWidths,
      dropdownWidth,
      availableWidth: this.listTarget.getBoundingClientRect().width,
    };
  }

  /**
   * Calculates which breadcrumbs can fit within the available width.
   *
   * Uses a two-pass algorithm:
   * 1. First pass: Assumes no dropdown is needed, calculates what fits
   * 2. Second pass: If overflow detected, recalculates with dropdown width reserved
   *
   * Always keeps the last breadcrumb visible as it represents the current page.
   *
   * @param {object} measurements - The measurement data object
   * @param {number[]} measurements.crumbWidths - Width of each breadcrumb element
   * @param {number} measurements.dropdownWidth - Width of the dropdown menu
   * @param {number} measurements.availableWidth - Total available container width
   * @returns {Set<number>} Set containing indices of breadcrumbs that should be visible
   * @private
   */
  #calculateVisibleSet({ crumbWidths, dropdownWidth, availableWidth }) {
    const lastCrumbIndex = crumbWidths.length - 1;
    const calculate = (width, visibleSet) => {
      let usedWidth = crumbWidths[lastCrumbIndex];
      visibleSet.add(lastCrumbIndex);
      for (let i = lastCrumbIndex - 1; i >= 0; i--) {
        usedWidth += crumbWidths[i];
        if (usedWidth < width) {
          visibleSet.add(i);
        } else {
          break;
        }
      }
    };

    const initialVisibleSet = new Set();
    calculate(availableWidth, initialVisibleSet);

    if (initialVisibleSet.size < crumbWidths.length) {
      const finalVisibleSet = new Set();
      calculate(availableWidth - dropdownWidth, finalVisibleSet);
      return finalVisibleSet;
    }

    return initialVisibleSet;
  }

  /**
   * Applies the calculated visibility layout to the DOM.
   *
   * Updates breadcrumb visibility, handles last item truncation when it's
   * the only visible item, and manages the dropdown menu state.
   *
   * @param {HTMLElement[]} crumbs - Array of breadcrumb <li> elements
   * @param {Set<number>} visibleSet - Set containing indices of visible breadcrumbs
   * @private
   */
  #render(crumbs, visibleSet) {
    // Update visibility of each crumb
    crumbs.forEach((crumb, index) => {
      crumb.classList.toggle("hidden", !visibleSet.has(index));
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
      lastCrumb.classList.toggle("truncate", isOnlyCrumbVisible);

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
   * Updates the dropdown menu visibility and content based on hidden breadcrumbs.
   *
   * Shows dropdown items for breadcrumbs that are hidden in the main navigation.
   * The dropdown itself is only visible when there are hidden items to display.
   *
   * @param {Set<number>} visibleSet - Set containing indices of visible breadcrumbs
   * @private
   */
  #updateDropdown(visibleSet) {
    const dropdownItems =
      this.dropdownMenuTarget.querySelectorAll('[role="menuitem"]');
    let hasHiddenItems = false;

    dropdownItems.forEach((item, index) => {
      const isVisible = !visibleSet.has(index);
      item.classList.toggle("hidden", !isVisible);
      if (isVisible) {
        hasHiddenItems = true;
      }
    });

    this.dropdownMenuTarget.classList.toggle("hidden", !hasHiddenItems);
    this.dropdownMenuTarget.classList.toggle("inline-flex", hasHiddenItems);
  }
}
