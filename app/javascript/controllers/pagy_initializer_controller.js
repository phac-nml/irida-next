import { Controller } from "@hotwired/stimulus";
import Pagy from "pagy";  // if using sprockets, you can remove above line, but make sure you have the appropriate directive if your manifest.js file.

export default class extends Controller {
  connect() {
    Pagy.init(this.element);
  }
}