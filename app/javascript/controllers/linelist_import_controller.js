import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {
    this.worker = null;
  }

  submit(event) {
    event.preventDefault();
    event.stopPropagation();
    this.startImport();
  }

  startImport() {
    console.log("Starting linelist import...");
  }
}
