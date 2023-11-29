import { Controller } from "@hotwired/stimulus";

// creates a table listing all the selected files
export default class extends Controller {
  static targets = ["field"];

  connect() {
    const checkboxes = document.querySelectorAll(
      "input[name='attachment_ids[]']:checked"
    );
    const newTable = document.createElement("table");
    newTable.classList.add(
      "w-full",
      "text-sm",
      "text-left",
      "text-slate-500",
      "dark:text-slate-400"
    );

    for (var i = 0; i < checkboxes.length; i++) {
      const newRow = newTable.insertRow(-1);
      this.#addCell(newRow, checkboxes[i].dataset.name);
      this.#addCell(newRow, checkboxes[i].dataset.type);
      this.#addCell(newRow, checkboxes[i].dataset.size);
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
    const cell = row.insertCell(-1);
    if (typeof value === "string") {
      cell.innerHTML = value;
    } else {
      cell.append(value);
    }
    cell.classList.add("px-6", "py-4");
  }
}
