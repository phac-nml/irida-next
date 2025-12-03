import { Controller } from "@hotwired/stimulus";

// Triggers nextflow/samplesheet/params_controller to submit once schema has been processed
export default class extends Controller {
  static values = {
    schema: { type: Object },
  };

  static outlets = ["nextflow--samplesheet--params"];

  nextflowSamplesheetParamsOutletConnected() {
    this.nextflowSamplesheetParamsOutlet.submitSamplesheetParams(
      this.schemaValue,
    );
  }
}
