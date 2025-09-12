import { Controller } from "@hotwired/stimulus";

// creates a table listing all selected metadata for deletion
export default class extends Controller {
    static targets = ["tableBody"];

    connect() {
        const body = document.getElementById("metadata-table-body");

        for (let row of body.rows) {
            const isChecked = row.querySelector(
              "input[type='checkbox']",
            ).checked;

            if (isChecked) {
                const newRow = this.tableBodyTarget.insertRow(-1);
                newRow.classList = row.classList;

                for (let cell of row.cells) {
                    // Copies key and value
                    if ([1, 2].includes(cell.cellIndex)) {
                        newRow.append(cell.cloneNode(true));
                    }
                }
            }
        }
    }
}
