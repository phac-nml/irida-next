import { Controller } from "@hotwired/stimulus";

// creates a table listing all selected metadata for deletion
export default class extends Controller {
  static targets = ["tableBody"];

  connect() {
    const body = document.getElementById("samples-table");

    for (let row of body.rows) {
      const isChecked = row.cells[0].children[0].checked;

      if (isChecked) {
        const newRow = this.tableBodyTarget.insertRow(-1);
        newRow.classList = row.classList;

        for (let cell of row.cells) {
          // Copies puid and name
          if ([0, 1].includes(cell.cellIndex)) {
            let clone = cell.cloneNode(true)
            if (clone.children[0].type == "checkbox") {
              clone.children[0].remove()
            }
            newRow.append(clone);
          }
        }
      }
    }
  }
}
