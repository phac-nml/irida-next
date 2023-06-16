import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static values = { compare: String };
  static targets = ["confirm"];
  connect() {
    console.log("Hello, Stimulus! -WHA", this.compareValue);
  }

  inputChanged(event) {
    console.log(event.target.value, this.compareValue);
    if (event.target.value === this.compareValue) {
      this.confirmTarget.removeAttribute("disabled");
    } else {
      this.confirmTarget.setAttribute("disabled", "disabled");
    }
  }
}
