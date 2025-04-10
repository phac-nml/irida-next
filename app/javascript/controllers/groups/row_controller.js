import { Controller } from "@hotwired/stimulus";
import { get } from "@rails/request.js";

export default class extends Controller {
  static targets = ["row"];
  static values = { url: { type: String } };

  /**
   * Toggle the group row to expose children content
   * @param event
   */
  toggle(event) {
    if (
      this.rowTarget.children.length == 1 ||
      !this.rowTarget.lastElementChild.contains(event.target)
    ) {
      get(this.urlValue, {
        responseKind: "turbo-stream",
      });
    }
  }
}
