import { Controller } from "@hotwired/stimulus";

// Handles sending file data to samplesheet after file selection
export default class extends Controller {
  static values = {
    files: { type: Object },
  };

  connect() {
    this.sendFileData();
  }

  sendFileData() {
    this.dispatch("sendFileData", {
      detail: {
        content: this.filesValue,
      },
    });
  }
}
