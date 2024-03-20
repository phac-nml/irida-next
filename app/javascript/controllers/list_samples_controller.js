import { Controller } from "@hotwired/stimulus";

// creates a table listing all the selected samples
export default class extends Controller {
  static targets = ["field"];

  connect() {
    const table = document.getElementById("samples-table");
    const body = table.getElementsByTagName("tbody")[0];
    const newTable = document.createElement("table");
    newTable.classList = table.classList;

    for (let row of body.rows) {
      const isChecked = row.cells[0].children[0].checked;

      if (isChecked) {
        const newRow = newTable.insertRow(-1);
        newRow.classList = row.classList;

        for (let cell of row.cells) {
          // copy sample id and name
          if ([1,2].includes(cell.cellIndex)) {
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
