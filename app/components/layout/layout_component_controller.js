import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["layoutContainer", "iconExpand", "iconCollapse", "link"];

  initialize() {
    // Need to determine the previous state
    localStorage.getItem("layout") === "collapsed"
      ? this.collapsed()
      : this.expanded();
  }

  toggle() {
    if (this.layoutContainerTarget.classList.contains("collapsed")) {
      this.expanded();
    } else {
      this.collapsed();
    }
  }

  collapsed() {
    this.layoutContainerTarget.classList.add("collapsed");
    this.iconCollapseTarget.classList.add("hidden");
    this.iconExpandTarget.classList.remove("hidden");
    this.iconExpandTarget.classList.add("flex");
    this.linkTargets.forEach((link) => {
      link.classList.add("sr-only");
    });
    localStorage.setItem("layout", "collapsed");
  }

  expanded() {
    this.layoutContainerTarget.classList.remove("collapsed");
    this.iconCollapseTarget.classList.remove("hidden");
    this.iconExpandTarget.classList.remove("flex");
    this.iconExpandTarget.classList.add("hidden");
    this.linkTargets.forEach((link) => {
      link.classList.remove("sr-only");
    });
    localStorage.setItem("layout", "expanded");
  }
}
