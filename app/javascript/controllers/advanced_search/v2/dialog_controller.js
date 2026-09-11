import { Controller } from "@hotwired/stimulus";

// Host adapter for the advanced search dialog.
//
// Owns the dialog lifecycle only (open on trigger/errors, dirty-close confirmation,
// re-render after Turbo morph) and delegates all node/DOM work to the host-agnostic
// builder controller through the advanced-search--v2--builder outlet.
export default class AdvancedSearchDialogController extends Controller {
  static outlets = ["advanced-search--v2--builder"];
  static values = {
    confirmCloseText: String,
    hasErrors: Boolean,
    open: Boolean,
    status: Boolean,
  };

  connect() {
    this.boundOnMorph = this.onMorph.bind(this);
    document.addEventListener("turbo:morph", this.boundOnMorph);
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.boundOnMorph);
  }

  advancedSearchV2BuilderOutletConnected() {
    this.renderSearchIfOpen();
  }

  renderSearchIfOpen() {
    if (this.openValue) {
      this.renderSearch();
    }
  }

  onMorph() {
    this.renderSearchIfOpen();
  }

  renderSearch() {
    if (this.hasAdvancedSearchV2BuilderOutlet) {
      this.advancedSearchV2BuilderOutlet.render();
    }
  }

  clearForm() {
    if (this.hasAdvancedSearchV2BuilderOutlet) {
      this.advancedSearchV2BuilderOutlet.clearForm();
    }
  }

  close(event) {
    if (this.hasErrorsValue) {
      event.preventDefault();
      event.stopImmediatePropagation();
      this.#focusFirstInvalidField();
      return;
    }

    if (!this.statusValue) {
      this.renderSearch();
      return;
    }

    if (event instanceof KeyboardEvent && event.type === "keydown") {
      event.preventDefault();
      event.stopImmediatePropagation();
      return;
    }

    if (!this.#dirty()) {
      this.#clear();
    } else if (window.confirm(this.confirmCloseTextValue)) {
      this.#clear();
    } else {
      event.stopImmediatePropagation();
      event.preventDefault();
    }
  }

  #dirty() {
    return this.hasAdvancedSearchV2BuilderOutlet
      ? this.advancedSearchV2BuilderOutlet.isDirty()
      : false;
  }

  #clear() {
    if (this.hasAdvancedSearchV2BuilderOutlet) {
      this.advancedSearchV2BuilderOutlet.clear();
    }
  }

  #focusFirstInvalidField() {
    const invalidField = Array.from(
      this.element.querySelectorAll("[aria-invalid='true']"),
    ).find((field) => !field.disabled && field.offsetParent !== null);

    invalidField?.focus();
  }
}
