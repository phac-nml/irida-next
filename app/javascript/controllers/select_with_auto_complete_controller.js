import { Controller } from "@hotwired/stimulus";
import TomSelect from "tom-select";

export default class SelectWithAutoCompleteController extends Controller {
  connect() {
    console.debug("SelectWithAutoCompleteController: Connected");
    new TomSelect(this.element);
  }

  disconnect() {
    console.debug("SelectWithAutoCompleteController: Disconnected");
    if (this.element.tomselect) {
      this.element.tomselect.destroy();
    }
  }
}
