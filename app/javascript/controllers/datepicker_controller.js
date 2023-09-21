import { Controller } from "@hotwired/stimulus";
import { Datepicker } from "flowbite-datepicker";

export default class extends Controller {
  static targets = ["datePicker"];
  static values = { format: { type: String, default: "yyyy-mm-dd" } };

  connect() {
    if (this.datePickerTarget.dataset.datepickerDialog) {
      new Datepicker(this.datePickerTarget, {
        container: "#dialog",
        format: this.formatValue,
        orientation: "bottom left",
        autohide: true,
      });
    } else {
      new Datepicker(this.datePickerTarget, {
        format: this.formatValue,
        orientation: "bottom left",
        autohide: true,
      });
    }
  }
}
