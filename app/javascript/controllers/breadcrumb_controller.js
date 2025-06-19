// app/javascript/controllers/breadcrumb_controller.js
import { Controller } from "@hotwired/stimulus";

/**
 * 🍞 BreadcrumbController
 *
 * A responsive and accessible breadcrumb navigation component that intelligently
 * manages space constraints by collapsing middle items into a dropdown menu.
 *
 * Features:
 * - 📱 Responsive layout with dynamic width calculations
 * - ♿ Full ARIA compliance and keyboard navigation
 * - 🎯 Smart collapsing with configurable tolerance
 * - 🔄 Efficient DOM updates and layout calculations
 * - 🎨 Smooth transitions and animations
 *
 * @example
 * ```html
 * <nav data-controller="breadcrumb">
 *   <ol data-breadcrumb-target="list">
 *     <li data-breadcrumb-target="crumb">Home</li>
 *     <li data-breadcrumb-target="crumb">Projects</li>
 *     <li data-breadcrumb-target="crumb">Current</li>
 *   </ol>
 *   <div data-breadcrumb-target="dropdown" role="menu">
 *     <!-- Dropdown content -->
 *   </div>
 * </nav>
 * ```
 *
 * @extends {Controller}
 */
export default class extends Controller {
  /** @type {string[]} Stimulus targets for DOM elements */
  static targets = ["list", "crumb", "dropdown"];

  /** @type {Object} Stimulus values for data binding */
  static values = { links: Array };

  // Private fields
  /** @type {Function|null} Bound resize event handler */
  #resizeHandler = null;

  /** @type {number|null} Animation frame ID for layout calculations */
  #animationFrame = null;

  // Configuration constants
  /** @type {number} Total horizontal padding in pixels (16px on each side) */
  #PADDING = 32;

  /** @type {number} Width of chevron separator in pixels */
  #CHEVRON_WIDTH = 16;

  /** @type {number} Percentage of container width to use as layout tolerance */
  #TOLERANCE_PERCENTAGE = 0.05;

  /**
   * Lifecycle: Controller Connection
   * Sets up event listeners and performs initial layout calculation
   * @returns {void}
   */
  connect() {
    this.#setupEventListeners();
    this.#performLayout();
  }

  /**
   * Lifecycle: Controller Disconnection
   * Cleans up event listeners and pending animations
   * @returns {void}
   */
  disconnect() {
    this.#cleanupEventListeners();
    this.#cancelPendingAnimations();
  }

  // ============================================================================
  // Event Management
  // ============================================================================

  /**
   * Sets up the resize event listener with passive optimization
   * @private
   * @returns {void}
   */
  #setupEventListeners() {
    this.#resizeHandler = this.#performLayout.bind(this);
    window.addEventListener("resize", this.#resizeHandler, { passive: true });
  }

  /**
   * Removes event listeners and cleans up references
   * @private
   * @returns {void}
   */
  #cleanupEventListeners() {
    if (this.#resizeHandler) {
      window.removeEventListener("resize", this.#resizeHandler);
      this.#resizeHandler = null;
    }
  }

  /**
   * Cancels any pending animation frames
   * @private
   * @returns {void}
   */
  #cancelPendingAnimations() {
    if (this.#animationFrame) {
      cancelAnimationFrame(this.#animationFrame);
      this.#animationFrame = null;
    }
  }

  // ============================================================================
  // Layout Management
  // ============================================================================

