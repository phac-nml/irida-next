import { Controller } from "@hotwired/stimulus";

// populates confirmation dialogue with description containing number of samples and samples selected for deletion
export default class extends Controller {
  static targets = ["tableBody", "description"];

  static values = {
    storageKey: {
      type: String,
      default: location.protocol + "//" + location.host + location.pathname,
    },
    singular: {
      type: String
    },
    plural: {
      type: String
    }
  }

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
    const storageValues = JSON.parse(
      sessionStorage.getItem(this.storageKeyValue)
    )
    if (storageValues) {
      if (storageValues.length == 1) {
        this.descriptionTarget.innerHTML = this.singularValue
      } else {
        this.descriptionTarget.innerHTML = this.pluralValue.replace("COUNT_PLACEHOLDER", storageValues.length)
      }
    }
  }
}
