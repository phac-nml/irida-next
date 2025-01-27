import { Controller } from "@hotwired/stimulus";

// Handles sending file data to samplesheet after file selection
export default class extends Controller {
  static values = {
    globalId: { type: String },
    filename: { type: String },
    index: { type: String },
    property: { type: String },
  };

  connect() {
    this.sendFileData();
  }

  sendFileData() {
    let dispatchContent = {
      globalId: this.globalIdValue,
      filename: this.filenameValue,
      index: this.indexValue,
      property: this.propertyValue,
    };
    this.dispatch("sendFileData", {
      detail: {
        content: dispatchContent,
      },
    });
  }
}
