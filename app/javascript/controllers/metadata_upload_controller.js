import { Controller } from "@hotwired/stimulus";
import * as XLSX from "xlsx";

export default class extends Controller {
  static targets = ["fileInput"];

  connect() {
    this.fileInputTarget.addEventListener("change", (event) => {
      this.readFile(event);
    });
  }

  readFile(event) {
    const { target } = event;
    const { files } = target;

    let reader = new FileReader();
    reader.readAsArrayBuffer(files[0]);

    reader.onload = function () {
      const workbook = XLSX.read(reader.result, { sheetRows: 1 });
      const worksheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[worksheetName];
      const headers = XLSX.utils.sheet_to_json(worksheet, { header: 1 })[0];
      console.log(headers);
    };

    reader.onerror = function () {
      console.log("ERROR");
      console.log(reader.error);
    };
  }

  disconnect() {
    this.fileInputTarget.removeEventListener("change", (event) => {
      this.readFile(event);
    });
  }
}
