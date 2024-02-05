import { Controller } from "@hotwired/stimulus";

// creates a table listing all the selected files
export default class extends Controller {
    static targets = ["table"];

    connect() {
        const body = document.getElementById("metadata-table-body");
        const table = body.parentElement;

        for (let row of body.rows) {
            const isChecked = row.cells[0].children[0].checked;

            if (isChecked) {
                const newRow = this.tableTarget.insertRow(-1);
                newRow.classList = row.classList;

                for (let cell of row.cells) {
                    // copy file name, type, and sze
                    if ([1, 2].includes(cell.cellIndex)) {
                        newRow.append(cell.cloneNode(true));
                    }
                }
            }
        }

        // const newBody = this.tableTarget.getElementsByTagName("tbody")[0];
        // newBody.classList = body.classList;
        // this.fieldTarget.appendChild(this.tableTarget);
    }
}
