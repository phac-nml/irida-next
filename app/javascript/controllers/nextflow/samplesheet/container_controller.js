import { Controller } from "@hotwired/stimulus";

// Handles sending metadata to samplesheet after metadata selection
export default class extends Controller {
  connect() {
    this.test();
  }

  test() {
    this.dispatch("test", {
      detail: {
        content: "hi",
      },
    });
  }
}
