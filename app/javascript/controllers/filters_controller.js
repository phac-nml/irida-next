import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

// Connects to data-controller="filters"
export default class extends Controller {
  static outlets = ["selection"];

  submit() {
    this.element.requestSubmit();
    if (this.hasSelectionOutlet) {
      this.selectionOutlet.clear();
    }
  }
}
