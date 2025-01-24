import { Controller } from "@hotwired/stimulus";

// Handles sending metadata and file form values to samplesheet FormData
export default class extends Controller {
  static values = {
    inputName: { type: String },
    inputValue: { type: String },
    filename: { type: String },
    index: { type: String },
    property: { type: String },
    type: { type: String },
  };

  connect() {
    console.log("autofilled");
    this.sendAutofilledInputData();
  }

  sendAutofilledInputData() {
    let dispatchContent = {
      inputName: this.inputNameValue,
      inputValue: this.inputValueValue,
    };
    if (this.typeValue == "file") {
      dispatchContent["file"] = {
        filename: this.filenameValue,
        index: this.indexValue,
        property: this.propertyValue,
      };
    }
    this.dispatch("sendAutofilledInputData", {
      detail: {
        content: dispatchContent,
      },
    });
  }
}
