import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["button", "content"];
  #tooltip;

  connect() {
    this.#tooltip = new Tooltip(this.contentTarget, this.buttonTarget, {
      placement: "top",
      triggerType: "none",
    });
  }

  copy(e) {
    e.stopImmediatePropagation();
    navigator.clipboard.writeText(e.target.value).then(this.#notify.bind(this));
  }

  #notify() {
    this.#tooltip.show();
    setTimeout(() => {
      this.#tooltip.hide();
    }, 1000);
  }
}
