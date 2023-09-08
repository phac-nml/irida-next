import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["layoutContainer", "expandButton", "link"];

  initialize() {
    // Need to determine the previous state
    localStorage.getItem("layout") === "collapsed"
      ? this.collapse()
      : this.expand();
  }

  collapse() {
    this.layoutContainerTarget.classList.add("collapsed");
    this.expandButtonTarget.classList.remove("hidden");
    localStorage.setItem("layout", "collapsed");
  }

  expand() {
    this.layoutContainerTarget.classList.remove("collapsed");
    this.expandButtonTarget.classList.add("hidden");
    localStorage.setItem("layout", "expanded");
  }
}
