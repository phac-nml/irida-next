import { Controller } from "@hotwired/stimulus";

// Sends sampleAttributes and allowedToUpdateSamples to nextflow/samplesheet_controller.js
export default class extends Controller {
  static values = {
    allowedToUpdateSamples: { type: Boolean },
    sampleAttributes: { type: Object },
  };

  retrieveSampleAttributes() {
    // clear the now unneeded DOM element
    this.element.remove();
    return {
      allowedToUpdateSamples: this.allowedToUpdateSamplesValue,
      sampleAttributes: this.sampleAttributesValue,
    };
  }
}
