import { Controller } from "@hotwired/stimulus";
import { computePosition, flip, shift, autoUpdate } from "@floating-ui/dom";

export default class MenuController extends Controller {
  static targets = ["trigger", "menu"];

  static values = {
    triggerType: { type: String, default: "none" },
  };

  #menu = this.menuTarget;
  #trigger = this.triggerTarget;
  #triggerType = this.triggerTypeValue;
  #visible = false;
  #cleanup = null;
  #onShow = null;
  #onHide = null;

  connect() {
    console.debug("Menu controller connected");
  }

  disconnect() {
    console.debug("Menu controller disconnected");
  }

  triggerTargetConnected() {
    if (this.#triggerType === "click") {
      this.#trigger.addEventListener("click", () => {
        this.toggle();
      });
    }
  }

  triggerTargetDisconnected() {
    if (this.#triggerType === "click") {
      this.#trigger.removeEventListener("click", () => {
        this.toggle();
      });
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
    this.#menu.removeAttribute("aria-hidden");
    this.#menu.classList.remove("hidden");
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
    this.#menu.classList.add("hidden");
    this.#visible = false;

    this.#removeClickOutsideListener();

    if (this.#onHide) {
      this.#onHide();
    }

    this.#cleanup;
  }

  update() {
    computePosition(this.#trigger, this.#menu, {
      placement: "bottom-start",
      middleware: [flip(), shift({ padding: 8 })],
    }).then(({ x, y }) => {
      Object.assign(this.#menu.style, {
        position: "absolute",
        left: `${x}px`,
        top: `${y}px`,
      });
    });
  }

  #setupClickOutsideListener() {
    document.body.addEventListener(
      "click",
      (event) => {
        this.#handleClickOutside(event);
      },
      true,
    );
  }

  #removeClickOutsideListener() {
    document.body.removeEventListener(
      "click",
      (event) => {
        this.#handleClickOutside(event);
      },
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
}
