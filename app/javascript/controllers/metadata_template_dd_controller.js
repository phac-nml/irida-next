import { Controller } from "@hotwired/stimulus";

/**
 * MetadataTemplateDropdownController
 *
 * Handles a Flowbite dropdown for metadata template selection.
 * - Submits the form when the dropdown is shown (for live filtering or updating)
 * - Hides the dropdown when a successful Turbo form submission occurs elsewhere
 *
 * Stimulus Targets:
 * - trigger: The element that toggles the dropdown
 * - menu: The dropdown menu element
 * - form: The form to submit on dropdown show
 *
 * Usage:
 * <div data-controller="metadata-template-dd">
 *   <button data-metadata-template-dd-target="trigger">Open</button>
 *   <div data-metadata-template-dd-target="menu">
 *     <form data-metadata-template-dd-target="form">...</form>
 *   </div>
 * </div>
 */
export default class extends Controller {
  static targets = ["trigger", "menu", "form"];

  /** @type {Dropdown} Flowbite dropdown instance */
  #dropdown;
  /** @type {Function} Bound event handler for turbo:submit-end */
  #turboSubmitEndListener = this.#handleTurboSubmitEnd.bind(this);

  initialize() {
    this.boundOnButtonKeyDown = this.onButtonKeyDown.bind(this);
    this.boundOnButtonClick = this.onButtonClick.bind(this);
    this.boundOnMenuItemKeyDown = this.onMenuItemKeyDown.bind(this);
    this.boundFocusOut = this.focusOut.bind(this);
  }

  /**
   * Connects the controller, initializes the dropdown, and sets up event listeners.
   */
  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  /**
   * Disconnects the controller and cleans up event listeners.
   */
  disconnect() {
    document.removeEventListener(
      "turbo:submit-end",
      this.#turboSubmitEndListener,
    );
    if (this.#dropdown) {
      this.#dropdown.hide();
      this.#dropdown = null;
    }
  }

  menuTargetConnected(element) {
    element.addEventListener("keydown", this.boundOnMenuItemKeyDown);
    element.addEventListener("focusout", this.boundFocusOut);
  }

  triggerTargetConnected(element) {
    element.addEventListener("keydown", this.boundOnButtonKeyDown);
    element.addEventListener("click", this.boundOnButtonClick, true);
    this.#dropdown = new Dropdown(this.menuTarget, this.triggerTarget, {
      triggerType: "none",
      onShow: () => {
        this.triggerTarget.setAttribute("aria-expanded", "true");
        if (this.hasFormTarget) {
          // Auto-submit the form when dropdown is shown
          this.formTarget.requestSubmit();
        }
      },
      onHide: () => {
        this.triggerTarget.setAttribute("aria-expanded", "false");
        this.#menuItems(element).forEach((menuitem) => {
          menuitem.setAttribute("tabindex", "-1");
        });
      },
    });

    document.addEventListener("turbo:submit-end", this.#turboSubmitEndListener);
  }

  focusOut(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.#dropdown.hide();
    }
  }

  onButtonClick(event) {
    event.preventDefault();
    event.stopPropagation();

    if (this.#dropdown.isVisible()) {
      this.#dropdown.hide();
    } else {
      var menuItems = this.#menuItems(this.menuTarget);
      this.#dropdown.show();
      if (!this.hasFormTarget) {
        menuItems[0].tabIndex = "0";
        menuItems[0].focus();
      }
    }
  }

  onButtonKeyDown(event) {
    switch (event.key) {
      case "Enter":
      case " ":
      case "ArrowDown":
        event.preventDefault();
        this.#dropdown.show();
        if (!this.hasFormTarget) {
          this.#menuItems(this.menuTarget)[0].focus();
        }
        break;
      case "ArrowUp":
        event.preventDefault();
        if (this.hasFormTarget) {
          this.formTarget.querySelector(
            'input[name="focusedMenuItemIndex"]',
          ).value = "-1";
        }
        this.#dropdown.show();
        if (!this.hasFormTarget) {
          this.#menuItems(this.menuTarget).at(-1).focus();
        }
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
      case "Tab":
        if (event.shiftKey) {
          event.preventDefault();
          this.triggerTarget.focus();
          this.#dropdown.hide();
        }
        break;
    }
  }

  /**
   * Handles Turbo form submission events.
   * Hides the dropdown if a successful submission occurs outside this form.
   *
   * @param {CustomEvent} event - The turbo:submit-end event
   * @private
   */
  #handleTurboSubmitEnd(event) {
    if (event.detail.success) {
      if (this.hasFormTarget && event.target === this.formTarget) {
        this.formTarget.remove();
        document.activeElement.blur();
      } else {
        this.#dropdown?.hide();
      }
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
