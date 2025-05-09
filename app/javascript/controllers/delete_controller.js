import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static outlets = ["selection"];
  static values = {
    id: String,
  };

  removeItemFromSelection() {
    this.selectionOutlet.remove({ params: { id: this.idValue } })();
  }
}
