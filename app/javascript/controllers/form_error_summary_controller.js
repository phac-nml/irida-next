import { Controller } from "@hotwired/stimulus";
import { focusWhenVisible } from "utilities/focus";
import { announce } from "utilities/live_region";

export default class extends Controller {
  static values = {
    announcement: String,
  };

  connect() {
    focusWhenVisible(this.element);

    if (this.hasAnnouncementValue) {
      announce(this.announcementValue, { politeness: "assertive" });
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
