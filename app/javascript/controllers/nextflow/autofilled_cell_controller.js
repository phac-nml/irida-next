import { Controller } from "@hotwired/stimulus";

// Handles sending metadata and file form values to samplesheet FormData
export default class extends Controller {
  static values = { inputName: { type: String }, inputValue: { type: String } };

  connect() {
    console.log("autofilled");
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
