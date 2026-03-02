// Stimulus controller that handles an accessible floating menu. It uses
// Floating UI (formerly Popper) to position the menu relative to a trigger
// element and manages show/hide logic including outside click detection.
//
// The controller is shared between multiple menu implementations
// (e.g. dropdown, select2, combobox, and datepicker)
// and is designed to be flexible and reusable. It exposes a `share()` method
// for passing in optional callbacks that run on show/hide, and it supports
// both click-triggered and non-click-triggered menus.
//
// Usage example (dropdown):
//
// <button data-controller="menu" data-menu-trigger-type="click">
//   Toggle menu
// </button>
//
// <div data-menu-target="menu" hidden>
//   <!-- menu content -->
// </div>

import { Controller } from "@hotwired/stimulus";
import {
  autoUpdate,
  computePosition,
  flip,
  shift,
  size,
} from "@floating-ui/dom";

export default class MenuController extends Controller {
  static targets = ["trigger", "menu"];

  static values = {
    triggerType: { type: String, default: "none" },
    strategy: { type: String, default: "absolute" },
  };

  #visible = false;
  #cleanup = null;
  #onShow = null;
  #onHide = null;

  initialize() {
    this.boundOnTriggerClick = this.#onTriggerClick.bind(this);
    this.boundHandleClickOutside = this.#handleClickOutside.bind(this);
  }

  disconnect() {
    if (this.isVisible()) {
      this.#removeClickOutsideListener();
      this.#cleanup?.();
    }
  }

  triggerTargetConnected() {
    if (this.triggerTypeValue === "click") {
      this.triggerTarget.addEventListener("click", this.boundOnTriggerClick);
    }
  }

  triggerTargetDisconnected() {
    if (this.triggerTypeValue === "click") {
      this.triggerTarget.removeEventListener("click", this.boundOnTriggerClick);
    }
  }

  share({ onShow, onHide }) {
    if (onShow) this.#onShow = onShow;
    if (onHide) this.#onHide = onHide;
  }

  isVisible() {
    return this.#visible;
  }

  toggle() {
    if (this.isVisible()) {
      this.hide();
    } else {
      this.show();
    }
  }

  show() {
    this.triggerTarget.setAttribute("aria-expanded", "true");
    this.menuTarget.setAttribute("aria-hidden", "false");
    this.menuTarget.removeAttribute("hidden");
    this.#visible = true;

    this.#setupClickOutsideListener();

    if (this.#onShow) {
      this.#onShow();
    }

    // Floating UI will call `this.update()` whenever it detects that the
    // trigger/menu geometry changes (scrolling, resize, etc.). The returned
    // cleanup function is stored so we can call it on hide/disconnect.
    this.#cleanup = autoUpdate(
      this.triggerTarget,
      this.menuTarget,
      this.update.bind(this),
    );
  }

  hide() {
    this.triggerTarget.setAttribute("aria-expanded", "false");
    this.menuTarget.setAttribute("aria-hidden", "true");
    this.menuTarget.setAttribute("hidden", "");
    this.#visible = false;

    this.#removeClickOutsideListener();

    if (this.#onHide) {
      this.#onHide();
    }

    this.#cleanup?.();
  }

  // recompute the menu position using Floating UI; called initially on show
  // and subsequently by `autoUpdate` whenever layout changes.
  update() {
    computePosition(this.triggerTarget, this.menuTarget, {
      placement: "bottom",
      middleware: [
        flip(),
        shift(),
        size({
          apply({ availableWidth, availableHeight, elements }) {
            Object.assign(elements.floating.style, {
              maxWidth: `${Math.max(0, availableWidth)}px`,
              maxHeight: `${Math.max(0, availableHeight)}px`,
            });
          },
        }),
      ],
    })
      .then(({ x, y }) => {
        Object.assign(this.menuTarget.style, {
          position: this.strategyValue,
          left: `${x}px`,
          top: `${y}px`,
        });
      })
      .catch(() => {
        // fallback for when Floating UI fails; we simply align below trigger
        const triggerRect = this.triggerTarget.getBoundingClientRect();
        Object.assign(this.menuTarget.style, {
          position: this.strategyValue,
          left: `${triggerRect.left}px`,
          top: `${triggerRect.bottom}px`,
        });
      });
  }

  #setupClickOutsideListener() {
    document.body.addEventListener("click", this.boundHandleClickOutside, true);
  }

  #removeClickOutsideListener() {
    document.body.removeEventListener(
      "click",
      this.boundHandleClickOutside,
      true,
    );
  }

  #handleClickOutside(event) {
    const clickedElement = event.target;
    if (
      clickedElement !== this.menuTarget &&
      !this.menuTarget.contains(clickedElement) &&
      !this.triggerTarget.contains(clickedElement) &&
      this.isVisible()
    ) {
      this.hide();
    }
  }

  #onTriggerClick() {
    this.toggle();
  }
}
