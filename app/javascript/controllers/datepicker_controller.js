import { Controller } from "@hotwired/stimulus";
import { Datepicker } from "flowbite-datepicker";

// Connects to data-controller="datepicker"
export default class extends Controller {
  static targets = ["datePicker"];

  initialize() {
    new Datepicker(this.datePickerTarget, {
      format: "yyyy-mm-dd",
      orientation: "bottom left",
    });
  }
}
