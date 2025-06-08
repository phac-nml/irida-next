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
  static values = {
    format: { type: String, default: "yyyy-mm-dd" },
    minDate: {
      type: String,
      default: null,
      validator: (value) => {
        if (!value) return true;
        const date = new Date(value);
        return !isNaN(date.getTime());
      },
    },
  };

  connect() {
    const options = {
      format: this.formatValue,
      orientation: "bottom left",
      autohide: true,
      minDate: this.getMinDate(),
    };

    if (this.datePickerTarget.dataset.datepickerDialog) {
      options.container = "#dialog";
    }

    new IridaNextDatepicker(this.datePickerTarget, options);

    if (this.datePickerTarget.dataset.datepickerAutosubmit) {
      this.datePickerTarget.addEventListener("changeDate", (e) =>
        this.handleDateSelected(e),
      );
    }
  }

  /**
   * Gets the minimum date value, handling null and invalid dates
   * @returns {Date|null} The minimum date or null if not set/invalid
   * @private
   */
  getMinDate() {
    if (!this.minDateValue) return null;

    const date = new Date(this.minDateValue);
    if (isNaN(date.getTime())) {
      console.warn(`Invalid minDate value: ${this.minDateValue}`);
      return null;
    }

    return date;
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
