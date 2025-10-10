import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "layoutContainer",
    "expandButtonContainer",
    "link",
    "content",
    "logo",
    "sidebarOverlay",
    "announcement",
  ];

  static values = {
    collapsedAnnouncement: String,
    expandedAnnouncement: String,
  };

  connect() {
    // Need to determine the previous state
    if (localStorage.getItem("layout") === "collapsed") {
      this.collapse();
    }
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

    if (this.hasAnnouncementTarget) {
      this.#announce(this.collapsedAnnouncementValue);
    }
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

    if (this.hasAnnouncementTarget) {
      this.#announce(this.expandedAnnouncementValue);
    }
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

  #convertRemToPixels(rem) {
    return (
      rem * parseFloat(getComputedStyle(document.documentElement).fontSize)
    );
  }

  #announce(message) {
    if (!message) return;
    this.announcementTarget.textContent = "";
    window.requestAnimationFrame(() => {
      this.announcementTarget.textContent = message;
    });
  }
}
