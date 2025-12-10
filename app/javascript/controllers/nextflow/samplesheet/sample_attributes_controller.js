import { Controller } from "@hotwired/stimulus";

// Notifies nextflow/samplesheet_controller.js sample attributes are ready and samplesheet can begin processing
export default class extends Controller {
  static values = {
    allowedToUpdateSamples: { type: Boolean },
  };

  connect() {
    this.notify();
  }

  notify() {
    this.dispatch("notify", {
      detail: {
        content: { allowedToUpdateSamples: this.allowedToUpdateSamplesValue },
      },
    });
  }
}
