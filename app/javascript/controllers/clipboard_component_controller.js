import { Controller } from "@hotwired/stimulus";
import { Tooltip } from "flowbite";

export default class extends Controller {
  static targets = ["source", "visible", "hidden", "submit"];

  connect() {
    this.visible = false;

    navigator.permissions.query({ name: "clipboard-write" }).then((result) => {
      if (result.state === "granted" || result.state === "prompt") {
        console.info("Clipboard write access granted");
      }
    });
  }

  copy() {
    console.log(this.submitTarget);
    navigator.clipboard.writeText(this.sourceTarget.value).then(function () {
      console.log("Copied to clipboard");
      const tooltip = new Tooltip(this.submitTarget, {
        placement: "bottom",
        triggerType: "hover",
      });
      tooltip.show();
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
