import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["source", "visible", "hidden", "copy"];

  connect() {
    this.visible = false;

    navigator.permissions.query({ name: "clipboard-write" }).then((result) => {
      if (result.state === "granted" || result.state === "prompt") {
        console.info("Clipboard write access granted");
      }
    });
  }

  copy() {
    navigator.clipboard.writeText(this.sourceTarget.value).then(() => {
      console.log(this.copyTarget);
      this.copyTarget.classList.add("bg-green-300");
      this.copyTarget.classList.add("hover:bg-green-300");
      this.copyTarget.disabled = true;

      setTimeout(() => {
        this.copyTarget.classList.remove("bg-green-300");
        this.copyTarget.classList.remove("hover:bg-green-300");
        this.copyTarget.disabled = false;
      }, 2000);
    });
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
