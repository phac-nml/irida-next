import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static outlets = ["filters"];

  connect() {
    this.filtersOutlet.submit();
  }
}
