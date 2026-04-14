import { Controller } from "@hotwired/stimulus";
import { focusWhenVisible } from "utilities/focus";

export default class extends Controller {
  static targets = ["heading"];

  connect() {
    if (this.hasHeadingTarget) {
      focusWhenVisible(this.headingTarget);
    }
  }

  focusField(event) {
    event.preventDefault();

    const targetId = event.params.targetId;
    const target = targetId ? document.getElementById(targetId) : null;
    if (!target) return;

    focusWhenVisible(target);
    target.scrollIntoView({ block: "center", inline: "nearest" });
  }
}
