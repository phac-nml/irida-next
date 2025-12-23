//  Our own custom dropdown.js that replaces flowbite dropdown.js e.g.
// - handles opening/closing
// - checking state
// - event listeners on open/close etc.
// - styling to position the dropdown above/below based on available space in the viewport

export default class Dropdown {
  constructor(target, trigger, options = {}) {
    this.target = target;
    this.trigger = trigger;
    this.options = options;
    this.visible = false;
    this.initialize();
  }

  initialize() {
    console.log("Initializing...");
    this.target.style.position = "fixed";
    this.target.style.positionAnchor = `--anchor-${this.target.id}`;
    this.target.classList.add("anchor");
    this.trigger.style.anchorName = `--anchor-${this.target.id}`;
  }

  isVisible() {
    return this.visible;
  }

  toggle() {
    if (this.isVisible()) {
      this.hide();
    } else {
      this.show();
    }
  }

  show() {
    this.trigger.setAttribute("aria-expanded", "true");
    this.target.removeAttribute("aria-hidden");
    this.target.classList.remove("hidden");
    this.visible = true;

    if (this.options.onShow) {
      this.options.onShow();
    }
  }

  hide() {
    this.trigger.setAttribute("aria-expanded", "false");
    this.target.setAttribute("aria-hidden", "true");
    this.target.classList.add("hidden");
    this.visible = false;

    if (this.options.onHide) {
      this.options.onHide();
    }
  }
}
