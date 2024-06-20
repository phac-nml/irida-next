import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    ignore: [],
  };

  connect() {
    console.log("Ignored", this.ignoreValue);
    this.element.addEventListener("change", this.handleFileChange.bind(this));
  }

  disconnect() {
    this.element.removeEventListener(
      "change",
      this.handleFileChange.bind(this),
    );
  }

  handleFileChange(event) {
    const files = Array.from(event.target.files).filter(
      (file) => !file.name.match(this.ignoreValue),
    );
    this.element.dispatchEvent(
      new CustomEvent("filechange", {
        detail: { files },
        bubbles: true,
      }),
    );
  }
}
