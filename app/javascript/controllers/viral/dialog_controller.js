import { Controller } from "@hotwired/stimulus";
import { createFocusTrap } from "focus-trap";

// persistent dialog state between connect/disconnects
const savedDialogStates = new Map();
export default class extends Controller {
  static targets = ["dialog", "trigger"];
  static values = { open: Boolean };
  #focusTrap = null;
  #trigger = null;

  connect() {
    this.#focusTrap = createFocusTrap(this.dialogTarget, {
      onActivate: () => this.dialogTarget.classList.add("focus-trap"),
      onDeactivate: () => this.dialogTarget.classList.remove("focus-trap"),
    });

    if (this.openValue) {
      this.open();
    } else {
      this.restoreFocusState();
    }
    this.element.setAttribute("data-controller-connected", "true");
  }

  disconnect() {
    this.#focusTrap.deactivate();
    if (this.openValue) {
      this.close();
      if (this.hasTriggerTarget) {
        // re-add refocusTrigger on save
        // (this is so that turbo page loads that replace the open dialog with a closed one will refocus the trigger)
        savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: true });
      }
    }
  }

  open() {
    this.element.setAttribute("data-turbo-permanent", "");
    this.openValue = true;
    if (this.hasTriggerTarget) {
      // once a dialog has been opened we need to save it to the state to refocus the trigger if the controller is disconnected before close
      savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: true });
    }
    this.dialogTarget.showModal();
    this.#focusTrap.activate();
  }

  close() {
    this.element.removeAttribute("data-turbo-permanent");
    this.openValue = false;
    this.#focusTrap.deactivate();
    this.dialogTarget.close();
    if (this.#trigger) {
      // close will refocus the trigger so we don't need to save it to refocus on next connect
      savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: false });
      this.#trigger.focus();
    }
  }

  handleEsc(event) {
    event.preventDefault();
  }

  restoreFocusState() {
    const state = savedDialogStates.get(this.dialogTarget.id);
    if (state && state.refocusTrigger) {
      this.#trigger.focus();
      savedDialogStates.set(this.dialogTarget.id, { refocusTrigger: false });
    }
  }

  updateTrigger(button) {
    this.#trigger = button;
  }
}
