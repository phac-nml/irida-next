import { computePosition, flip, shift, autoUpdate } from "@floating-ui/dom";

/**
 * Dropdown - small utility to manage show/hide of a dropdown panel.
 *
 * Responsibilities:
 * - Toggle visibility and ARIA attributes
 * - Provide onShow/onHide lifecycle hooks
 * - Close when clicking outside the dropdown/trigger
 */
export default class Dropdown {
  /**
   * @param {Element} target  The panel element to show/hide.
   * @param {Element} trigger The element that toggles the panel.
   * @param {Object} options  Optional trigger type and callbacks: { triggerType, onShow, onHide }.
   */
  constructor(target, trigger, options = {}) {
    this._target = target;
    this._trigger = trigger;
    this._options = options;
    this._visible = false;
    this._cleanup = null;

    // Prepare element styling and event wiring
    this._initialize();
  }

  // Initialize styling and event listeners
  _initialize() {
    if (this._target && this._trigger) {
      this._setupEventListeners();
    }
  }

  // Attach primary toggle handler to trigger
  _setupEventListeners() {
    if (this._options.triggerType === "click" || !this._options.triggerType) {
      this._trigger.addEventListener("click", () => {
        this.toggle();
      });
    }
  }

  // Install a capturing click listener on body to detect outside clicks
  _setupClickOutsideListener() {
    document.body.addEventListener(
      "click",
      (event) => {
        this._handleClickOutside(event);
      },
      true,
    );
  }

  // Remove the previously installed outside click listener
  _removeClickOutsideListener() {
    document.body.removeEventListener(
      "click",
      (event) => {
        this._handleClickOutside(event);
      },
      true,
    );
  }

  // Close the dropdown when a click occurs outside of the trigger/panel
  _handleClickOutside(event) {
    const clickedElement = event.target;
    if (
      clickedElement !== this._target &&
      !this._target.contains(clickedElement) &&
      !this._trigger.contains(clickedElement) &&
      this.isVisible()
    ) {
      this.hide();
    }
  }

  // Whether the panel is currently visible
  isVisible() {
    return this._visible;
  }

  // Toggle visibility
  toggle() {
    if (this.isVisible()) {
      this.hide();
    } else {
      this.show();
    }
  }

  // Show the panel and run onShow hook
  show() {
    this._trigger.setAttribute("aria-expanded", "true");
    this._target.removeAttribute("aria-hidden");
    this._target.classList.remove("hidden");
    this._visible = true;

    // Detect outside clicks to auto-close
    this._setupClickOutsideListener();

    if (this._options.onShow) {
      this._options.onShow();
    }

    this._cleanup = autoUpdate(
      this._trigger,
      this._target,
      this.update.bind(this),
    );
  }

  // Hide the panel and run onHide hook
  hide() {
    this._trigger.setAttribute("aria-expanded", "false");
    this._target.setAttribute("aria-hidden", "true");
    this._target.classList.add("hidden");
    this._visible = false;

    // Clean up outside click listener
    this._removeClickOutsideListener();

    if (this._options.onHide) {
      this._options.onHide();
    }

    this._cleanup();
  }

  update() {
    computePosition(this._trigger, this._target, {
      placement: "bottom-start",
      middleware: [flip(), shift({ padding: 8 })],
    }).then(({ x, y }) => {
      Object.assign(this._target.style, {
        position: "absolute",
        left: `${x}px`,
        top: `${y}px`,
      });
    });
  }
}
