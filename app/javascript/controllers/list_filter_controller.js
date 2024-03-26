import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

export default class extends Controller {
  static targets = ["tags", "template", "input", "count"];
  static outlets = ["selection"];

  handleInput(event) {
    const value = event.target.value.trim();

    if (event.keyCode === 8 && value.length === 0) {
      // Handle backspace event
      this.#handleBackspace(event);
    } else if (value.length === 0 && event.keyCode === 188) {
      // Handle when a `,` is entered alone
      event.preventDefault();
    } else if (event.keyCode === 86 && event.ctrlKey === true) {
      // Skip handling paste, this gets handled by the paste event
      return;
    } else if (event.keyCode === 188) {
      // If string ends with a coma, directly add the tag without debounce
      event.preventDefault();
      this.#clearAndFocus();
      this.#addDelayed.cancel();
      this.tagsTarget.insertBefore(this.#formatTag(value), this.inputTarget);
    } else {
      // Just text entered so debounce the value incase user adds more text
      this.#addDelayed();
    }
  }

  handlePaste(event) {
    event.preventDefault();
    const data = (event.clipboardData || window.clipboardData).getData("text");
    const items = this.#getNamesAndPUID(data);
    items.forEach((item) =>
      this.tagsTarget.insertBefore(this.#formatTag(item), event.target),
    );
    this.#clearAndFocus();
  }

  remove({ target }) {
    const item = target.closest("span.filter-item");
    item.parentNode.removeChild(item);
  }

  clear() {
    const tags = this.tagsTarget.querySelectorAll(".search-tag");
    [...tags].forEach((tag) => this.tagsTarget.removeChild(tag));
    this.inputTarget.value = "";
  }

  focus() {
    this.inputTarget.focus();
  }

  afterSubmit() {
    if (this.hasSelectionOutlet) {
      this.selectionOutlet.clear();
    }
    this.#updateCount();
  }

  #handleBackspace(event) {
    const tags = this.tagsTarget.querySelectorAll("span.search-tag");
    if (tags.length === 0) return;
    const last = tags[tags.length - 1];
    const text = last.querySelector(".label").innerText;
    this.tagsTarget.removeChild(last);
    this.inputTarget.value = text;
    this.#addDelayed();
  }

  #getNamesAndPUID(value) {
    return value
      .split(/\r?\n|,/)
      .map((t) => t.trim())
      .filter(Boolean);
  }

  #clearAndFocus() {
    this.inputTarget.value = "";
    this.inputTarget.focus();
  }

  #formatTag(item) {
    const clone = this.templateTarget.content.cloneNode(true);
    clone.querySelector(".label").innerText = item;
    clone.querySelector("input").value = item;
    clone.querySelector("input").id = Date.now().toString(36);
    return clone;
  }

  #addDelayed = _.debounce(() => {
    const value = this.inputTarget.value.trim();
    if (value.length > 0 && value !== ",") {
      this.tagsTarget.insertBefore(this.#formatTag(value), this.inputTarget);
      this.#clearAndFocus();
    }
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
