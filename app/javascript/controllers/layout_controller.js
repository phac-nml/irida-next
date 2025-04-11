import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "layoutContainer",
    "expandButtonContainer",
    "link",
    "content",
    "logo",
    "sidebarOverlay",
  ];

  connect() {
    // Need to determine the previous state
    if (localStorage.getItem("layout") === "collapsed") {
      this.collapse();
    }

    this.boundHandleSidebarOverlayClick =
      this.handleSidebarOverlayClick.bind(this);

    this.sidebarOverlayTarget.addEventListener(
      "click",
      this.boundHandleSidebarOverlayClick,
    );
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

  expand(event) {
    this.layoutContainerTarget.classList.remove("collapsed");
    if (window.innerWidth < this.#convertRemToPixels(80)) {
      this.layoutContainerTarget.classList.remove("max-xl:collapsed");
    }
    this.expandButtonContainerTarget.classList.add("xl:hidden");
    if (typeof event !== "undefined") {
      this.logoTarget.focus();
    }
    localStorage.setItem("layout", "expanded");
  }

  handleSidebarOverlayClick() {
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

  #convertRemToPixels(rem) {
    return (
      rem * parseFloat(getComputedStyle(document.documentElement).fontSize)
    );
  }
}
