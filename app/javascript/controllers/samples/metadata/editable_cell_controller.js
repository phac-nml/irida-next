import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["formTemplate"];

  submit(event) {
    let tableCell = event.target.parentNode;
    let form = this.formTemplateTarget.innerHTML
      .replace(/SAMPLE_ID_PLACEHOLDER/g, event.target.dataset.sampleId)
      .replace(/FIELD_ID_PLACEHOLDER/g, event.target.dataset.field);
    tableCell.insertAdjacentHTML("beforeend", form);
    tableCell.getElementsByTagName("form")[0].requestSubmit();
  }
}
