import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["tags", "template", "input", "count"];
  static outlets = ["selection"];
  static values = { filters: { type: Array, default: [] } };

  connect() {
    this.idempotentConnect();
  }

  idempotentConnect() {
    this.clear();

    this.filtersValue
      .filter(Boolean)
      .forEach((value) =>
        this.tagsTarget.insertBefore(this.#formatTag(value), this.inputTarget),
      );

    this.#updateCount();
  }

  handleInput(event) {
    if (event.isComposing) return;
    const value = event.target.value.trim();
    if (event.key === "Backspace" && value.length === 0) {
      // Handle backspace event when input is empty, otherwise just let
      this.#handleBackspace(event);
    } else if (value.length === 0 && (event.key === "," || event.key === " ")) {
      // Handle when a `,` is entered alone; that is do nothing
      event.preventDefault();
    } else if (event.key === ",") {
      // If a string ends with a coma, directly add the tag
      event.preventDefault();
      this.#clearAndFocus();
      this.tagsTarget.insertBefore(this.#formatTag(value), this.inputTarget);
    }
  }

  handlePaste(event) {
    event.preventDefault();
    const data = (event.clipboardData || window.clipboardData).getData("text");
    const values = this.#getValues(data);
    for (const value of values) {
      this.tagsTarget.insertBefore(this.#formatTag(value), event.target);
    }
    this.#clearAndFocus();
  }

  remove({ target }) {
    const item = target.closest("span.filter-item");
    item.parentNode.removeChild(item);
  }

  clear() {
    this.#clearTags();
    this.inputTarget.value = "";
  }

  focus() {
    this.inputTarget.focus();
  }

  afterSubmit() {
    if (this.hasSelectionOutlet) {
      this.selectionOutlet.clear();
    }

    // Get all the text in the tagsTarget
    const inputs = this.tagsTarget.querySelectorAll("input");
    const text = Array.from(inputs)
      .filter(Boolean)
      .map((tag) => tag.value);
    this.filtersValue = text;

    this.#updateCount();
  }

  afterClose() {
    this.clear();
  }

  #clearTags() {
    while (this.tagsTarget.firstChild !== this.inputTarget) {
      this.tagsTarget.firstChild.remove();
    }
  }

  #handleBackspace(event) {
    const tags = this.tagsTarget.querySelectorAll("span.search-tag");
    if (tags.length === 0) return;
    event.preventDefault();
    const last = tags[tags.length - 1];
    const text = last.querySelector(".label").textContent;
    this.tagsTarget.removeChild(last);
    this.inputTarget.value = text;
  }

  #getValues(value) {
    return value
      .split(/\r?\n|,/)
      .map((t) => t.trim())
      .filter(Boolean);
  }

  #clearAndFocus() {
    this.inputTarget.value = "";
    this.inputTarget.focus();
  }

  #formatTag(value) {
    const clone = this.templateTarget.content.cloneNode(true);
    const input = clone.querySelector("input");

    clone.querySelector(".label").textContent = value;
    input.value = value;

    return clone;
  }

  #updateCount() {
    if (this.hasCountTarget) {
      const count = this.filtersValue.filter(Boolean).length;
      this.countTarget.textContent = count;
      this.countTarget.classList.toggle("hidden", count === 0);
      this.countTarget.classList.toggle("inline-flex", count > 0);
    }
  }
}
