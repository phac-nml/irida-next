import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
  static values = { page: Number };

  submit() {
    const form =
      this.element instanceof HTMLFormElement
        ? this.element
        : this.element.closest("form");
    if (!form) return;

    if (this.hasPageValue) {
      const existingPageInput = form.querySelector(
        'input[name="page"][data-metadata-toggle-page="true"]',
      );
      existingPageInput?.remove();

      const hiddenPageInput = createHiddenInput("page", this.pageValue);
      hiddenPageInput.dataset.metadataTogglePage = "true";
      form.appendChild(hiddenPageInput);
    }

    if (typeof form.requestSubmit === "function") {
      form.requestSubmit();
      return;
    }

    Turbo.navigator.submitForm(form);
  }
}
