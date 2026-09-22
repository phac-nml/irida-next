import { Controller } from "@hotwired/stimulus";

const toggleHidden = (element, isHidden) => {
  if (!element) return;

  element.classList.toggle("hidden", isHidden);
};

export default class extends Controller {
  static outlets = [
    "advanced-search--v1",
    "advanced-search--v2--builder",
    "selection",
  ];
  static targets = ["input", "clearButton", "submitButton"];

  clear() {
    if (!this.hasInputTarget) {
      return;
    }

    this.inputTarget.value = "";
    this.updateButtons();
    this.clearSelection();

    this.inputTarget.focus();

    const form = this.element.closest("form");
    if (form) {
      form.requestSubmit();
    }
  }

  clearSelection() {
    if (this.hasSelectionOutlet) {
      this.selectionOutlet.clear();
    }
  }

  get hasSearchContent() {
    return this.hasInputTarget && this.inputTarget.value.trim().length > 0;
  }

  handleInput() {
    this.updateButtons();
  }

  updateButtons() {
    if (!this.hasClearButtonTarget || !this.hasSubmitButtonTarget) {
      return;
    }

    const showClear = this.hasSearchContent;
    toggleHidden(this.clearButtonTarget, !showClear);
    toggleHidden(this.submitButtonTarget, showClear);
  }

  showSubmitHideClear() {
    toggleHidden(this.submitButtonTarget, false);
    toggleHidden(this.clearButtonTarget, true);
  }

  showClearHideSubmit() {
    toggleHidden(this.clearButtonTarget, false);
    toggleHidden(this.submitButtonTarget, true);
  }

  updateFocus() {
    this.inputTarget?.focus();
  }

  onFocusin(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.inputTarget?.setAttribute("data-turbo-permanent", "");
    }
  }

  onFocusout(event) {
    if (!this.element.contains(event.relatedTarget)) {
      this.inputTarget?.removeAttribute("data-turbo-permanent");
    }
  }

  beforeSubmit() {
    if (this.hasAdvancedSearchV1Outlet) {
      this.advancedSearchV1Outlet.renderExistingSearch();
    }

    if (this.hasAdvancedSearchV2BuilderOutlet) {
      this.advancedSearchV2BuilderOutlet.renderExisting();
    }
  }
}
