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
      if (checkboxes[i].dataset.attachmentName) {
        const div = document.createElement("div");
        div.innerHTML =
          checkboxes[i].dataset.name + checkboxes[i].dataset.attachmentName;
        this.#addCell(newRow, div);
      } else {
        this.#addCell(newRow, checkboxes[i].dataset.name);
      }
      this.#addCell(newRow, checkboxes[i].dataset.type);
      if (checkboxes[i].dataset.attachmentSize) {
        const parentDiv = document.createElement("div");
        const div1 = document.createElement("div");
        div1.classList.add("mb-4");
        div1.innerHTML = checkboxes[i].dataset.size;
        const div2 = document.createElement("div");
        div2.innerHTML = checkboxes[i].dataset.attachmentSize;
        parentDiv.appendChild(div1);
        parentDiv.appendChild(div2);
        this.#addCell(newRow, parentDiv);
      } else {
        this.#addCell(newRow, checkboxes[i].dataset.size);
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
    const cell = row.insertCell(-1);
    if (typeof value === "string") {
      cell.innerHTML = value;
    } else {
      cell.append(value);
    }
    cell.classList.add("px-6", "py-4");
  }
}
