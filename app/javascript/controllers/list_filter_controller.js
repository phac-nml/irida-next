import { Controller } from "@hotwired/stimulus";

// Key code constants for keyboard events.
const BACKSPACE = 8; // Represents the backspace key.
const SPACE = 32;    // Represents the spacebar key.
const COMMA = 188;   // Represents the comma key.

export default class extends Controller {
  static targets = ["tags", "template", "input", "count"];
  static outlets = ["selection"];
  static values = { samples: Array };

  connect() {
    this.samplesValue.filter(sample => sample.length > 0).forEach(sample => {
      this.tagsTarget.insertBefore(this.#formatTag(sample), this.inputTarget);
    });
    this.#updateCount();
    this.samplesValue = [];
  }

  handleInput(event) {
    const value = event.target.value.trim();
    if (event.keyCode === BACKSPACE && value.length === 0) {
      // Handle backspace event when input is empty, otherwise just let
      this.#handleBackspace(event);
    } else if (
      value.length === 0 &&
      (event.keyCode === COMMA || event.keyCode === SPACE)
    ) {
      // Handle when a `,` is entered alone; that is do nothing
      event.preventDefault();
    } else if (event.keyCode === COMMA) {
      // If a string ends with a coma, directly add the tag
      event.preventDefault();
      this.#clearAndFocus();
      this.tagsTarget.insertBefore(this.#formatTag(value), this.inputTarget);
    }
  }

  handlePaste(event) {
    event.preventDefault();
    const data = (event.clipboardData || window.clipboardData).getData("text");
    const items = this.#getNamesAndPUID(data);
    for (const item of items) {
      this.tagsTarget.insertBefore(this.#formatTag(item), event.target);
    }
    this.#clearAndFocus();
  }

  remove({ target }) {
    const item = target.closest("span.filter-item");
    item.parentNode.removeChild(item);
  }

  clear() {
    const tags = this.tagsTarget.querySelectorAll(".search-tag");
    for (const tag of tags) {
      this.tagsTarget.removeChild(tag);
    }
    this.inputTarget.value = "";
  }

  focus() {
    this.inputTarget.focus();
  }

  afterSubmit() {
    if (this.hasSelectionOutlet) {
      this.selectionOutlet.clear();
    }
    // check to see if there is any text in the input
    if (this.inputTarget.value.length > 0) {
      this.tagsTarget.insertBefore(
        this.#formatTag(this.inputTarget.value),
        this.inputTarget,
      );
      this.inputTarget.value = "";
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
