import { Controller } from "@hotwired/stimulus";

// creates a table listing all the selected files
export default class extends Controller {
  static targets = ["field"];

  connect() {
    const table = document.getElementById("attachments-table");

    const newTable = document.createElement("table");
    newTable.classList = table.classList;

    const headers = table.getElementsByTagName("th");
    const headersIndex = [];
    for (let header of headers) {
      if (["Filename", "Type", "Size"].includes(header.innerText)) {
        headersIndex.push(header.cellIndex);
      }
    }

    const body = table.getElementsByTagName("tbody")[0];
    for (let row of body.rows) {
      const isChecked = row.cells[0].children[0].checked;

      if (isChecked) {
        const newRow = newTable.insertRow(-1);
        newRow.classList = row.classList;

        for (let cell of row.cells) {
          if (headersIndex.includes(cell.cellIndex)) {
            const newCell = cell;
            newRow.append(newCell.cloneNode(true));
          }
        }
      }
    }

    const newBody = newTable.getElementsByTagName("tbody")[0];
    newBody.classList = body.classList;

    this.fieldTarget.appendChild(newTable);
  }
}
