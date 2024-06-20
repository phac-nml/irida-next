import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["error"];
  static values = {
    ignore: [],
  };

  connect() {
    console.log("Ignored", this.ignoreValue);
    this.ignoreRegex = new RegExp(
      this.ignoreValue.map((a) => a.replace(".", "")).join("$|") + "$",
    );
    console.log(this.ignoreRegex);
    this.element.addEventListener("change", this.handleFileChange.bind(this));
  }

  disconnect() {
    this.element.removeEventListener(
      "change",
      this.handleFileChange.bind(this),
    );
  }

  handleFileChange(event) {
    const files = Array.from(event.target.files);
    // Split the files into ignore and non-ignore files
    const ignoreFiles = files.filter((file) =>
      file.name.match(this.ignoreRegex),
    );
    const notIgnoredFiles = files.filter(
      (file) => !file.name.match(this.ignoreRegex),
    );

    // if (ignoreFiles.length > 0) {
    //   this.errorTarget.classList.remove("hidden");
    // }
    const fileList = new FileList();
    notIgnoredFiles.forEach((file) => {
      fileList.push(file);
    });
    this.element.files = fileList;

    console.log("Ignored files", ignoreFiles);
    console.log("Not ignored files", notIgnoredFiles);
  }
}
