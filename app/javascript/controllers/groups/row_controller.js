import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["toggle"];

  connect() {
    console.log(this.element, this.toggleTarget);
  }

  toggle(event) {
    console.log("CLICKED");
    if (event.target.tagName !== "A") {
      this.toggleTarget.click();
    }
  }
}
