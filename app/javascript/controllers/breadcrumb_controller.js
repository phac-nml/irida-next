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
  #PADDING = 32; // Total horizontal padding (16px on each side)
  #CHEVRON_WIDTH = 16; // Width of the chevron separator
  #TOLERANCE_PERCENTAGE = 0.05; // 5% tolerance before switching to dropdown

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
    const { crumbs, dropdown } = this.#getLayoutElements();
    const containerWidth = this.listTarget.clientWidth;
    const availableWidth = containerWidth - this.#PADDING;
    const toleranceWidth = containerWidth * this.#TOLERANCE_PERCENTAGE;

    // Early exit for minimal breadcrumbs
    if (crumbs.length < 3) {
      this.#showAllCrumbs(crumbs, dropdown);
      return;
    }

    // First show all crumbs to get accurate measurements
    this.#showAllCrumbs(crumbs, dropdown);
    await this.#waitForLayout();

    // Calculate total width of all crumbs
    const totalWidth = this.#calculateTotalWidth(crumbs);

    // If everything fits (with tolerance), keep all crumbs visible
    if (totalWidth <= availableWidth + toleranceWidth) {
      return; // Already showing all crumbs
    }

    // If not everything fits, switch to dropdown mode
    await this.#applyDropdownLayout(crumbs, dropdown);
  }

  /**
   * 🎯 Get all necessary DOM elements for layout calculations
   */
  #getLayoutElements() {
    const crumbs = this.crumbTargets;
    const dropdown = this.dropdownTarget;
    return { crumbs, dropdown };
  }

  /**
   * 🎯 Show all crumbs and hide dropdown
   */
  #showAllCrumbs(crumbs, dropdown) {
    crumbs.forEach((crumb) => (crumb.style.display = "inline-flex"));
    dropdown.style.display = "none";
  }

  /**
   * 📝 Update dropdown content
   */
  #updateDropdownContent(middleCrumbs) {
    const dropdownMenu = this.dropdownTarget.querySelector('[role="menu"]');
    if (!dropdownMenu) return;

    // Clear existing content
    while (dropdownMenu.firstChild) {
      dropdownMenu.removeChild(dropdownMenu.firstChild);
    }

    // Add menu items for each middle crumb
    middleCrumbs.forEach((crumb, index) => {
      const link = this.linksValue[index + 1]; // +1 to skip home
      if (!link) return;

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
      dropdownMenu.appendChild(menuItem);
    });
  }

  #calculateTotalWidth(crumbs) {
    let totalWidth = 0;
    crumbs.forEach((crumb, index) => {
      // Add chevron width for all except the first crumb
      if (index > 0) {
        totalWidth += this.#CHEVRON_WIDTH;
      }
      // Add the crumb's width
      totalWidth += crumb.getBoundingClientRect().width;
    });
    return totalWidth;
  }

  async #applyDropdownLayout(crumbs, dropdown) {
    // Always show first and last crumbs
    const firstCrumb = crumbs[0];
    const lastCrumb = crumbs[crumbs.length - 1];
    firstCrumb.style.display = "inline-flex";
    lastCrumb.style.display = "inline-flex";

    // Hide all middle crumbs
    const middleCrumbs = crumbs.slice(1, -1);
    middleCrumbs.forEach((crumb) => {
      crumb.style.display = "none";
    });

    // Show dropdown
    dropdown.style.display = "inline-flex";

    // Update dropdown content
    this.#updateDropdownContent(middleCrumbs);
  }

  async #waitForLayout() {
    // Wait for two animation frames to ensure layout is complete
    await new Promise(resolve => requestAnimationFrame(() =>
      requestAnimationFrame(resolve)
    ));
  }
}
