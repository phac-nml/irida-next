import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    ids: Array,
  };
  static outlets = ["selection"];

  connect() {
    this.selectionOutlet.update(this.idsValue);
  }
}
