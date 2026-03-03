import {
  autoUpdate,
  computePosition,
  flip,
  shift,
  size,
} from "@floating-ui/dom";

export default class FloatingMenu {
  // Private Fields

  #trigger; // DOM element that triggers the menu
  #menu; // DOM element of the floating menu
  #strategy; // Positioning strategy ('absolute' or 'fixed')
  #manageAria; // Whether to manage ARIA attributes
  #visible; // Current visibility state
  #cleanup; // Cleanup function for autoUpdate
  #onShow; // Callback fired when menu shows
  #onHide; // Callback fired when menu hides
  #boundHandleClickOutside; // Bound click outside handler

  // Public Methods

  // Initialize floating menu with config options
  constructor({ trigger, menu, strategy, onShow, onHide, manageAria }) {
    this.#trigger = trigger;
    this.#menu = menu;
    this.#strategy = strategy || "absolute";
    this.#manageAria = manageAria || true;
    this.#visible = false;
    this.#onShow = onShow;
    this.#onHide = onHide;
    this.#boundHandleClickOutside = this.#handleClickOutside.bind(this);
  }

  // Returns boolean indicating if menu is currently visible
  isVisible() {
    return this.#visible;
  }

  // Show menu if hidden, hide if visible
  toggle() {
    if (this.isVisible()) {
      this.hide();
    } else {
      this.show();
    }
  }

  // Display menu, setup click listener, start position tracking
  show() {
    this.#visible = true;
    this.#applyVisibleState();
    this.#setupClickOutsideListener();

    if (this.#onShow) {
      this.#onShow();
    }

    this.#cleanup = autoUpdate(
      this.#trigger,
      this.#menu,
      this.update.bind(this),
    );
  }

  // Hide menu, remove click listener, stop position tracking
  hide() {
    this.#visible = false;
    this.#applyHiddenState();
    this.#removeClickOutsideListener();

    if (this.#onHide) {
      this.#onHide();
    }

    this.#cleanup?.();
  }

  // Cleanup and hide menu
  destroy() {
    if (this.isVisible()) {
      this.hide();
    }
    this.#trigger = null;
    this.#menu = null;
    this.#strategy = null;
    this.#manageAria = null;
    this.#visible = false;
    this.#cleanup = null;
    this.#onShow = null;
    this.#onHide = null;
    this.#boundHandleClickOutside = null;
  }

  // Recalculate and apply menu position using Floating UI
  update() {
    computePosition(this.#trigger, this.#menu, {
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
        Object.assign(this.#menu.style, {
          position: this.#strategy,
          left: `${x}px`,
          top: `${y}px`,
        });
      })
      .catch(() => {
        // fallback for when Floating UI fails; we simply align below trigger
        const triggerRect = this.#trigger.getBoundingClientRect();
        Object.assign(this.#menu.style, {
          position: this.#strategy,
          left: `${triggerRect.left}px`,
          top: `${triggerRect.bottom}px`,
        });
      });
  }

  // Private Methods

  // Attach document click handler to detect outside clicks
  #setupClickOutsideListener() {
    document.body.addEventListener(
      "click",
      this.#boundHandleClickOutside,
      true,
    );
  }

  // Remove document click handler
  #removeClickOutsideListener() {
    document.body.removeEventListener(
      "click",
      this.#boundHandleClickOutside,
      true,
    );
  }

  // Hide menu if click occurs outside trigger or menu
  #handleClickOutside(event) {
    const clickedElement = event.target;
    if (
      clickedElement !== this.#menu &&
      !this.#menu.contains(clickedElement) &&
      !this.#trigger.contains(clickedElement) &&
      this.isVisible()
    ) {
      this.hide();
    }
  }

  // Set ARIA attributes for visible state
  #applyVisibleState() {
    if (this.#manageAria) {
      this.#trigger.setAttribute("aria-expanded", "true");
      this.#menu.removeAttribute("aria-hidden");
      this.#menu.removeAttribute("hidden");
    }
  }

  // Set ARIA attributes for hidden state
  #applyHiddenState() {
    if (this.#manageAria) {
      this.#trigger.setAttribute("aria-expanded", "false");
      this.#menu.setAttribute("aria-hidden", "true");
      this.#menu.setAttribute("hidden", "");
    }
  }
}
