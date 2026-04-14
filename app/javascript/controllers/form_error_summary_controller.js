import { Controller } from "@hotwired/stimulus";
import { focusWhenVisible } from "utilities/focus";

export default class extends Controller {
  connect() {
    focusWhenVisible(this.element);
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
