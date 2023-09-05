import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle"];

  /**
   * Toggle the group row to expose children content
   * @param event
   */
  toggle(event) {
    if (event.target.tagName !== "A") {
      this.toggleTarget.click();
    }
  }
}
