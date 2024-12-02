import { Controller } from "@hotwired/stimulus";

class IridaNextDatepicker extends Datepicker {
  _getDatepickerOptions(options) {
    const datepickerOptions = super._getDatepickerOptions(options);

    if (options.container) {
      datepickerOptions.container = options.container;
    }

    return datepickerOptions;
  }
}

export default class extends Controller {
  static targets = ["datePicker"];
  static values = { format: { type: String, default: "yyyy-mm-dd" } };

  connect() {
    if (this.datePickerTarget.dataset.datepickerAutosubmit) {
      this.datePickerTarget.addEventListener("changeDate", (e) =>
        this.handleDateSelected(e),
      );
    }

    if (this.datePickerTarget.dataset.datepickerDialog) {
      new IridaNextDatepicker(this.datePickerTarget, {
        container: "#dialog",
        format: this.formatValue,
        orientation: "bottom left",
        autohide: true,
      });
    } else {
      new IridaNextDatepicker(this.datePickerTarget, {
        format: this.formatValue,
        orientation: "bottom left",
        autohide: true,
      });
    }
  }

  disconnect() {
    if (this.datePickerTarget.dataset.datepickerAutosubmit) {
      this.datePickerTarget.removeEventListener("changeDate", (e) =>
        this.handleDateSelected(e),
      );
    }
  }

  handleDateSelected(e) {
    this.datePickerTarget.setAttribute("value", e.target.value);
    this.datePickerTarget.form.requestSubmit();
  }
}
