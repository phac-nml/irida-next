import { Controller } from "@hotwired/stimulus";

/**
 * @class LayoutController
 * @classdesc Stimulus controller for managing the main layout, sidebar, and header behavior.
 * @property {HTMLElement} layoutContainerTarget - The main container for the layout.
 * @property {HTMLElement} expandButtonContainerTarget - The container for the expand button.
 * @property {HTMLElement} linkTarget - A link element.
 * @property {HTMLElement} contentTarget - The main content area.
 * @property {HTMLElement} logoTarget - The logo element.
 * @property {HTMLElement} sidebarOverlayTarget - The overlay for the sidebar.
 * @property {HTMLElement} headerTarget - The header element.
 * @property {HTMLElement} mainContentTarget - The main content container.
 */
export default class extends Controller {
  static targets = [
    // The main layout container
    "layoutContainer",
    // The button to expand the sidebar
    "expandButtonContainer",
    // Links within the sidebar
    "link",
    // The main content area of the page
    "content",
    // The logo in the sidebar
    "logo",
    // The overlay for the sidebar on mobile
    "sidebarOverlay",
    // The header of the page
    "header",
    // The main content area
    "mainContent",
  ];

  /**
   * Stimulus connect lifecycle method.
   * Initializes the controller, sets the initial layout state from localStorage,
   * and sets up the scroll listener.
   * @returns {void}
   */
  connect() {
    // 📦 Check for saved layout state in local storage
    if (localStorage.getItem("layout") === "collapsed") {
      this.collapse();
    }
    // 📜 Initialize last scroll position
    this.lastScrollTop = 0;
  }

  /**
   * Stimulus disconnect lifecycle method.
   * Cleans up event listeners when the controller is removed from the DOM.
   * @returns {void}
   */
  disconnect() {
    // 🗑️ Remove event listener to prevent memory leaks
    this.contentTarget.removeEventListener(
      "click",
      this.boundHandleSidebarOverlayClick,
    );
  }

  /**
   * Collapses the sidebar.
   * Adds CSS classes to collapse the sidebar and updates the layout state in localStorage.
   * @returns {void}
   */
  collapse() {
    // 🤏 Collapse the sidebar
    this.layoutContainerTarget.classList.add("max-xl:collapsed", "collapsed");
    // ▶️ Show the expand button
    this.expandButtonContainerTarget.classList.remove("xl:hidden");
    // 💾 Save the collapsed state
    localStorage.setItem("layout", "collapsed");
  }

  /**
   * Expands the sidebar.
   * Removes CSS classes to expand the sidebar and updates the layout state in localStorage.
   * @returns {void}
   */
  expand() {
    // ▶️ Hide the expand button
    this.expandButtonContainerTarget.classList.add("xl:hidden");
    // ↔️ Expand the sidebar
    this.layoutContainerTarget.classList.remove("collapsed");
    if (window.innerWidth < this.#convertRemToPixels(80)) {
      this.layoutContainerTarget.classList.remove("max-xl:collapsed");
    }
    // 💾 Save the expanded state
    localStorage.setItem("layout", "expanded");

    // 🔍 Focus on the logo after expanding
    setTimeout(() => {
      this.logoTarget.focus();
    }, 25);
  }

  /**
   * Handles focus events on the content area.
   * Collapses the sidebar on smaller screens when the content area is focused.
   * @returns {void}
   */
  handleContentFocus() {
    // 📱 Check if on a small screen
    if (window.innerWidth < this.#convertRemToPixels(80)) {
      if (
        !this.layoutContainerTarget.classList.contains(
          "max-xl:collapsed",
          "collapsed",
        )
      ) {
        // 🤏 Collapse the sidebar if it's expanded
        this.collapse();
      }
    }
  }

  /**
   * Handles scroll events on the main content area.
   * Hides the header when scrolling down and shows it when scrolling up.
   * @param {Event} event - The scroll event.
   * @returns {void}
   */
  handleScroll(event) {
    const { scrollTop } = event.target;

    // 👇 Scrolling down
    if (scrollTop > this.lastScrollTop) {
      // 🙈 Hide the header
      this.headerTarget.classList.add("-translate-y-full");
      // ⬆️ Move the main content up
      this.mainContentTarget.classList.remove("top-16");
      this.mainContentTarget.classList.add("top-0");
    } else {
      // 👆 Scrolling up
      // 🙉 Show the header
      this.headerTarget.classList.remove("-translate-y-full");
      // ⬇️ Move the main content down
      this.mainContentTarget.classList.remove("top-0");
      this.mainContentTarget.classList.add("top-16");
    }

    // 💾 Update the last scroll position
    this.lastScrollTop = scrollTop <= 0 ? 0 : scrollTop;
  }

  /**
   * Converts rem units to pixels.
   * @param {number} rem - The value in rem units.
   * @returns {number} The equivalent value in pixels.
   * @private
   */
  #convertRemToPixels(rem) {
    // 📏 Convert rem to pixels based on the root font size
    return (
      rem * parseFloat(getComputedStyle(document.documentElement).fontSize)
    );
  }
}
