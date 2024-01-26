import { Controller } from "@hotwired/stimulus";
import * as XLSX from "xlsx";

export default class extends Controller {
  static targets = ["fileInput", "selectInput", "submitButton"];

  connect() {
    this.fileInputTarget.addEventListener("change", (event) => {
      this.#readFile(event);
    });
    this.selectInputTarget.addEventListener("change", (event) => {
      this.#toggleSubmitButton(event);
    });
  }

  #toggleSubmitButton(event) {
    const { value } = event.target;
    this.submitButtonTarget.disabled = !value;
  }

  #readFile(event) {
    const { files } = event.target;

    if (!files.length) return;

    //TODO: check file extension?
    //TODO: clear select options before population

    const reader = new FileReader();
    reader.readAsArrayBuffer(files[0]);

    reader.onload = () => {
      const workbook = XLSX.read(reader.result, { sheetRows: 1 });
      const worksheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[worksheetName];
      const headers = XLSX.utils.sheet_to_json(worksheet, { header: 1 })[0];
      this.#addSelectOptions(headers);
    };
  }

  #addSelectOptions(headers) {
    for (var header of headers) {
      const option = document.createElement("option");
      option.value = header;
      option.text = header;
      this.selectInputTarget.appendChild(option);
    }
  }

  disconnect() {
    this.fileInputTarget.removeEventListener("change", (event) => {
      this.#readFile(event);
    });
    this.selectInputTarget.removeEventListener("change", (event) => {
      this.#toggleSubmitButton(event);
    });
  }
}
