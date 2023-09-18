import { Controller } from "@hotwired/stimulus";
import { Datepicker } from "flowbite-datepicker";

export default class extends Controller {
  static targets = ["datePicker"];

  connect() {
    if (this.datePickerTarget.dataset.datepickerDialog) {
      new Datepicker(this.datePickerTarget, {
        container: "#dialog",
        format: "yyyy-mm-dd",
        orientation: "bottom left",
        autohide: true,
      });
    } else {
      new Datepicker(this.datePickerTarget, {
        format: "yyyy-mm-dd",
        orientation: "bottom left",
        autohide: true,
      });
    }
  }
}
