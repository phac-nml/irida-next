import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["bar"];
  static values = { percentage: Number, open: Boolean };

  // This lifecycle method is called automatically when the 'percentage' value changes
  percentageValueChanged() {
    this.updateProgressBar();
  }

  // This lifecycle method is called automatically when the 'open' value changes
  openValueChanged() {
    if (this.openValue) {
      this.show();
    } else {
      this.hide();
    }
  }

  updatePercentageValue(newPercentage) {
    this.percentageValue = newPercentage;
  }

  updateProgressBar() {
    this.barTarget.style.width = `${this.percentageValue}%`;
  }

  show() {
    this.element.style.display = "block";
  }

  hide() {
    this.element.style.display = "none";
  }
}
