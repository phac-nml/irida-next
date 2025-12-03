import { Controller } from "@hotwired/stimulus";

// Notifies nextflow/samplesheet_controller.js that the samplesheet has rendered
export default class extends Controller {
  connect() {
    this.notify();
  }

  notify() {
    this.dispatch("notify");
  }
}
