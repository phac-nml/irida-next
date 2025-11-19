import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    ids: Array,
  };
  static outlets = ["selection"];

  connect() {
    if (this.hasSelectionOutlet) {
      this.selectionOutlet.update(this.idsValue);
    }
  }

  selectionOutletConnected() {
    // Update the selection when the outlet becomes available
    this.selectionOutlet.update(this.idsValue);
  }
}
