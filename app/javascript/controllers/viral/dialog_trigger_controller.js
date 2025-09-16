import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  open() {
    console.log("open");
    this.triggeredTimestamp = Date.now();
  }
}
