import {
  autoUpdate,
  computePosition,
  flip,
  offset,
  shift,
  size,
} from "@floating-ui/dom";

export default class FloatingDropdown {
  // Private Fields

  #trigger; // DOM element that triggers the dropdown
  #dropdown; // DOM element of the floating dropdown
  #strategy; // Positioning strategy ('absolute' or 'fixed')
  #distance; // Distance in pixels between trigger and dropdown
  #manageAria; // Whether to manage ARIA attributes
  #visible; // Current visibility state
  #cleanup; // Cleanup function for autoUpdate
  #onShow; // Callback fired when dropdown shows
  #onHide; // Callback fired when dropdown hides
  #boundHandleClickOutside; // Bound click outside handler

  // Public Methods

  // Initialize floating dropdown with config options
  constructor({
    trigger,
    dropdown,
    strategy = "absolute",
    distance = 0,
    manageAria = true,
    onShow,
    onHide,
  }) {
    this.#trigger = trigger;
    this.#dropdown = dropdown;
    this.#strategy = strategy;
    this.#distance = distance;
    this.#manageAria = manageAria;
    this.#visible = false;
    this.#onShow = onShow;
    this.#onHide = onHide;
    this.#boundHandleClickOutside = this.#handleClickOutside.bind(this);
  }

  // Returns boolean indicating if dropdown is currently visible
  isVisible() {
    return this.#visible;
  }

  // Show dropdown if hidden, hide if visible
  toggle() {
    if (this.isVisible()) {
      this.hide();
    } else {
      this.show();
    }
  }

  // Display dropdown, setup click listener, start position tracking
  show() {
    this.#visible = true;
    this.#applyVisibleState();
    this.#setupClickOutsideListener();

    if (this.#onShow) {
      this.#onShow();
    }

    this.#cleanup = autoUpdate(
      this.#trigger,
      this.#dropdown,
      this.update.bind(this),
    );
  }

  // Hide dropdown, remove click listener, stop position tracking
  hide() {
    this.#visible = false;
    this.#applyHiddenState();
    this.#removeClickOutsideListener();

    if (this.#onHide) {
      this.#onHide();
    }

    this.#cleanup?.();
  }

  // Cleanup and hide dropdown
  destroy() {
    if (this.isVisible()) {
      this.hide();
    }
    this.#trigger = null;
    this.#dropdown = null;
    this.#strategy = null;
    this.#manageAria = null;
    this.#visible = false;
    this.#cleanup = null;
    this.#onShow = null;
    this.#onHide = null;
    this.#boundHandleClickOutside = null;
  }

  // Recalculate and apply dropdown position using Floating UI
  update() {
    computePosition(this.#trigger, this.#dropdown, {
      placement: "bottom",
      middleware: [
        flip(),
        offset(this.#distance),
        shift(),
        size({
          apply({ availableWidth, availableHeight, rects, elements }) {
            Object.assign(elements.floating.style, {
              maxWidth: `${Math.max(0, availableWidth)}px`,
              maxHeight: `${Math.max(0, availableHeight)}px`,
              minWidth: `${rects.reference.width}px`,
              minHeight: `${rects.reference.height}px`,
            });
          },
        }),
      ],
    })
      .then(({ x, y }) => {
        Object.assign(this.#dropdown.style, {
          position: this.#strategy,
          left: `${x}px`,
          top: `${y}px`,
        });
      })
      .catch(() => {
        // fallback for when Floating UI fails; we simply align below trigger
        const triggerRect = this.#trigger.getBoundingClientRect();
        Object.assign(this.#dropdown.style, {
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

  // Hide dropdown if click occurs outside trigger or dropdown
  #handleClickOutside(event) {
    const clickedElement = event.target;
    if (
      clickedElement !== this.#dropdown &&
      !this.#dropdown.contains(clickedElement) &&
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
      this.#dropdown.removeAttribute("aria-hidden");
      this.#dropdown.removeAttribute("hidden");
    }
  }

  // Set ARIA attributes for hidden state
  #applyHiddenState() {
    if (this.#manageAria) {
      this.#trigger.setAttribute("aria-expanded", "false");
      this.#dropdown.setAttribute("aria-hidden", "true");
      this.#dropdown.setAttribute("hidden", "");
    }
  }
}
