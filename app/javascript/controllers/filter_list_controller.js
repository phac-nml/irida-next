import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tags", "success"];
  connect() {
    console.log(this.tagsTarget);
  }

  handleInput(event) {
    if (event.data === " ") return;
    console.log(event.data);

    if (event.inputType === "insertFromPaste") {
      const items = this.#getNamesAndPUID(event);
      items.forEach((value) =>
        this.tagsTarget.insertBefore(this.#formatTag(value), event.target),
      );
      event.target.value = "";
      event.target.focus();
    } else if (event.data === ",") {
      const value = event.target.value.replace(",", "");
      this.tagsTarget.insertBefore(this.#formatTag(value), event.target);
      event.target.value = "";
      event.target.focus();
    } else {
      console.log("Waiting...need to debounce here", event);
    }
  }

  handlePaste(event) {
    console.log("PASTE", event);
  }

  #getNamesAndPUID(event) {
    return event.target.value
      .split(",")
      .map((t) => t.trim())
      .filter(Boolean);
  }

  #formatTag(item) {
    const clone = this.successTarget.content.cloneNode(true);
    clone.querySelector(".label").innerText = item;
    clone.querySelector("input").value = item;
    return clone;
  }
}