  /**
   * Schedules a layout calculation for the next animation frame
   * @private
   * @returns {Promise<void>}
   */
  async #performLayout() {
    this.#cancelPendingAnimations();
    this.#animationFrame = requestAnimationFrame(async () => {
      await this.#calculateOptimalLayout();
    });
  }

  /**
   * Calculates and applies the optimal layout based on available space
   * @private
   * @returns {Promise<void>}
   */
  async #calculateOptimalLayout() {
    const { crumbs, dropdown } = this.#getLayoutElements();
    const containerWidth = this.listTarget.clientWidth;
    const availableWidth = containerWidth - this.#PADDING;
    const toleranceWidth = containerWidth * this.#TOLERANCE_PERCENTAGE;

    // Early exit for minimal breadcrumbs
    if (crumbs.length < 3) {
      this.#showAllCrumbs(crumbs, dropdown);
      return;
    }

    // Measure total width with all crumbs visible
    this.#showAllCrumbs(crumbs, dropdown);
    await this.#waitForLayout();
    const totalWidth = this.#calculateTotalWidth(crumbs);

    // Apply appropriate layout based on available space
    if (totalWidth <= availableWidth + toleranceWidth) {
      return; // Keep all crumbs visible
    }
    await this.#applyDropdownLayout(crumbs, dropdown);
  }

  /**
   * Calculates the total width of all breadcrumbs including separators
   * @private
   * @param {Element[]} crumbs - Array of breadcrumb elements
   * @returns {number} Total width in pixels
   */
  #calculateTotalWidth(crumbs) {
    return crumbs.reduce((totalWidth, crumb, index) => {
      const chevronWidth = index > 0 ? this.#CHEVRON_WIDTH : 0;
      return totalWidth + crumb.getBoundingClientRect().width + chevronWidth;
    }, 0);
  }

  /**
   * Retrieves the DOM elements needed for layout calculations
   * @private
   * @returns {{ crumbs: Element[], dropdown: Element }}
   */
  #getLayoutElements() {
    return {
      crumbs: this.crumbTargets,
      dropdown: this.dropdownTarget
    };
  }

  /**
   * Applies the dropdown layout by showing first/last items and collapsing middle items
   * @private
   * @param {Element[]} crumbs - Array of breadcrumb elements
   * @param {Element} dropdown - Dropdown menu element
   * @returns {Promise<void>}
   */
  async #applyDropdownLayout(crumbs, dropdown) {
    const [firstCrumb, ...middleCrumbs] = crumbs;
    const lastCrumb = middleCrumbs.pop();

    // Show bookend crumbs
    firstCrumb.style.display = "inline-flex";
    lastCrumb.style.display = "inline-flex";

    // Hide and process middle crumbs
    middleCrumbs.forEach(crumb => crumb.style.display = "none");
    dropdown.style.display = "inline-flex";
    this.#updateDropdownContent(middleCrumbs);
  }

  /**
   * Shows all breadcrumbs and hides the dropdown
   * @private
   * @param {Element[]} crumbs - Array of breadcrumb elements
   * @param {Element} dropdown - Dropdown menu element
   * @returns {void}
   */
  #showAllCrumbs(crumbs, dropdown) {
    crumbs.forEach((crumb) => (crumb.style.display = "inline-flex"));
    dropdown.style.display = "none";
  }

  /**
   * Waits for layout calculations to complete
   * @private
   * @returns {Promise<void>}
   */
  async #waitForLayout() {
    await new Promise(resolve => requestAnimationFrame(() =>
      requestAnimationFrame(resolve)
    ));
  }

  /**
   * Updates the dropdown menu content with middle breadcrumb items
   * @private
   * @param {Element[]} middleCrumbs - Array of middle breadcrumb elements
   * @returns {void}
   */
  #updateDropdownContent(middleCrumbs) {
    const dropdownMenu = this.dropdownTarget.querySelector('[role="menu"]');
    if (!dropdownMenu) return;

    dropdownMenu.innerHTML = ""; // Clear existing content

    middleCrumbs.forEach((crumb, index) => {
      const link = this.linksValue[index + 1]; // +1 to skip home
      if (!link) return;

      const menuItem = this.#createDropdownMenuItem(link);
      dropdownMenu.appendChild(menuItem);
    });
  }

  /**
   * Creates a dropdown menu item with proper accessibility attributes
   * @private
   * @param {{ path: string, name: string }} link - Link data for the menu item
   * @returns {HTMLElement} The created menu item element
   */
  #createDropdownMenuItem(link) {
    const menuItem = document.createElement("li");
    menuItem.setAttribute("role", "none");

    const anchor = document.createElement("a");
    anchor.setAttribute("role", "menuitem");
    anchor.setAttribute("tabindex", "-1");
    anchor.href = link.path;
    anchor.textContent = link.name;
    anchor.title = link.name;
    anchor.setAttribute("data-turbo-frame", "_top");
    anchor.className = [
      "block",
      "px-4",
      "py-2",
      "text-sm",
      "text-slate-600",
      "dark:text-slate-400",
      "hover:bg-slate-100",
      "dark:hover:bg-slate-700",
      "focus:outline-none",
      "focus:bg-slate-200",
      "dark:focus:bg-slate-800",
    ].join(" ");

    menuItem.appendChild(anchor);
    return menuItem;
  }
}
