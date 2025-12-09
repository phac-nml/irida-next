import { Controller } from "@hotwired/stimulus";

// Handles sending metadata to samplesheet after metadata selection
export default class extends Controller {
  static values = {
    metadata: { type: Object },
  };

  connect() {
    this.sendMetadata();
  }

  sendMetadata() {
    this.dispatch("sendMetadata", {
      detail: {
        content: { metadata: this.metadataValue },
      },
    });
  }
}
