import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["row"];

  initialize() {
    this.boundKeydown = this.keydown.bind(this);
  }

  connect() {
    this.element.addEventListener("keydown", this.boundKeydown);
    this.element.setAttribute("data-controller-connected", "true");
  }

  keydown(event) {
    if (event.key === "ArrowDown" && !event.ctrlKey && !event.shiftKey) {
      if (event.target.parentNode.lastElementChild !== event.target) {
        event.target.tabIndex = "-1";
        event.target.nextElementSibling.tabIndex = "0";
        event.target.nextElementSibling.focus();
      }
    } else if (event.key === "ArrowUp" && !event.ctrlKey && !event.shiftKey) {
      if (event.target.parentNode.firstElementChild !== event.target) {
        event.target.tabIndex = "-1";
        event.target.previousElementSibling.tabIndex = "0";
        event.target.previousElementSibling.focus();
      }
    } else if (event.key === "Home") {
      if (this.rowTargets.includes(event.target) || event.ctrlKey) {
        if (event.target.parentNode.firstElementChild !== event.target) {
          event.target.tabIndex = "-1";
          event.target.parentNode.firstElementChild.tabIndex = "0";
          event.target.parentNode.firstElementChild.focus();
        }
      }
    } else if (event.key === "End") {
      if (this.rowTargets.includes(event.target) || event.ctrlKey) {
        if (event.target.parentNode.lastElementChild !== event.target) {
          event.target.tabIndex = "-1";
          event.target.parentNode.lastElementChild.tabIndex = "0";
          event.target.parentNode.lastElementChild.focus();
        }
      }
    } else if (event.key === "PageUp") {
      if (event.target.parentNode.firstElementChild !== event.target) {
        event.target.tabIndex = "-1";
        event.target.parentNode.firstElementChild.tabIndex = "0";
        event.target.parentNode.firstElementChild.focus();
      }
    } else if (event.key === "PageDown") {
      if (event.target.parentNode.lastElementChild !== event.target) {
        event.target.tabIndex = "-1";
        event.target.parentNode.lastElementChild.tabIndex = "0";
        event.target.parentNode.lastElementChild.focus();
      }
    }
  }
}
