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
    "sampleCount"
  ];
  static values = {
    pagedFieldName: String,
    singularDescription: String,
    pluralDescription: String,
    nonZeroHeader: String,
  };

  #page = 1;

  connect() {
    this.allIds = this.selectionOutlet.getStoredItems();
    this.numSelected = this.selectionOutlet.getNumSelected()
    this.#makePagedHiddenInputs();
    this.#replaceDescriptionPlaceholder();
    if (this.hasSampleCountTarget) {
      this.#replaceCountPlaceholder(this.sampleCountTarget, this.nonZeroHeaderValue);
    }
  }

  scroll() {
    if (
      this.scrollableTarget.scrollHeight - this.scrollableTarget.scrollTop <=
      this.scrollableTarget.clientHeight + 1
    ) {
      this.#makePagedHiddenInputs();
    }
  }

  #replaceDescriptionPlaceholder() {
    if (this.numSelected === 1) {
      this.summaryTarget.innerHTML = this.singularDescriptionValue;
    } else {
      this.#replaceCountPlaceholder(this.summaryTarget, this.pluralDescriptionValue);
    }
  }

  #replaceCountPlaceholder(textNode, countPlaceholderText) {
    textNode.innerHTML = countPlaceholderText.replace(
      "COUNT_PLACEHOLDER",
      this.numSelected
    );
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
