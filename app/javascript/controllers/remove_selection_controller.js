import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    id: String,
  };

  removeItemFromSelection() {
    this.dispatch("removeItemFromStorage", {
      detail: {
        id: this.idValue,
      },
    });
  }
}
