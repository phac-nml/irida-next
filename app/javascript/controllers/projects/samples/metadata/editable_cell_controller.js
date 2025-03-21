import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["formTemplate"];

  submit(event) {
    let tableCell = event.target.parentNode;
    let form = this.formTemplateTarget.innerHTML
      .replace(/URL_PLACEHOLDER/g, event.target.dataset.url)
      .replace(/FIELD_PLACEHOLDER/g, event.target.dataset.field);
    tableCell.insertAdjacentHTML("beforeend", form);
    tableCell.getElementsByTagName("form")[0].requestSubmit();
  }
}
