import { Controller } from "@hotwired/stimulus";

// Handles sending metadata to samplesheet after metadata selection
export default class extends Controller {
  static values = {
    schema: { type: Object },
  };

  static outlets = ["nextflow--samplesheet--params"];

  nextflowSamplesheetParamsOutletConnected() {
    console.log("conencted!");
    this.nextflowSamplesheetParamsOutlet.submitSamplesheetParams(
      this.schemaValue,
    );
  }
}
