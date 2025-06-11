import { Controller } from "@hotwired/stimulus";
import { createFocusTrap } from "focus-trap";

export default class extends Controller {
  static targets = ["dialog"];

  static values = { open: Boolean };

  #focusTrap = null;

  initialize() {
    console.log("initialize");

    // const container = document.getElementById("dialog");
    const container = this.dialogTarget;

    this.#focusTrap = createFocusTrap(container, {
      onActivate: () => container.classList.add("is-active"),
      onDeactivate: () => container.classList.remove("is-active"),
    });
  }

  connect() {
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
