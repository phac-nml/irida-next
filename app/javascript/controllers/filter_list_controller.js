import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

function add_tag(item, event) {}

export default class extends Controller {
  static targets = ["tags", "success"];
  connect() {
    console.log(this.tagsTarget);
  }

  handleInput(event) {
    const data = event.data.trim();
    if (data === "") return;
    console.log(data);

    if (event.inputType === "insertFromPaste") {
      const items = this.#getNamesAndPUID(event);
      items.forEach((value) =>
        this.tagsTarget.insertBefore(this.#formatTag(value), event.target),
      );
      event.target.value = "";
      event.target.focus();
    } else if (data === ",") {
      const value = event.target.value.replace(",", "");
      if (value.length > 0) {
        // A 0 length value would be if there was just a ',' entered
        this.tagsTarget.insertBefore(this.#formatTag(value), event.target);
      }
      event.target.value = "";
      event.target.focus();
    } else {
      const value = event.target.value.replace(",", "");
      this.#addDelayed(value, event);
    }
  }

  #getNamesAndPUID(event) {
    return event.target.value
      .split(",")
      .map((t) => t.trim())
      .filter(Boolean);
  }

  #addToDOM(tag, event) {
    this.tagsTarget.insertBefore(tag, event.target);
  }

  #clearAndFocus(event) {
    event.target.value = "";
    event.target.focus();
  }

  #formatTag(item) {
    const clone = this.successTarget.content.cloneNode(true);
    clone.querySelector(".label").innerText = item;
    clone.querySelector("input").value = item;
    return clone;
  }

  #addDelayed = _.debounce((item, event) => {
    console.log(item);
  }, 1000);
}
