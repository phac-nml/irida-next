import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "layoutContainer",
    "expandButtonContainer",
    "expandButton",
    "link",
    "content",
    "logo",
    "sidebarOverlay",
    "announcement",
    "collapseButton",
  ];

  static values = {
    collapsedAnnouncement: String,
    expandedAnnouncement: String,
  };

  connect() {
    this.announcementsEnabled = true;

    // Need to determine the previous state
    if (localStorage.getItem("layout") === "collapsed") {
      this.announcementsEnabled = false;
      this.collapse();
    }

    this.#setExpandedState(
      !this.layoutContainerTarget.classList.contains("collapsed"),
    );

    this.announcementsEnabled = true;
  }

  disconnect() {
    this.contentTarget.removeEventListener(
      "click",
      this.boundHandleSidebarOverlayClick,
    );
  }

  collapse(event) {
    const initiatedByUser = event instanceof Event;

    this.layoutContainerTarget.classList.add("max-xl:collapsed", "collapsed");
    this.expandButtonContainerTarget.classList.remove("xl:hidden");
    localStorage.setItem("layout", "collapsed");

    this.#setExpandedState(false);

    if (this.announcementsEnabled && this.hasAnnouncementTarget) {
      this.#announce(this.collapsedAnnouncementValue);
    }

    if (initiatedByUser && this.hasExpandButtonTarget) {
      window.requestAnimationFrame(() => {
        this.expandButtonTarget.focus();
      });
    }
  }

  expand() {
    this.expandButtonContainerTarget.classList.add("xl:hidden");
    this.layoutContainerTarget.classList.remove("collapsed");
    if (window.innerWidth < this.#convertRemToPixels(80)) {
      this.layoutContainerTarget.classList.remove("max-xl:collapsed");
    }
    localStorage.setItem("layout", "expanded");

    this.#setExpandedState(true);

    setTimeout(() => {
      this.logoTarget.focus();
    }, 25);

    if (this.announcementsEnabled && this.hasAnnouncementTarget) {
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
    if (!message || !this.announcementsEnabled) return;
    this.announcementTarget.textContent = "";
    window.requestAnimationFrame(() => {
      this.announcementTarget.textContent = message;
    });
  }

  #setExpandedState(isExpanded) {
    const value = String(isExpanded);

    if (this.hasCollapseButtonTarget) {
      this.collapseButtonTarget.setAttribute("aria-expanded", value);
    }

    if (this.hasExpandButtonTarget) {
      this.expandButtonTarget.setAttribute("aria-expanded", value);
    }
  }
}
