//  Our own custom dropdown.js that replaces flowbite dropdown.js e.g.
// - handles opening/closing
// - checking state
// - event listeners on open/close etc.
// - styling to position the dropdown above/below based on available space in the viewport

export default class Dropdown {
  constructor(target, trigger, options = {}) {
    this._target = target;
    this._trigger = trigger;
    this._options = options;
    this._visible = false;
    this._initialize();
  }

  _initialize() {
    if (this._target && this._trigger) {
      this._addStyling();
      this._setupEventListeners();
    }
  }

  _addStyling() {
    this._target.classList.add("anchor");
    this._target.style.positionAnchor = `--anchor-${this._target.id}`;
    this._trigger.style.anchorName = `--anchor-${this._target.id}`;
  }

  _setupEventListeners() {
    this._trigger.addEventListener("click", () => {
      this.toggle();
    });
  }

  _setupClickOutsideListener() {
    document.body.addEventListener(
      "click",
      (event) => {
        this._handleClickOutside(event);
      },
      true,
    );
  }

  _removeClickOutsideListener() {
    document.body.removeEventListener(
      "click",
      (event) => {
        this._handleClickOutside(event);
      },
      true,
    );
  }

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

  isVisible() {
    return this._visible;
  }

  toggle() {
    if (this.isVisible()) {
      this.hide();
    } else {
      this.show();
    }
  }

  show() {
    this._trigger.setAttribute("aria-expanded", "true");
    this._target.removeAttribute("aria-hidden");
    this._target.classList.remove("hidden");
    this._visible = true;
    this._setupClickOutsideListener();
    if (this._options.onShow) {
      this._options.onShow();
    }
  }

  hide() {
    this._trigger.setAttribute("aria-expanded", "false");
    this._target.setAttribute("aria-hidden", "true");
    this._target.classList.add("hidden");
    this._visible = false;
    this._removeClickOutsideListener();
    if (this._options.onHide) {
      this._options.onHide();
    }
  }
}
