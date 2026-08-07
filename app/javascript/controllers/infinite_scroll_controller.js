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
    "selectionCount",
  ];
  static values = {
    pagedFieldName: String,
    singularDescription: String,
    pluralDescription: String,
    nonZeroHeader: String,
    countPeAttachments: { type: Boolean, default: false },
  };

  #page = 1;

  connect() {
    this.allIds = this.selectionOutlet.getOrCreateStoredItems();
    this.numSelected = this.#calculateNumSelected();
    this.#makePagedHiddenInputs();
    this.#replaceDescriptionPlaceholder();
    if (this.hasSelectionCountTarget) {
      this.#replaceCountPlaceholder(
        this.selectionCountTarget,
        this.nonZeroHeaderValue,
      );
    }

    // Add data-connected attribute
    this.element.setAttribute("data-connected", true);
  }

  #calculateNumSelected() {
    const numSelected = this.allIds.length;

    // if (this.countPeAttachmentsValue) {
    //   // pe files are saved as nested stringified 2 value arrays
    //   // eg: ["att_1", "att_2", "["att_3_fwd", "att_3_rev"]"]
    //   // we'll count how many opening brackets ([) exist, and add an additional count for each to represent the
    //   // two PE files
    //   numSelected += this.allIds.reduce((total, str) => {
    //     return total + (str.match(/\[/g) || []).length;
    //   }, 0);
    // }

    return numSelected;
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
      this.#replaceCountPlaceholder(
        this.summaryTarget,
        this.pluralDescriptionValue,
      );
    }
  }

  #replaceCountPlaceholder(textNode, countPlaceholderText) {
    textNode.innerHTML = countPlaceholderText.replace(
      "COUNT_PLACEHOLDER",
      this.numSelected,
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
