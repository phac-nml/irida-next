import { Controller } from "@hotwired/stimulus";

// creates a table listing all the selected files
export default class extends Controller {
  static targets = ["field"];

  connect() {
    const body = document.getElementById("attachments-table-body");
    const table = body.parentElement;
    const newTable = document.createElement("table");
    newTable.classList = table.classList;

    for (let row of body.rows) {
      const isChecked = row.cells[0].children[0].checked;

      if (isChecked) {
        const newRow = newTable.insertRow(-1);
        newRow.classList = row.classList;

        for (let cell of row.cells) {
          // copy file name, type, and sze
          if ([1, 3, 4].includes(cell.cellIndex)) {
            newRow.append(cell.cloneNode(true));
          }
        }
      }
    }

    const newBody = newTable.getElementsByTagName("tbody")[0];
    newBody.classList = body.classList;
    this.fieldTarget.appendChild(newTable);
  }
}
