import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "layoutContainer",
    "expandButtonContainer",
    "link",
    "content",
    "logo",
    "sidebarOverlay",
    "header",
    "mainContent",
  ];

  connect() {
    // Need to determine the previous state
    if (localStorage.getItem("layout") === "collapsed") {
      this.collapse();
    }
    this.lastScrollTop = 0;
  }

  disconnect() {
    this.contentTarget.removeEventListener(
      "click",
      this.boundHandleSidebarOverlayClick,
    );
  }

  collapse() {
    this.layoutContainerTarget.classList.add("max-xl:collapsed", "collapsed");
    this.expandButtonContainerTarget.classList.remove("xl:hidden");
    localStorage.setItem("layout", "collapsed");
  }

  expand() {
    this.expandButtonContainerTarget.classList.add("xl:hidden");
    this.layoutContainerTarget.classList.remove("collapsed");
    if (window.innerWidth < this.#convertRemToPixels(80)) {
      this.layoutContainerTarget.classList.remove("max-xl:collapsed");
    }
    localStorage.setItem("layout", "expanded");

    setTimeout(() => {
      this.logoTarget.focus();
    }, 25);
  }

  handleContentFocus() {
    if (window.innerWidth < this.#convertRemToPixels(80)) {
      if (
        !this.layoutContainerTarget.classList.contains(
          "max-xl:collapsed",
          "collapsed",
        )
      ) {
        this.collapse();
      }
    }
  }

  handleScroll(event) {
    const { scrollTop } = event.target;

    if (scrollTop > this.lastScrollTop) {
      // Scrolling down
      this.headerTarget.classList.add("-translate-y-full");
      this.mainContentTarget.classList.remove("top-16");
      this.mainContentTarget.classList.add("top-0");
    } else {
      // Scrolling up
      this.headerTarget.classList.remove("-translate-y-full");
      this.mainContentTarget.classList.remove("top-0");
      this.mainContentTarget.classList.add("top-16");
    }

    this.lastScrollTop = scrollTop <= 0 ? 0 : scrollTop;
  }

  #convertRemToPixels(rem) {
    return (
      rem * parseFloat(getComputedStyle(document.documentElement).fontSize)
    );
  }
}
