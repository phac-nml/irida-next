import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

// Connects to data-controller="filters"
export default class extends Controller {
  initialize() {
    this.submit = this.submit.bind(this)
  }

  connect() {
    this.submit = _.debounce(this.submit, 1000);
  }

  submit() {
    this.element.requestSubmit();
  }
}
