import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "layoutContainer",
    "expandButton",
    "link",
    "content",
    "logo",
  ];

  connect() {
    // Need to determine the previous state
    if (localStorage.getItem("layout") === "collapsed") {
      this.collapse();
    }

    this.contentTarget.addEventListener(
      "click",
      this.handleContentClick.bind(this),
    );
    this.expandButtonTarget.addEventListener(
      "focus",
      this.handleContentFocus.bind(this),
    );
  }

  disconnect() {
    this.contentTarget.removeEventListener(
      "click",
      this.handleContentClick.bind(this),
    );
    this.expandButtonTarget.removeEventListener(
      "focus",
      this.handleContentFocus.bind(this),
    );
  }

  collapse() {
    this.layoutContainerTarget.classList.add("max-xl:collapsed", "collapsed");
    this.expandButtonTarget.classList.remove("xl:hidden");
    localStorage.setItem("layout", "collapsed");
  }

  expand(event) {
    this.layoutContainerTarget.classList.remove(
      "max-xl:collapsed",
      "collapsed",
    );
    this.expandButtonTarget.classList.add("xl:hidden");
    if (typeof event !== "undefined") {
      this.logoTarget.focus();
    }
    localStorage.setItem("layout", "expanded");
  }

  handleContentClick(event) {
    if (this.expandButtonTarget.contains(event.target)) {
      return;
    } else if (window.innerWidth < this.#convertRemToPixels(80)) {
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

  handleContentFocus(event) {
    if (
      this.expandButtonTarget.contains(event.target) &&
      window.innerWidth < this.#convertRemToPixels(80)
    ) {
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
