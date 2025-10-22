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
    this.boundOnButtonKeyDown = this.onButtonKeyDown.bind(this);
    this.boundOnMenuItemKeyDown = this.onMenuItemKeyDown.bind(this);
    this.boundFocusOut = this.focusOut.bind(this);
  }

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  menuTargetConnected(element) {
    element.setAttribute("aria-hidden", "true");
    element.addEventListener("keydown", this.boundOnMenuItemKeyDown);
    element.addEventListener("focusout", this.boundFocusOut);
    this.#menuItems(element).forEach((menuitem) => {
      menuitem.setAttribute("tabindex", "-1");
    });
  }

  menuTargetDisconnected(element) {
    element.removeEventListener("keydown", this.boundOnMenuItemKeyDown);
    element.removeEventListener("focusout", this.boundFocusOut);
  }

  triggerTargetConnected(element) {
    element.addEventListener("keydown", this.boundOnButtonKeyDown);
    this.dropdown = new Dropdown(this.menuTarget, element, {
      triggerType: "click",
      offsetSkidding: this.skiddingValue,
      offsetDistance: this.distanceValue,
      onShow: () => {
        this.triggerTarget.setAttribute("aria-expanded", "true");
        this.menuTarget.setAttribute("aria-hidden", "false");
        this.menuTarget.removeAttribute("hidden");
      },
      onHide: () => {
        this.triggerTarget.setAttribute("aria-expanded", "false");
        this.menuTarget.setAttribute("aria-hidden", "true");
        this.menuTarget.setAttribute("hidden", "hidden");
      },
    });
  }

  focusOut(event) {
    if (!this.menuTarget.contains(event.relatedTarget)) {
      this.dropdown.hide();
    }
  }

  onButtonKeyDown(event) {
    var menuItems = this.#menuItems(this.menuTarget);
    switch (event.key) {
      case "Enter":
      case " ":
      case "ArrowDown":
        event.preventDefault();
        this.dropdown.show();
        menuItems[0].tabIndex = "0";
        menuItems[0].focus();
        break;
      case "ArrowUp":
        event.preventDefault();
        this.dropdown.show();
        menuItems[menuItems.length - 1].tabIndex = "0";
        menuItems[menuItems.length - 1].focus();
        break;
    }
  }

  onMenuItemKeyDown(event) {
    var menuItems = this.#menuItems(this.menuTarget);
    var currentIndex = menuItems.indexOf(document.activeElement);
    this.#focusByKey(event, menuItems, currentIndex);
  }

  #focusByKey(event, menuItems, currentIndex) {
    switch (event.key) {
      case "Enter":
      case " ":
        event.preventDefault();
        if (menuItems[currentIndex].nodeName === "LI") {
          // find first clickable target
          const clickableTarget = menuItems[currentIndex].querySelector(
            'a, button, input[type="submit"]',
          );
          // fire click or close dropdown
          if (clickableTarget) {
            clickableTarget.click();
          } else {
            this.dropdown.hide();
          }
        } else {
          menuItems[currentIndex].click();
        }
        return document.addEventListener(
          "turbo:morph",
          () => {
            this.triggerTarget.focus();
          },
          { once: true },
        );
      case "Escape":
        event.preventDefault();
        this.triggerTarget.focus();
        break;
      case "ArrowUp":
        event.preventDefault();
        var prevIndex = menuItems.length - 1;
        if (currentIndex > 0) {
          var prevIndex = Math.max(0, currentIndex - 1);
        }
        menuItems[currentIndex].tabIndex = "-1";
        menuItems[prevIndex].tabIndex = "0";
        menuItems[prevIndex].focus();
        break;
      case "ArrowDown":
        event.preventDefault();
        var nextIndex = 0;
        if (currentIndex < menuItems.length - 1) {
          var nextIndex = Math.min(menuItems.length - 1, currentIndex + 1);
        }
        menuItems[currentIndex].tabIndex = "-1";
        menuItems[nextIndex].tabIndex = "0";
        menuItems[nextIndex].focus();
        break;
      case "Home":
        event.preventDefault();
        menuItems[currentIndex].tabIndex = "-1";
        menuItems[0].tabIndex = "0";
        menuItems[0].focus();
        break;
      case "End":
        event.preventDefault();
        menuItems[currentIndex].tabIndex = "-1";
        menuItems[menuItems.length - 1].tabIndex = "0";
        menuItems[menuItems.length - 1].focus();
        break;
    }
  }

  #menuItems(menu) {
    return Array.prototype.slice.call(
      menu.querySelectorAll(
        '[role="menuitem"]:not([disabled]), [role="menuitemcheckbox"]:not([disabled]), [role="menuitemradio"]:not([disabled])',
      ),
    );
  }
}
