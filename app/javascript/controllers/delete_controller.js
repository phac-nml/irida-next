import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = {
    id: String,
  };

  removeItemFromSelection() {
    console.log("delete_controller");
    console.log(this.idValue);
    this.dispatch("removeItemFromLocalStorage", {
      detail: {
        id: this.idValue,
      },
    });
  }
}
