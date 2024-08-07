import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
  static outlets = ["selection"];
  static targets = [
    "all",
    "pageForm",
    "pageFormContent",
    "scrollable",
    "summary",
  ];
  static values = {
    pagedFieldName: String,
    singular: String,
    plural: String,
  };

  #page = 1;

  connect() {
    this.allIds = this.selectionOutlet.getStoredItems();
    this.#makePagedHiddenInputs();
    this.#replaceCountPlaceholder();
  }

  scroll() {
    if (
      this.scrollableTarget.scrollHeight - this.scrollableTarget.scrollTop <=
      this.scrollableTarget.clientHeight + 1
    ) {
      this.#makePagedHiddenInputs();
    }
  }

  #replaceCountPlaceholder() {
    const numSelected = this.selectionOutlet.getNumSelected();
    let summary = this.summaryTarget;

    if (numSelected == 1) {
      summary.innerHTML = this.singularValue;
    } else {
      summary.innerHTML = this.pluralValue.replace(
        "COUNT_PLACEHOLDER",
        numSelected
      );
    }
  }

  #makePagedHiddenInputs() {
    const itemsPerPage = 100;
    const start = (this.#page - 1) * itemsPerPage;
    const end = this.#page * itemsPerPage;
    const ids = this.allIds.slice(start, end);

    if (ids && ids.length) {
      const fragment = document.createDocumentFragment();
      for (const id of ids) {
        fragment.appendChild(createHiddenInput(this.pagedFieldNameValue, id));
      }
      fragment.appendChild(createHiddenInput("page", this.#page));
      this.pageFormContentTarget.innerHTML = "";
      this.pageFormContentTarget.appendChild(fragment);
      this.#page++;
      this.pageFormTarget.requestSubmit();
    }
  }
}
