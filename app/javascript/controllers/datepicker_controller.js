import { Controller } from "@hotwired/stimulus";
import { Datepicker } from "flowbite-datepicker";

export default class extends Controller {
  static targets = ["datePicker"];
  static values = {
    format: { type: String, default: "yyyy-mm-dd" },
    currentDate: String
  };

  connect() {
    this.localTimeOffset = new Date().getTimezoneOffset() * 60000
    if (this.currentDateValue) {
      this.dateWithOffset = this.#getDateWithOffset(this.currentDateValue)
    }

    if (this.datePickerTarget.dataset.datepickerDialog) {
      let dp = new Datepicker(this.datePickerTarget, {
        container: "#dialog",
        format: this.formatValue,
        orientation: "bottom left",
        autohide: true,
      })
      if (this.currentDateValue) {
        dp.setDate(this.dateWithOffset);
      }
    } else {
      let dp = new Datepicker(this.datePickerTarget, {
        format: this.formatValue,
        orientation: "bottom left",
        autohide: true,
      })
      if (this.currentDateValue) {
        dp.setDate(this.dateWithOffset);
      }
    }

    if (this.datePickerTarget.dataset.datepickerAutosubmit) {
      this.datePickerTarget.addEventListener("changeDate", (e) =>
        this.handleDateSelected(e)
      );
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
    let selectedDateWithoutOffset = this.#getDateWithoutOffset(e.target.value)
    this.datePickerTarget.setAttribute("value", selectedDateWithoutOffset);
    this.datePickerTarget.form.requestSubmit();
  }

  #getDateWithOffset(date) {
    let parsedTimeWithOffset = Date.parse(date) - this.localTimeOffset
    return new Date(parsedTimeWithOffset).toISOString().slice(0, 10)
  }

  #getDateWithoutOffset(date) {
    let parsedTimeWithoutOffset = Date.parse(date) + this.localTimeOffset
    return new Date(parsedTimeWithoutOffset).toISOString().slice(0, 10)
  }
}
