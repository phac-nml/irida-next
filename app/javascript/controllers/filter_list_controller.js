import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

export default class extends Controller {
  static targets = ["tags", "template", "input", "count"];
  static outlets = ["selection"];

  handleInput(event) {
    if (event.data === "" || event.data === " ") return;

    if (event.inputType === "insertFromPaste" || event.data === ",") {
      const items = this.#getNamesAndPUID(event);
      items.forEach((item) =>
        this.tagsTarget.insertBefore(this.#formatTag(item), event.target),
      );
      this.#clearAndFocus(event);
    } else {
      this.#addDelayed(event);
    }
  }

  remove({ target }) {
    const item = target.closest("span.filter-item");
    item.parentNode.removeChild(item);
  }

  clear() {
    const tags = this.tagsTarget.querySelectorAll(".search-tag");
    [...tags].forEach((tag) => this.tagsTarget.removeChild(tag));
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
    clone.querySelector("input").id = Date.now().toString(36);
    return clone;
  }

  #addDelayed = _.debounce((event) => {
    this.tagsTarget.insertBefore(
      this.#formatTag(event.target.value),
      event.target,
    );
    this.#clearAndFocus(event);
  }, 1000);

  #updateCount() {
    const count = this.tagsTarget.querySelectorAll(".search-tag").length;
    if (count > 0) {
      this.countTarget.innerText = count;
      this.countTarget.classList.remove("hidden");
      this.countTarget.classList.add("inline-flex");
    } else {
      this.countTarget.classList.remove("inline-flex");
      this.countTarget.classList.add("hidden");
    }
  }
}
