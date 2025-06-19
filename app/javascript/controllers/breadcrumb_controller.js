// app/javascript/controllers/breadcrumb_controller.js
import { Controller } from "@hotwired/stimulus";

/**
 * 🍞 Accessible Breadcrumb Controller
 *
 * Provides intelligent, responsive breadcrumb navigation that automatically
 * collapses middle items into a dropdown when space is constrained.
 *
 * Features:
 * - 📱 Responsive: Adapts to container width changes
 * - ♿ Accessible: Full keyboard and screen reader support
 * - 🎯 Smart Collapsing: Always shows Home + dropdown + trailing items
 * - 🎨 Smooth Animations: Fade-in/out transitions
 * - 🔧 Maintainable: Clear separation of concerns
 *
 * @example
 * <nav data-controller="breadcrumb" data-breadcrumb-links-value="[...]">
 *   <ol data-breadcrumb-target="list">
 *     <li data-breadcrumb-target="crumb">Home</li>
 *     <li data-breadcrumb-target="crumb">Projects</li>
 *     <li data-breadcrumb-target="crumb">My Project</li>
 *     <li data-breadcrumb-target="dropdown">
 *       <button aria-haspopup="true" aria-expanded="false">
 *         <span aria-hidden="true">⋯</span>
 *       </button>
 *       <ul role="menu"></ul>
 *     </li>
 *   </ol>
 * </nav>
 */
export default class extends Controller {
  // 🎯 Stimulus targets and values
  static targets = ["list", "crumb", "dropdown"];
  static values = { links: Array };

  // 📏 Layout configuration
  static classes = ["animate"];

  // 🔧 Private properties
  #resizeHandler = null;
  #animationFrame = null;

  /**
   * 🚀 Initialize the breadcrumb controller
   * Sets up event listeners and performs initial layout calculation
   */
  connect() {
    this.#setupEventListeners();
    this.#performLayout();
  }

  /**
   * 🧹 Clean up resources when controller disconnects
   * Removes event listeners and cancels pending animations
   */
  disconnect() {
    this.#cleanupEventListeners();
    this.#cancelPendingAnimations();
  }

  // ============================================================================
  // 🎯 PUBLIC METHODS
  // ============================================================================

  /**
   * 🔄 Trigger manual layout recalculation
   * Useful for programmatic updates or testing
   */
  recalculate() {
    this.#performLayout();
  }

  // ============================================================================
  // 🔧 PRIVATE SETUP & CLEANUP METHODS
  // ============================================================================

  /**
   * 📡 Set up event listeners for responsive behavior
   */
  #setupEventListeners() {
    this.#resizeHandler = this.#performLayout.bind(this);
    window.addEventListener("resize", this.#resizeHandler, { passive: true });
  }

  /**
   * 🧹 Remove event listeners to prevent memory leaks
   */
  #cleanupEventListeners() {
    if (this.#resizeHandler) {
      window.removeEventListener("resize", this.#resizeHandler);
      this.#resizeHandler = null;
    }
  }

  /**
   * ⏹️ Cancel any pending animation frames
   */
  #cancelPendingAnimations() {
    if (this.#animationFrame) {
      cancelAnimationFrame(this.#animationFrame);
      this.#animationFrame = null;
    }
  }

  // ============================================================================
  // 📐 LAYOUT CALCULATION METHODS
  // ============================================================================

  /**
   * 🎯 Main layout orchestration method
   * Coordinates the entire breadcrumb layout process
   */
  async #performLayout() {
    this.#cancelPendingAnimations();

