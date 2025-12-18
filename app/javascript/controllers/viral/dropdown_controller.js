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
    this.boundOnButtonClick = this.onButtonClick.bind(this);
    this.boundOnMenuItemKeyDown = this.onMenuItemKeyDown.bind(this);
    this.boundFocusOut = this.focusOut.bind(this);
  }

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  menuTargetConnected(element) {
    element.style.position = "fixed";
    element.style.positionAnchor = `--anchor-${this.menuTarget.id}`;
    element.classList.add("anchor");
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
    element.style.anchorName = `--anchor-${this.menuTarget.id}`;
    element.addEventListener("keydown", this.boundOnButtonKeyDown);
    element.addEventListener("click", this.boundOnButtonClick, {
      capture: true,
    });
  }

  focusOut(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.hide();
    }
  }

  onButtonClick(event) {
    event.preventDefault();
    event.stopPropagation();

    if (this.isVisible()) {
      this.hide();
    } else {
      this.#openMenuAndFocusMenuItem(0);
    }
  }

  isVisible() {
    return !this.menuTarget.classList.contains("hidden");
  }

  show() {
    this.triggerTarget.setAttribute("aria-expanded", "true");
    this.menuTarget.removeAttribute("aria-hidden");
    this.menuTarget.classList.remove("hidden");
  }

  hide() {
    this.triggerTarget.setAttribute("aria-expanded", "false");
    this.menuTarget.setAttribute("aria-hidden", "true");
    this.menuTarget.classList.add("hidden");
    this.#menuItems(this.menuTarget).forEach((menuitem) => {
      menuitem.setAttribute("tabindex", "-1");
    });
  }

  onButtonKeyDown(event) {
    switch (event.key) {
      case "Enter":
      case " ":
      case "ArrowDown":
        event.preventDefault();
        this.#openMenuAndFocusMenuItem(0);
        break;
      case "ArrowUp":
        event.preventDefault();
        this.#openMenuAndFocusMenuItem(-1);
        break;
    }
  }

  #openMenuAndFocusMenuItem(index) {
    var menuItems = this.#menuItems(this.menuTarget);

    if (menuItems.length === 0) {
      // lazy loaded menu
      document.addEventListener(
        "turbo:frame-load",
        () => {
          var menuItems = this.#menuItems(this.menuTarget);
          // initialize tab index to -1 on lazy load
          menuItems.forEach((menuItem) => {
            menuItem.setAttribute("tabindex", "-1");
          });
          this.#focusMenuItem(menuItems.at(index));
        },
        { once: true },
      );
      this.show();
    } else {
      this.show();
      this.#focusMenuItem(menuItems.at(index));
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
            this.hide();
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
        this.#focusMenuItem(menuItems.at(prevIndex));
        break;
      case "ArrowDown":
        event.preventDefault();
        var nextIndex = 0;
        if (currentIndex < menuItems.length - 1) {
          var nextIndex = Math.min(menuItems.length - 1, currentIndex + 1);
        }
        menuItems[currentIndex].tabIndex = "-1";
        this.#focusMenuItem(menuItems.at(nextIndex));
        break;
      case "Home":
        event.preventDefault();
        menuItems[currentIndex].tabIndex = "-1";
        this.#focusMenuItem(menuItems.at(0));
        break;
      case "End":
        event.preventDefault();
        menuItems[currentIndex].tabIndex = "-1";
        this.#focusMenuItem(menuItems.at(-1));
        break;
      case "Tab":
        if (event.shiftKey) {
          event.preventDefault();
          this.triggerTarget.focus();
          this.hide();
        }
        break;
    }
  }

  #focusMenuItem(menuItem) {
    menuItem.tabIndex = "0";
    menuItem.focus();
  }

  #menuItems(menu) {
    return Array.prototype.slice.call(
      menu.querySelectorAll(
        '[role="menuitem"]:not([disabled]), [role="menuitemcheckbox"]:not([disabled]), [role="menuitemradio"]:not([disabled])',
      ),
    );
  }
}
