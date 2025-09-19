import { Controller } from "@hotwired/stimulus";

let trigger = null;

export default class extends Controller {
  static outlets = ["viral--dialog"];
  static targets = ["button"];

  open() {
    trigger = this.buttonTarget;
  }

  viralDialogOutletConnected() {
    this.viralDialogOutlet.updateTrigger(trigger);
  }
}
