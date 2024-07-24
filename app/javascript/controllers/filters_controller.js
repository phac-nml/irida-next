import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

// Connects to data-controller="filters"
export default class extends Controller {
  static outlets = ["selection"];

  initialize() {
    this.submit = this.submit.bind(this);
  }

  connect() {
    this.submit = _.debounce(this.submit, 500);
  }

  submit() {
    this.element.requestSubmit();
    if (this.hasSelectionOutlet) {
      this.selectionOutlet.clear();
    }
  }
}