    this.#animationFrame = requestAnimationFrame(async () => {
      await this.#calculateOptimalLayout();
    });
  }

  /**
   * 🧮 Calculate the optimal breadcrumb layout
   * Determines which crumbs to show/hide based on available space
   */
  async #calculateOptimalLayout() {
    const { crumbs, dropdown, container, availableWidth } =
      this.#getLayoutElements();

    // 🚫 Early exit for minimal breadcrumbs
    if (this.#shouldSkipDropdown(crumbs)) {
      this.#showAllCrumbs(crumbs, dropdown);
      return;
    }

    // 📏 Try to fit all crumbs without dropdown first
    if (await this.#canFitAllCrumbs(crumbs, availableWidth)) {
      this.#showAllCrumbs(crumbs, dropdown);
      return;
    }

    // 🎯 Use dropdown strategy for space-constrained layouts
    await this.#applyDropdownLayout(crumbs, dropdown, availableWidth);
  }

  /**
   * 🎯 Get all necessary DOM elements for layout calculations
   */
  #getLayoutElements() {
    const crumbs = this.crumbTargets;
    const dropdown = this.dropdownTarget;
    const container = this.listTarget;
    const availableWidth = container.clientWidth - 16; // Account for padding

    return { crumbs, dropdown, container, availableWidth };
  }

  /**
   * ❌ Determine if dropdown should be skipped entirely
   */
  #shouldSkipDropdown(crumbs) {
    return crumbs.length < 3;
  }

  /**
   * 📏 Check if all crumbs can fit without dropdown
   */
  async #canFitAllCrumbs(crumbs, availableWidth) {
    // 🎭 Temporarily show all crumbs to measure
    this.#showAllCrumbs(crumbs, this.dropdownTarget);
    await this.#waitForLayout();

    const totalWidth = this.#calculateTotalWidth(crumbs);
    return totalWidth <= availableWidth;
  }

  /**
   * 🎯 Apply dropdown-based layout strategy
   */
  async #applyDropdownLayout(crumbs, dropdown, availableWidth) {
    const dropdownWidth = await this.#measureDropdownWidth(dropdown);
    console.log(dropdownWidth);
    const { firstWidth, lastWidth } = this.#getEndCrumbWidths(crumbs);

    // 📐 Calculate available space for middle crumbs
    const middleSpace = availableWidth - firstWidth - lastWidth - dropdownWidth;

    // 🎯 Determine which middle crumbs to show
    const visibleMiddleIndexes = this.#calculateVisibleMiddleCrumbs(
      crumbs,
      middleSpace,
    );

    // 🎨 Apply the calculated layout
    this.#applyCalculatedLayout(crumbs, dropdown, visibleMiddleIndexes);
  }

  // ============================================================================
  // 📏 MEASUREMENT & CALCULATION METHODS
  // ============================================================================

  /**
   * 📐 Calculate total width of all crumbs
   */
  #calculateTotalWidth(crumbs) {
    return crumbs.reduce((total, crumb) => {
      return total + crumb.getBoundingClientRect().width;
    }, 0);
  }

  /**
   * 📏 Get widths of first and last crumbs
   */
  #getEndCrumbWidths(crumbs) {
    const firstCrumb = crumbs[0];
    const lastCrumb = crumbs[crumbs.length - 1];

    return {
      firstWidth: firstCrumb.getBoundingClientRect().width,
      lastWidth: lastCrumb.getBoundingClientRect().width,
    };
  }

  /**
   * 📏 Measure dropdown width for layout calculations
   */
  async #measureDropdownWidth(dropdown) {
    dropdown.style.display = "block";
    dropdown.style.visibility = "hidden";
    await this.#waitForLayout();

    const width = dropdown.getBoundingClientRect().width;
    dropdown.style.visibility = "";

    return width;
  }

  /**
   * 🎯 Calculate which middle crumbs can be shown
   * Uses a greedy algorithm from both ends
   */
  #calculateVisibleMiddleCrumbs(crumbs, availableSpace) {
    const visibleIndexes = [];
    let usedSpace = 0;

    // 🎯 Start from both ends and work inward
    let leftIndex = 1;
    let rightIndex = crumbs.length - 2;

    while (leftIndex <= rightIndex && usedSpace < availableSpace) {
      // 🎯 Try left side first
      const leftCrumb = crumbs[leftIndex];
      const leftWidth = leftCrumb.getBoundingClientRect().width;

      if (usedSpace + leftWidth <= availableSpace) {
        visibleIndexes.push(leftIndex);
        usedSpace += leftWidth;
        leftIndex++;
      } else {
        break;
      }

      // 🎯 Try right side if we have more space and crumbs
      if (leftIndex <= rightIndex && usedSpace < availableSpace) {
        const rightCrumb = crumbs[rightIndex];
        const rightWidth = rightCrumb.getBoundingClientRect().width;

        if (usedSpace + rightWidth <= availableSpace) {
          visibleIndexes.push(rightIndex);
          usedSpace += rightWidth;
          rightIndex--;
        } else {
          break;
        }
      }
    }

    return visibleIndexes.sort((a, b) => a - b);
  }

  // ============================================================================
  // 🎨 LAYOUT APPLICATION METHODS
  // ============================================================================

  /**
   * 🎨 Show all crumbs and hide dropdown
   */
  #showAllCrumbs(crumbs, dropdown) {
    crumbs.forEach((crumb) => (crumb.style.display = ""));
    this.#hideDropdown(dropdown);
    this.#updateDropdownContent([]);
  }

  /**
   * 🎯 Apply the calculated layout with dropdown
   */
  #applyCalculatedLayout(crumbs, dropdown, visibleMiddleIndexes) {
    // 🎭 Show/hide middle crumbs based on calculation
    for (let i = 1; i < crumbs.length - 1; i++) {
      const shouldShow = visibleMiddleIndexes.includes(i);
      crumbs[i].style.display = shouldShow ? "" : "none";
    }

    // 🎯 Determine hidden indexes for dropdown
    const hiddenIndexes = this.#getHiddenMiddleIndexes(
      crumbs,
      visibleMiddleIndexes,
    );

    // 🎨 Show/hide dropdown based on hidden items
    if (hiddenIndexes.length > 0) {
      this.#showDropdown(dropdown);
      this.#updateDropdownContent(hiddenIndexes);
    } else {
      this.#hideDropdown(dropdown);
      this.#updateDropdownContent([]);
    }
  }

  /**
   * 📋 Get indexes of hidden middle crumbs
   */
  #getHiddenMiddleIndexes(crumbs, visibleIndexes) {
    const hiddenIndexes = [];

    for (let i = 1; i < crumbs.length - 1; i++) {
      if (!visibleIndexes.includes(i)) {
        hiddenIndexes.push(i);
      }
    }

    return hiddenIndexes;
  }

  /**
   * 🎨 Show dropdown with animation
   */
  #showDropdown(dropdown) {
    dropdown.style.display = "";
    dropdown.style.visibility = "";
  }

  /**
   * 🎨 Hide dropdown
   */
  #hideDropdown(dropdown) {
    dropdown.style.display = "none";
    dropdown.style.visibility = "";
  }

  // ============================================================================
  // 🎯 DROPDOWN CONTENT MANAGEMENT
  // ============================================================================

  /**
   * 📝 Update dropdown menu content with hidden breadcrumb items
   */
  #updateDropdownContent(hiddenIndexes) {
    const dropdownMenu = this.dropdownTarget.querySelector('[role="menu"]');
    if (!dropdownMenu) return;

    // 🧹 Clear existing content
    this.#clearDropdownMenu(dropdownMenu);

    // 📝 Add hidden items to dropdown
    const links = this.linksValue;
    hiddenIndexes
      .sort((a, b) => a - b)
      .forEach((index) => {
        const link = links[index];
        const menuItem = this.#createDropdownMenuItem(link);
        dropdownMenu.appendChild(menuItem);
      });
  }

  /**
   * 🧹 Clear all items from dropdown menu
   */
  #clearDropdownMenu(dropdownMenu) {
    while (dropdownMenu.firstChild) {
      dropdownMenu.removeChild(dropdownMenu.firstChild);
    }
  }

  /**
   * 🎨 Create a dropdown menu item element
   */
  #createDropdownMenuItem(link) {
    console.log(link);
    const listItem = document.createElement("li");
    listItem.setAttribute("role", "none");

    const anchor = document.createElement("a");
    anchor.setAttribute("role", "menuitem");
    anchor.setAttribute("tabindex", "-1");
    anchor.className = this.#getDropdownItemClasses();
    anchor.href = link.path;
    anchor.textContent = link.name;
    anchor.title = link.name; // ♿ Accessibility: tooltip for truncated text

    // 🚀 Add Turbo Frame attribute for proper navigation
    anchor.setAttribute("data-turbo-frame", "_top");

    listItem.appendChild(anchor);
    return listItem;
  }

  /**
   * 🎨 Get CSS classes for dropdown menu items
   */
  #getDropdownItemClasses() {
    return [
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
  }

  // ============================================================================
  // ⏱️ UTILITY METHODS
  // ============================================================================

  /**
   * ⏱️ Wait for next layout cycle
   */
  #waitForLayout() {
    return new Promise((resolve) => requestAnimationFrame(resolve));
  }
}
