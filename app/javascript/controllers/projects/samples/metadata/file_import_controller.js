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
    const { target } = event;
    const { value } = target;
    if (value) {
      this.submitButtonTarget.disabled = false;
    } else {
      this.submitButtonTarget.disabled = true;
    }
  }

  #readFile(event) {
    const { target } = event;
    const { files } = target;

    if (!files.length) return;

    let reader = new FileReader();
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
    for (let header of headers) {
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
