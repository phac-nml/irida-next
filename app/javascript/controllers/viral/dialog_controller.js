import { Controller } from "@hotwired/stimulus";
import { createFocusTrap } from "focus-trap";

export default class extends Controller {
  static targets = ["dialog"];
  static values = { open: Boolean };
  #focusTrap = null;

  connect() {
    this.#focusTrap = createFocusTrap(this.dialogTarget, {
      onActivate: () => this.dialogTarget.classList.add("focus-trap"),
      onDeactivate: () => this.dialogTarget.classList.remove("focus-trap"),
    });

    if (this.openValue) this.open();
    this.element.setAttribute("data-controller-connected", "true");
  }

  disconnect() {
    this.close();
  }

  open() {
    this.openValue = true;
    this.dialogTarget.showModal();
    this.#focusTrap.activate();
  }

  close() {
    this.openValue = false;
    this.dialogTarget.close();
    this.#focusTrap.deactivate();
  }

  handleEsc(event) {
    event.preventDefault();
  }
}
