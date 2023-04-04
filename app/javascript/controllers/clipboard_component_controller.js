import { Controller } from "@hotwired/stimulus";
export default class extends Controller {
  static targets = ["input", "visible", "hidden", "copy", "tooltip"];
  static values = { token: String };

  connect() {
    this.visible = false;
    navigator.permissions.query({ name: "clipboard-write" }).then((result) => {
      if (result.state === "granted" || result.state === "prompt") {
        console.info("Clipboard write access granted");
      }
    });
  }

  copy() {
    navigator.clipboard.writeText(this.tokenValue).then(() => {
      const tooltip = new Tooltip(this.tooltipTarget, this.copyTarget, {
        triggerType: "click",
      });
      tooltip.show();

      setTimeout(() => {
        tooltip.hide();
      }, 2000);
    });
  }

  toggle() {
    if (this.visible) {
      this.visibleTarget.classList.remove("hidden");
      this.hiddenTarget.classList.add("hidden");
      this.inputTarget.value = Array.prototype.join.call(
        { length: this.tokenValue.length },
        "*"
      );
      this.visible = false;
    } else {
      this.visibleTarget.classList.add("hidden");
      this.hiddenTarget.classList.remove("hidden");
      this.inputTarget.value = this.tokenValue;
      this.visible = true;
    }
  }
}
