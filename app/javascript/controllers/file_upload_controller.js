import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["alert", "error"];
  static values = {
    ignore: [],
  };
  #ignoreRegex;

  connect() {
    this.#ignoreRegex = new RegExp(
      this.ignoreValue.map((a) => a.replace(".", "")).join("$|") + "$",
    );
  }

  handleFileChange(event) {
    const files = Array.from(event.target.files);
    const dt = new DataTransfer();
    const ignoreFiles = [];

    files.forEach((file) => {
      if (!file.name.match(this.#ignoreRegex)) {
        dt.items.add(file);
      } else {
        ignoreFiles.push(file);
      }
    });
    event.target.files = dt.files;

    if (ignoreFiles.length > 0 && this.hasAlertTarget) {
      this.errorTarget.textContent = ignoreFiles
        .map((file) => file.name)
        .join(", ");
      this.alertTarget.classList.remove("hidden");
    } else {
      this.alertTarget.classList.add("hidden");
    }
  }
}
