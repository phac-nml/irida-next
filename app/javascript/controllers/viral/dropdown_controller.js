import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["trigger", "menu"];
  static values = {
    position: String,
    trigger: String,
    skidding: Number,
    distance: Number,
  };

  initialize() {
    this.boundKeydown = this.keyDown.bind(this);
    this.boundFocusOut = this.focusOut.bind(this);
  }

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  menuTargetConnected(element) {
    element.setAttribute("aria-hidden", "true");
    element.addEventListener("keydown", this.boundKeydown);
    element.addEventListener("focusout", this.boundFocusOut);
  }

  menuTargetDisconnected(element) {
    element.removeEventListener("keydown", this.boundKeydown);
    element.removeEventListener("focusout", this.boundFocusOut);
  }

  triggerTargetConnected(element) {
    this.dropdown = new Dropdown(this.menuTarget, element, {
      triggerType: this.triggerValue,
      offsetSkidding: this.skiddingValue,
      offsetDistance: this.distanceValue,
      onShow: () => {
        this.triggerTarget.setAttribute("aria-expanded", "true");
        this.menuTarget.setAttribute("aria-hidden", "false");
        this.menuTarget.removeAttribute("hidden");
        this.menuTarget.setAttribute("tabindex", "0");
      },
      onHide: () => {
        this.triggerTarget.setAttribute("aria-expanded", "false");
        this.menuTarget.setAttribute("aria-hidden", "true");
        this.menuTarget.setAttribute("tabindex", "-1");
        this.menuTarget.setAttribute("hidden", "hidden");
      },
    });
  }

  focusOut(event) {
    if (!this.menuTarget.contains(event.relatedTarget)) {
      this.dropdown.hide();
    }
  }

  keyDown(event) {
    var menuLinks = Array.prototype.slice.call(
      this.menuTarget.querySelectorAll("a"),
    );
    var currentIndex = menuLinks.indexOf(document.activeElement);
    this.#focusByKey(event, menuLinks, currentIndex);
  }

  #focusByKey(event, menuLinks, currentIndex) {
    switch (event.key) {
      case "Escape":
        this.triggerTarget.focus();
      case "ArrowUp":
      case "ArrowLeft":
        event.preventDefault();
        if (currentIndex > -1) {
          var prevIndex = Math.max(0, currentIndex - 1);
          menuLinks[prevIndex].focus();
        }
        break;
      case "ArrowDown":
      case "ArrowRight":
        event.preventDefault();
        if (currentIndex > -1) {
          var nextIndex = Math.min(menuLinks.length - 1, currentIndex + 1);
          menuLinks[nextIndex].focus();
        }
        break;
      case "Home":
        event.preventDefault();
        menuLinks[0].focus();
        break;
      case "End":
        event.preventDefault();
        menuLinks[menuLinks.length - 1].focus();
        break;
    }
  }
}
