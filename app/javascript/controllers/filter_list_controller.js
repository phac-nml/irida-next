import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

export default class extends Controller {
  static targets = ["tags", "template", "input", "count"];
  static outlets = ["selection"];

  handleInput(event) {
    if (event.data === "") return;

    if (event.inputType === "insertFromPaste") {
      const items = this.#getNamesAndPUID(event);
      items.forEach((item) =>
        this.tagsTarget.insertBefore(this.#formatTag(item), event.target),
      );
      this.#clearAndFocus(event);
    } else {
      const value = event.target.value.replace(",", "");
      this.#addDelayed(value, event);
    }
  }

  remove(event) {
    const item = event.target.closest("span.filter-item");
    item.parentNode.removeChild(item);
  }

  focus() {
    this.inputTarget.focus();
  }

  afterSubmit() {
    this.selectionOutlet.clear();
    this.#updateCount();
  }

  #getNamesAndPUID(event) {
    return event.target.value
      .split(",")
      .map((t) => t.trim())
      .filter(Boolean);
  }

  #clearAndFocus(event) {
    event.target.value = "";
    event.target.focus();
  }

  #formatTag(item) {
    const clone = this.templateTarget.content.cloneNode(true);
    clone.querySelector(".label").innerText = item;
    clone.querySelector("input").value = item;
    return clone;
  }

  #addDelayed = _.debounce((value, event) => {
    this.tagsTarget.insertBefore(this.#formatTag(value), event.target);
    this.#clearAndFocus(event);
  }, 1000);

  #updateCount() {
    const count = this.tagsTarget.querySelectorAll(".search-tag").length;
    console.log({ count });
    this.countTarget.innerText = count;
  }
}
