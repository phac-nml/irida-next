import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field"];

  connect() {
    const checkboxes = document.querySelectorAll(
      "input[name='attachment_ids[]']:checked"
    );
    const newTable = document.createElement("table");
    newTable.classList.add("w-full");

    for (var i = 0; i < checkboxes.length; i++) {
      const newRow = newTable.insertRow(-1);
      this.#addCell(newRow, checkboxes[i].dataset.name);
      this.#addCell(newRow, checkboxes[i].dataset.size);
      this.#addCell(newRow, checkboxes[i].dataset.type);

      if (checkboxes[i].dataset.attachmentName) {
        const newRow = newTable.insertRow(-1);
        this.#addCell(newRow, checkboxes[i].dataset.attachmentName);
        this.#addCell(newRow, checkboxes[i].dataset.attachmentSize);
        this.#addCell(newRow, checkboxes[i].dataset.type);
      }
    }

    const body = newTable.querySelector("tbody");
    body.classList.add(
      "divide-y",
      "divide-slate-200",
      "dark:bg-slate-800",
      "dark:divide-slate-700"
    );

    this.fieldTarget.appendChild(newTable);
  }

  #addCell(row, value) {
    row.insertCell(-1).innerHTML = value ? value : "";
  }
}
