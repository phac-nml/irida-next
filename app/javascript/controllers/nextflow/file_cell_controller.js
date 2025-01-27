import { Controller } from "@hotwired/stimulus";

// Handles sending file data to samplesheet after file selection
export default class extends Controller {
  static values = {
    inputName: { type: String },
    inputValue: { type: String },
    filename: { type: String },
    index: { type: String },
    property: { type: String },
  };

  connect() {
    this.sendFileData();
  }

  sendFileData() {
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
    } else if (this.typeValue == "metadata") {
      dispatchContent["metadata"] = { property: this.propertyValue };
    }
    this.dispatch("sendFileData", {
      detail: {
        content: dispatchContent,
      },
    });
  }
}
