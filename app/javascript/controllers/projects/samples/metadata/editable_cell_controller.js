import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["formTemplate"];

  submit(event) {
    let form = this.formTemplateTarget.innerHTML
      .replace(/URL_PLACEHOLDER/g, event.target.dataset.url)
      .replace(/FIELD_PLACEHOLDER/g, event.target.dataset.field);
    event.target.parentNode.insertAdjacentHTML("beforeend", form);
    this.element.getElementsByTagName("form")[0].requestSubmit();
  }
}
