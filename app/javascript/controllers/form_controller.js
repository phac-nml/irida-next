import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["field"];

  connect() {
    const storageValue = sessionStorage.getItem(
      location.protocol + "//" + location.host + location.pathname
    );
    this.fieldTarget.value = storageValue;
  }
}
