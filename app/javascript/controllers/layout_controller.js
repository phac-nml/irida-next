import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["layoutContainer", "iconExpand", "iconCollapse", "link"];

  initialize() {
    // Need to determine the previous state
    sessionStorage.getItem("layout") === "collapsed"
      ? this.collapsed()
      : this.expended();
  }

  toggle() {
    if (this.layoutContainerTarget.classList.contains("collapsed")) {
      this.expended();
    } else {
      this.collapsed();
    }
  }

  collapsed() {
    this.layoutContainerTarget.classList.add("collapsed");
    this.iconCollapseTarget.classList.add("hidden");
    this.iconExpandTarget.classList.remove("hidden");
    this.linkTargets.forEach((link) => {
      link.classList.add("sr-only");
    });
    sessionStorage.setItem("layout", "collapsed");
  }

  expended() {
    this.layoutContainerTarget.classList.remove("collapsed");
    this.iconCollapseTarget.classList.remove("hidden");
    this.iconExpandTarget.classList.add("hidden");
    this.linkTargets.forEach((link) => {
      link.classList.remove("sr-only");
    });
    sessionStorage.setItem("layout", "expended");
  }
}
