import { Controller } from "@hotwired/stimulus";

// Connects to data-controller="filters"
export default class extends Controller {
  static targets = ["cell"];
  static outlets = ["nextflow--samplesheet"];

  static values = { inputName: { type: String }, inputValue: { type: String } };

  connect() {
    this.sendAutofilledInputData();
  }

  sendAutofilledInputData() {
    this.dispatch("sendAutofilledInputData", {
      detail: {
        content: {
          inputName: this.inputNameValue,
          inputValue: this.inputValueValue,
        },
      },
    });
  }
}
