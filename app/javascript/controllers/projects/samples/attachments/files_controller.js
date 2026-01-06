import { Controller } from "@hotwired/stimulus";

// creates a table listing all the selected files
export default class extends Controller {
  static targets = ["field"];

  connect() {
    const body = document.getElementById("attachments-table-body");
    const table = body.parentElement;
    const newTable = document.createElement("table");
    newTable.classList = table.classList;

    for (const row of body.rows) {
      const isChecked = row.querySelector("input[type='checkbox']").checked;

      if (isChecked) {
        const newRow = newTable.insertRow(-1);
        newRow.classList = row.classList;

        for (const cell of row.cells) {
          // copy file name, type, size, and uploaded time
          if ([1, 2, 4, 5].includes(cell.cellIndex)) {
            const cloneNode = cell.cloneNode(true);
            cloneNode.classList = "px-3 py-3";
            newRow.append(cloneNode);
          }
        }
      }
    }

    const newBody = newTable.getElementsByTagName("tbody")[0];
    newBody.classList = body.classList;
    this.fieldTarget.appendChild(newTable);
  }
}
