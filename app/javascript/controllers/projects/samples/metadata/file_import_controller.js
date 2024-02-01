import { Controller } from "@hotwired/stimulus";
import * as XLSX from "xlsx";

export default class extends Controller {
  static targets = ["selectInput", "submitButton"];

  #disabled_classes = [
    "bg-gray-50",
    "border",
    "border-gray-300",
    "text-gray-900",
    "text-sm",
    "rounded-lg",
    "focus:ring-blue-500",
    "focus:border-blue-500",
    "block",
    "w-full",
    "p-2.5",
    "dark:bg-gray-700",
    "dark:border-gray-600",
    "dark:placeholder-gray-400",
    "dark:text-white",
    "dark:focus:ring-blue-500",
    "dark:focus:border-blue-500",
  ];

  connect() {
    this.#disableSelectInput();
    this.submitButtonTarget.disabled = true;
  }

  toggleSubmitButton(event) {
    const { value } = event.target;
    this.submitButtonTarget.disabled = !value;
  }

  readFile(event) {
    const { files } = event.target;

    if (!files.length) {
      this.#removeSelectOptions();
      return;
    }

    const reader = new FileReader();
    reader.readAsArrayBuffer(files[0]);

    reader.onload = () => {
      const workbook = XLSX.read(reader.result, { sheetRows: 1 });
      const worksheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[worksheetName];
      const headers = XLSX.utils.sheet_to_json(worksheet, { header: 1 })[0];
      this.#removeSelectOptions();
      this.#addSelectOptions(headers);
    };
  }

  #removeSelectOptions() {
    while (this.selectInputTarget.options.length > 1) {
      this.selectInputTarget.remove(this.selectInputTarget.options.length - 1);
    }
    this.#disableSelectInput();
    this.submitButtonTarget.disabled = true;
  }

  #addSelectOptions(headers) {
    for (var header of headers) {
      const option = document.createElement("option");
      option.value = header;
      option.text = header;
      this.selectInputTarget.append(option);
    }
    this.selectInputTarget.disabled = false;
    this.selectInputTarget.classList.remove(...this.#disabled_classes);
  }

  #disableSelectInput() {
    this.selectInputTarget.disabled = true;
    this.selectInputTarget.classList.add(...this.#disabled_classes);
  }
}
