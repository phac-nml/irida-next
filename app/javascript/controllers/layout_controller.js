import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "layoutContainer",
    "expandButtonContainer",
    "link",
    "content",
    "logo",
    "sidebarOverlay",
    "sidebarNavContainer",
  ];

  connect() {
    // Need to determine the previous state
    if (localStorage.getItem("layout") === "collapsed") {
      this.collapse();
    }

    this.handleSidebarNavContainerScroll();

    this.boundHandleSidebarOverlayClick =
      this.handleSidebarOverlayClick.bind(this);
    this.boundHandleSidebarNavContainerScroll =
      this.handleSidebarNavContainerScroll.bind(this);

    this.sidebarOverlayTarget.addEventListener(
      "click",
      this.boundHandleSidebarOverlayClick,
    );

    this.sidebarNavContainerTarget.addEventListener(
      "scroll",
      this.boundHandleSidebarNavContainerScroll,
    );

    addEventListener("resize", this.boundHandleSidebarNavContainerScroll);
  }

  disconnect() {
    this.contentTarget.removeEventListener(
      "click",
      this.boundHandleSidebarOverlayClick,
    );
    this.sidebarNavContainerTarget.removeEventListener(
      "scroll",
      this.boundHandleSidebarNavContainerScroll,
    );
    removeEventListener("resize", this.boundHandleSidebarNavContainerScroll);
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

  handleSidebarNavContainerScroll() {
    if (this.sidebarNavContainerTarget.scrollTop > 0) {
      this.sidebarNavContainerTarget.classList.add("border-t", "scrim-t");
    } else {
      this.sidebarNavContainerTarget.classList.remove("border-t", "scrim-t");
    }

    if (
      this.sidebarNavContainerTarget.scrollHeight -
        this.sidebarNavContainerTarget.scrollTop >
      this.sidebarNavContainerTarget.clientHeight
    ) {
      this.sidebarNavContainerTarget.classList.add("border-b", "scrim-b");
    } else {
      this.sidebarNavContainerTarget.classList.remove("border-b", "scrim-b");
    }
  }

  #convertRemToPixels(rem) {
    return (
      rem * parseFloat(getComputedStyle(document.documentElement).fontSize)
    );
  }
}
