import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

export default class extends Controller {
  static targets = ["tags", "template", "input", "count"];
  static outlets = ["selection"];

  handleInput(event) {
    if (event.keyCode === 8 && event.target.value.length === 0) {
      // Handle backspace event
      this.#handleBackspace();
    } else if (event.target.value.trim() === "") {
      return;
    } else if (event.keyCode === 86 && event.ctrlKey === true) {
      const items = this.#getNamesAndPUID(event.target.value);
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

  #handleBackspace() {
    const tags = this.tagsTarget.querySelectorAll("span.search-tag");
    if (tags.length === 0) return;
    const last = tags[tags.length - 1];
    const text = last.querySelector(".label").innerText;
    this.tagsTarget.removeChild(last);
    this.inputTarget.value = text;
  }

  #getNamesAndPUID(value) {
    return value
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
