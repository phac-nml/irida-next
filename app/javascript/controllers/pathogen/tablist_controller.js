import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="tablist"
export default class extends Controller {
  #tabs;

  connect() {
    this.#tabs = Array.from(this.element.querySelectorAll("a"));
  }

  handleKeyboardInput(event) {
    const handler = this.#getKeyboardHandler(event.key);
    if (handler) {
      // keep default tab and enter functionality
      if (event.key !== "Tab" || event.key !== "Enter") event.preventDefault();
      handler.call(this, event);
    }
  }

  #getKeyboardHandler(key) {
    const handlers = {
      " ": this.#selectTab.bind(this),
      ArrowLeft: (event) => this.#handleLeftNavigation(event, "single"),
      ArrowRight: (event) => this.#handleRightNavigation(event, "single"),
      Home: (event) => this.#handleLeftNavigation(event, "fullList"),
      End: (event) => this.#handleRightNavigation(event, "fullList"),
    };
    return handlers[key];
  }

  #selectTab(event) {
    Turbo.visit(event.target.href, { action: "replace" });
  }

  #handleRightNavigation(event, movementSize) {
    let index = this.#tabs.indexOf(event.target);
    const lastTabIndex = this.#tabs.length - 1;
    if (index !== lastTabIndex) {
      const targetIndex = movementSize === "single" ? index + 1 : lastTabIndex;
      this.#tabs[targetIndex].focus();
    }
  }

  #handleLeftNavigation(event, movementSize) {
    let index = this.#tabs.indexOf(event.target);

    if (index !== 0) {
      const targetIndex = movementSize === "single" ? index - 1 : 0;
      this.#tabs[targetIndex].focus();
    }
  }
}
