import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";

export default class extends Controller {
  static values = { url: { type: String } };

  /**
   * Toggle the group row to expose children content
   * @param event
   */
  toggle() {
    get(this.urlValue, {
      responseKind: "turbo-stream",
    });
  }
}
