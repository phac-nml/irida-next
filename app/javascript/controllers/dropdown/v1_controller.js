import { Controller } from "@hotwired/stimulus";

const MENU_NAV_KEYS = new Set([
  "ArrowUp",
  "ArrowDown",
  "Home",
  "End",
  "Escape",
  "Enter",
  " ",
  "Tab",
]);

export default class extends Controller {
  static targets = ["trigger", "menu", "caret"];
  static values = {
    position: String,
    trigger: String,
    skidding: Number,
    distance: Number,
  };

  #documentMenuKeyDownBound = false;
  initialize() {
    this.boundOnButtonKeyDown = this.onButtonKeyDown.bind(this);
    this.boundOnButtonClick = this.onButtonClick.bind(this);
    this.boundOnMenuKeyDown = this.onMenuKeyDown.bind(this);
    this.boundFocusOut = this.focusOut.bind(this);
    this.boundStopMenuFocusPropagation =
      this.stopMenuFocusPropagation.bind(this);
  }

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  disconnect() {
    this.#unbindDocumentMenuKeyDown();
  }

  menuTargetConnected(element) {
    element.setAttribute("aria-hidden", "true");
    element.addEventListener("focusout", this.boundFocusOut);
    // Keep focus events inside the menu from bubbling to a host Pathogen
    // toolbar, which would otherwise restore focus to the trigger and make the
    // open menu unreachable by keyboard.
    element.addEventListener("focusin", this.boundStopMenuFocusPropagation);
    this.#menuItems(element).forEach((menuitem) => {
      menuitem.setAttribute("tabindex", "-1");
    });
  }

  menuTargetDisconnected(element) {
    element.removeEventListener("focusout", this.boundFocusOut);
    element.removeEventListener("focusin", this.boundStopMenuFocusPropagation);
  }

  stopMenuFocusPropagation(event) {
    event.stopPropagation();
  }

  triggerTargetConnected(element) {
    element.addEventListener("keydown", this.boundOnButtonKeyDown);
    element.addEventListener("click", this.boundOnButtonClick, {
      capture: true,
    });
    this.dropdown = new Dropdown(this.menuTarget, element, {
      triggerType: "none",
      offsetSkidding: this.skiddingValue,
      offsetDistance: this.distanceValue,
      onShow: () => {
        this.triggerTarget.setAttribute("aria-expanded", "true");
        this.menuTarget.setAttribute("aria-hidden", "false");
        this.menuTarget.removeAttribute("hidden");
        this.#bindDocumentMenuKeyDown();
        if (this.hasCaretTarget) {
          this.caretTarget.classList.add("rotate-180");
        }
      },
      onHide: () => {
        this.#unbindDocumentMenuKeyDown();
        this.triggerTarget.setAttribute("aria-expanded", "false");
        this.menuTarget.setAttribute("aria-hidden", "true");
        this.menuTarget.setAttribute("hidden", "hidden");
        this.#menuItems(element).forEach((menuitem) => {
          menuitem.setAttribute("tabindex", "-1");
        });
        if (this.hasCaretTarget) {
          this.caretTarget.classList.remove("rotate-180");
        }
      },
    });
  }

  focusOut(event) {
    if (!event.relatedTarget) {
      return;
    }

    if (!this.element.contains(event.relatedTarget)) {
      this.dropdown.hide();
    }
  }

  onButtonClick(event) {
    event.preventDefault();
    event.stopPropagation();

    if (this.dropdown.isVisible()) {
      this.dropdown.hide();
    } else {
      this.#openMenuAndFocusMenuItem(0);
    }
  }

  onButtonKeyDown(event) {
    if (this.#isMenuOpen()) {
      return;
    }

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

  onMenuKeyDown(event) {
    if (!this.#isMenuOpen() || !this.#eventInDropdown(event.target)) {
      return;
    }

    if (!MENU_NAV_KEYS.has(event.key)) {
      return;
    }

    const menuItems = this.#menuItems(this.menuTarget);
    const currentIndex = menuItems.indexOf(document.activeElement);
    this.#focusByKey(event, menuItems, currentIndex);
  }

  #bindDocumentMenuKeyDown() {
    if (this.#documentMenuKeyDownBound) {
      return;
    }

    this.#documentMenuKeyDownBound = true;
    document.addEventListener("keydown", this.boundOnMenuKeyDown, {
      capture: true,
    });
  }

  #unbindDocumentMenuKeyDown() {
    if (!this.#documentMenuKeyDownBound) {
      return;
    }

    this.#documentMenuKeyDownBound = false;
    document.removeEventListener("keydown", this.boundOnMenuKeyDown, {
      capture: true,
    });
  }

  #eventInDropdown(target) {
    if (!(target instanceof Node)) {
      return false;
    }

    return (
      this.triggerTarget === target ||
      this.triggerTarget.contains(target) ||
      this.menuTarget.contains(target)
    );
  }

  #openMenuAndFocusMenuItem(index) {
    const menuItems = this.#menuItems(this.menuTarget);

    if (menuItems.length === 0) {
      // lazy loaded menu
      document.addEventListener(
        "turbo:frame-load",
        () => {
          const menuItems = this.#menuItems(this.menuTarget);
          // initialize tab index to -1 on lazy load
          menuItems.forEach((menuItem) => {
            menuItem.setAttribute("tabindex", "-1");
          });
          this.#focusMenuItem(menuItems.at(index));
        },
        { once: true },
      );
      this.dropdown.show();
    } else {
      this.dropdown.show();
      this.#focusMenuItem(menuItems.at(index));
    }
  }

  #focusByKey(event, menuItems, currentIndex) {
    if (menuItems.length === 0) {
      return;
    }

    event.stopImmediatePropagation();

    const activeItem = currentIndex >= 0 ? menuItems[currentIndex] : null;

    switch (event.key) {
      case "Enter":
      case " ":
        if (!activeItem) {
          return;
        }

        event.preventDefault();
        if (activeItem.nodeName === "LI") {
          // find first clickable target
          const clickableTarget = activeItem.querySelector(
            'a, button, input[type="submit"]',
          );
          // fire click or close dropdown
          if (clickableTarget) {
            clickableTarget.click();
          } else {
            this.dropdown.hide();
          }
        } else {
          activeItem.click();
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
        this.dropdown.hide();
        this.triggerTarget.focus();
        break;
      case "ArrowUp": {
        event.preventDefault();
        const prevIndex =
          activeItem === null || currentIndex <= 0
            ? menuItems.length - 1
            : currentIndex - 1;
        this.#clearMenuItemTabIndex(activeItem);
        this.#focusMenuItem(menuItems[prevIndex]);
        break;
      }
      case "ArrowDown": {
        event.preventDefault();
        const nextIndex =
          activeItem === null || currentIndex >= menuItems.length - 1
            ? 0
            : currentIndex + 1;
        this.#clearMenuItemTabIndex(activeItem);
        this.#focusMenuItem(menuItems[nextIndex]);
        break;
      }
      case "Home":
        event.preventDefault();
        this.#clearMenuItemTabIndex(activeItem);
        this.#focusMenuItem(menuItems[0]);
        break;
      case "End":
        event.preventDefault();
        this.#clearMenuItemTabIndex(activeItem);
        this.#focusMenuItem(menuItems[menuItems.length - 1]);
        break;
      case "Tab":
        if (event.shiftKey) {
          event.preventDefault();
          this.triggerTarget.focus();
          this.dropdown.hide();
        }
        break;
    }
  }

  #clearMenuItemTabIndex(menuItem) {
    if (menuItem) {
      menuItem.tabIndex = "-1";
    }
  }

  #focusMenuItem(menuItem) {
    if (!menuItem) {
      return;
    }

    menuItem.tabIndex = "0";
    menuItem.focus({ focusVisible: true });
  }

  #isMenuOpen() {
    if (this.dropdown?.isVisible()) {
      return true;
    }

    if (this.triggerTarget?.getAttribute("aria-expanded") === "true") {
      return true;
    }

    const menu = this.menuTarget;
    return Boolean(
      menu && !menu.hidden && menu.getAttribute("aria-hidden") !== "true",
    );
  }

  #menuItems(menu) {
    return Array.prototype.slice.call(
      menu.querySelectorAll(
        '[role="menuitem"]:not([disabled]), [role="menuitemcheckbox"]:not([disabled]), [role="menuitemradio"]:not([disabled])',
      ),
    );
  }
}
