import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  connect() {}

  idempotentConnect() {}

  submit() {
    this.element.requestSubmit();
  }
}
