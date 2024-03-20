import { Controller } from "@hotwired/stimulus";

// creates a table listing all the selected samples
export default class extends Controller {
  static targets = ["field"];

  #td_classes = ["bg-slate-50", "dark:bg-slate-900", "left-0", "left-12", "sticky"];

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
          if ([1, 2].includes(cell.cellIndex)) {
            const clone = cell.cloneNode(true);
            const link = clone.querySelector("a");
            link.classList.remove("font-semibold");
            const span = link.querySelector("span");
            span.classList.remove("font-semibold");
            clone.classList.remove(...this.#td_classes);
            newRow.append(clone);
          }
        }
      }
    }

    const newBody = newTable.getElementsByTagName("tbody")[0];
    newBody.classList = body.classList;
    this.fieldTarget.appendChild(newTable);
  }
}
