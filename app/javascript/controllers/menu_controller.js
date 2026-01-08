import { Controller } from "@hotwired/stimulus";
import { computePosition, flip, shift, autoUpdate } from "@floating-ui/dom";

export default class MenuController extends Controller {
  static targets = ["trigger", "menu"];

  static values = {
    triggerType: { type: String, default: "click" },
  };

  #visible = false;
  #cleanup = null;
  #onShow = null;
  #onHide = null;

  connect({ onShow, onHide }) {
    console.debug("Menu controller connected");
    this.#onShow = onShow;
    this.#onHide = onHide;
  }

  disconnect() {
    console.debug("Menu controller disconnected");
  }

  triggerTargetConnected() {
    if (this.triggerTypeValue === "click") {
      this.triggerTarget.addEventListener("click", () => {
        this.toggle();
      });
    }
  }

  triggerTargetDisconnected() {
    if (this.triggerTypeValue === "click") {
      this.triggerTarget.removeEventListener("click", () => {
        this.toggle();
      });
    }
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
    this.menuTarget.removeAttribute("aria-hidden");
    this.menuTarget.classList.remove("hidden");
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
    this.menuTarget.classList.add("hidden");
    this.#visible = false;

    this.#removeClickOutsideListener();

    if (this.#onHide) {
      this.#onHide();
    }

    this.#cleanup;
  }

  update() {
    computePosition(this.triggerTarget, this.menuTarget, {
      placement: "bottom-start",
      middleware: [flip(), shift({ padding: 8 })],
    }).then(({ x, y }) => {
      Object.assign(this.menuTarget.style, {
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
