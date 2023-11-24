import { Controller } from "@hotwired/stimulus";

// disables buttons until checkboxes are selected
export default class extends Controller {
  static targets = ["input"];
  static outlets = ["action-link"];

  toggle() {
    const selectedCheckboxes = this.inputTargets.filter(
      (checkbox) => checkbox.checked
    );
    this.actionLinkOutlets.forEach((outlet) => {
      outlet.setDisabled(selectedCheckboxes.length);
    });
  }

  actionLinkOutletConnected(outlet) {
    const selectedCheckboxes = this.inputTargets.filter(
      (checkbox) => checkbox.checked
    ).length;
    outlet.setDisabled(selectedCheckboxes.length);
  }
}
