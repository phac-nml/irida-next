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
      const name = checkboxes[i].dataset.name;
      newRow.insertCell(-1).innerHTML = name ? name : "";
      const size = checkboxes[i].dataset.size;
      newRow.insertCell(-1).innerHTML = size ? size : "";
      const type = checkboxes[i].dataset.type;
      newRow.insertCell(-1).innerHTML = type ? type : "";

      if (checkboxes[i].dataset.attachmentName) {
        const newRow = newTable.insertRow(-1);
        const attachmentName = checkboxes[i].dataset.attachmentName;
        newRow.insertCell(-1).innerHTML = attachmentName ? attachmentName : "";
        const attachmentSize = checkboxes[i].dataset.attachmentSize;
        newRow.insertCell(-1).innerHTML = attachmentSize ? attachmentSize : "";
        const attachmentType = checkboxes[i].dataset.type;
        newRow.insertCell(-1).innerHTML = attachmentType ? attachmentType : "";
      }
    }

    const body = newTable.querySelector("tbody");
    body.classList.add(
      "divide-y",
      "divide-slate-200",
      "dark:bg-slate-800",
      "dark:divide-slate-700"
    );

    this.fieldTarget.appendChild(newTable);
  }
}
