import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "visible", "hidden"];
  connect() {
    console.log("Hello, Stimulus!", this.element);
    this.visible = false;

    navigator.permissions.query({ name: "clipboard-write" }).then((result) => {
      if (result.state === "granted" || result.state === "prompt") {
        console.info("Clipboard write access granted");
      }
    });
  }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value);
  }

  toggle() {
    if (this.visible) {
      this.visibleTarget.classList.remove("hidden");
      this.hiddenTarget.classList.add("hidden");
      this.visible = false;
    } else {
      console.log("Was not visible");
      this.visibleTarget.classList.add("hidden");
      this.hiddenTarget.classList.remove("hidden");
      this.visible = true;
    }
  }
}
