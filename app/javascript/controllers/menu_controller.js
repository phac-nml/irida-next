import { Controller } from "@hotwired/stimulus";
import { autoUpdate, computePosition, flip, size } from "@floating-ui/dom";

export default class MenuController extends Controller {
  static targets = ["trigger", "menu"];

  static values = {
    triggerType: { type: String, default: "none" },
    strategy: { type: String, default: "absolute" },
  };

  #menu = this.menuTarget;
  #trigger = this.triggerTarget;
  #triggerType = this.triggerTypeValue;
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
    if (this.#triggerType === "click") {
      this.#trigger.addEventListener("click", this.boundOnTriggerClick);
    }
  }

  triggerTargetDisconnected() {
    if (this.#triggerType === "click") {
      this.#trigger.removeEventListener("click", this.boundOnTriggerClick);
    }
  }

  share({ menu, triggerType, onShow, onHide }) {
    if (menu) this.#menu = menu;
    if (triggerType) this.#triggerType = triggerType;
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
    this.#trigger.setAttribute("aria-expanded", "true");
    this.#menu.setAttribute("aria-hidden", "false");
    this.#menu.removeAttribute("hidden");
    this.#visible = true;

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

  hide() {
    this.#trigger.setAttribute("aria-expanded", "false");
    this.#menu.setAttribute("aria-hidden", "true");
    this.#menu.setAttribute("hidden", "");
    this.#visible = false;

    this.#removeClickOutsideListener();

    if (this.#onHide) {
      this.#onHide();
    }

    this.#cleanup?.();
  }

  update() {
    computePosition(this.#trigger, this.#menu, {
      placement: "bottom",
      middleware: [
        flip(),
        size({
          apply({ availableHeight, elements }) {
            Object.assign(elements.floating.style, {
              maxHeight: `${Math.max(0, availableHeight)}px`,
            });
          },
        }),
      ],
    }).then(({ x, y }) => {
      Object.assign(this.#menu.style, {
        position: this.strategyValue,
        left: `${x}px`,
        top: `${y}px`,
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
