import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field"];

  connect() {
    const checkboxes = document.querySelectorAll(
      "input[name='attachment_ids[]']:checked"
    );
    const newTable = document.createElement("table");
    newTable.classList.add("w-full");

    for (var i = 0; i < checkboxes.length; i++) {
      const newRow = newTable.insertRow(-1);
      newRow.insertCell(-1).innerHTML = checkboxes[i].dataset.name;
      newRow.insertCell(-1).innerHTML = checkboxes[i].dataset.size;
      newRow.insertCell(-1).innerHTML = checkboxes[i].dataset.type;
    }

    this.fieldTarget.appendChild(newTable);
  }
}
