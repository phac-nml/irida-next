import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["bar"];
  static values = { percentage: Number };

  // This lifecycle method is called automatically when the 'percentage' value changes
  percentageValueChanged() {
    this.updateProgressBar();
  }

  updateProgressBar() {
    this.barTarget.style.width = `${this.percentageValue}%`;
  }
}
