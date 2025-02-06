import { Controller } from "@hotwired/stimulus";

// Handles sending file data to samplesheet after file selection
export default class extends Controller {
  static targets = ["input", "clear"];

  enter() {
    this.#sendFilter();
  }

  change() {
    if (this.inputTarget.value) {
      this.clearTarget.classList.remove("hidden");
    } else {
      this.clearTarget.classList.add("hidden");
    }
  }

  clear() {
    this.inputTarget.value = "";
    this.#sendFilter();
  }

  #sendFilter() {
    this.dispatch("sendFilter", {
      detail: {
        content: this.inputTarget.value,
      },
    });
  }
}
