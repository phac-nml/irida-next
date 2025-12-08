import { Controller } from "@hotwired/stimulus";

// Triggers nextflow/samplesheet/params_controller to submit once properties has been processed
export default class extends Controller {
  static values = {
    properties: { type: Object },
  };

  static outlets = ["nextflow--samplesheet--params"];

  nextflowSamplesheetParamsOutletConnected() {
    this.nextflowSamplesheetParamsOutlet.submitSamplesheetParams(
      this.propertiesValue,
    );
  }
}
