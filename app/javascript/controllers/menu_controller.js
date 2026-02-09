import { Controller } from "@hotwired/stimulus";
import { autoUpdate, computePosition, flip, size } from "@floating-ui/dom";

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

  update() {
    computePosition(this.triggerTarget, this.menuTarget, {
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
      Object.assign(this.menuTarget.style, {
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
