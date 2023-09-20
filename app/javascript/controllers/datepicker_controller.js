import { Controller } from "@hotwired/stimulus";
import { Datepicker } from "flowbite-datepicker";

export default class extends Controller {
  static targets = ["datePicker"];

  connect() {
    if (this.datePickerTarget.dataset.datepickerAutosubmit) {
      this.datePickerTarget.addEventListener("changeDate", (e) =>
        this.handleDateSelected(e)
      );
    }

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

  disconnect() {
    if (this.datePickerTarget.dataset.datepickerAutosubmit) {
      this.datePickerTarget.removeEventListener("changeDate", (e) =>
        this.handleDateSelected(e)
      );
    }
  }

  handleDateSelected(e) {
    this.datePickerTarget.setAttribute("value", e.target.value);
    this.datePickerTarget.form.requestSubmit();
  }
}
