import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field"];

  connect() {
    let table = document.getElementById("attachments-table-body");
    let newTable = document.createElement("table");

    for (var i = 0; i < table.rows.length; i++) {
      let row = table.rows[i];
      let isChecked = row.cells[0].children[0].checked;

      if (isChecked) {
        let newRow = newTable.insertRow(-1);

        for (var j = 0; j < row.cells.length; j++) {
          //only copy file name, type, and size columns
          if (j == 1 || j == 4) {
            let cell = row.cells[j];
            let newCell = newRow.insertCell(-1);
            newCell.innerHTML = cell.innerHTML;
          }
        }
      }
    }

    this.fieldTarget.appendChild(newTable);
  }
}
