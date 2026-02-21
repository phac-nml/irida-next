import { Controller } from "@hotwired/stimulus";
import { Turbo } from "@hotwired/turbo-rails";

export default class extends Controller {
  static values = { path: String };

  handle(event) {
    if (
      event.defaultPrevented ||
      this.#hasBlockingModal() ||
      this.#isEditableTarget(event.target)
    ) {
      return;
    }

    if (!this.#isOpenShortcut(event) && !this.#isSlashShortcut(event)) {
      return;
    }

    event.preventDefault();

    if (this.#onSearchPage()) {
      this.#focusSearchInput();
      return;
    }

    Turbo.visit(this.pathValue);
  }

  #isOpenShortcut(event) {
    return (
      (event.metaKey || event.ctrlKey) &&
      !event.altKey &&
      !event.shiftKey &&
      event.key.toLowerCase() === "k"
    );
  }

  #isSlashShortcut(event) {
    return (
      !event.metaKey &&
      !event.ctrlKey &&
      !event.altKey &&
      !event.shiftKey &&
      event.key === "/"
    );
  }

  #onSearchPage() {
    const currentPath = window.location.pathname.replace(/\/+$/, "");
    const targetPath = this.pathValue.replace(/\/+$/, "");
    return currentPath === targetPath;
  }

  #focusSearchInput() {
    const input = document.getElementById("global-search-query");
    if (!input) return;

    input.focus();
    input.select();
  }

  #hasBlockingModal() {
    return document.querySelector("dialog[open]") !== null;
  }

  #isEditableTarget(target) {
    if (!(target instanceof HTMLElement)) {
      return false;
    }

    if (target.isContentEditable) {
      return true;
    }

    return (
      target.closest("input, textarea, select, [contenteditable='true']") !==
      null
    );
  }
}
