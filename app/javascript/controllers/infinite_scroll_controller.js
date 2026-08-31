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
    separatePeAttachments: { type: Boolean, default: false },
  };

  #page = 1;

  connect() {
    this.allIds = this.#parseIds();
    this.numSelected = this.allIds.length;
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

  #parseIds() {
    const ids = this.selectionOutlet.getOrCreateStoredItems();
    if (this.separatePeAttachmentsValue) {
      // handles flattening attachment ids where PE files come in as a stringified nested array and need further parsing
      // PE files are outputted as individual ids
      const flattenedPeIds = ids.flatMap((item) => {
        try {
          const parsed = JSON.parse(item);
          return Array.isArray(parsed) ? parsed : [item];
        } catch {
          return [item];
        }
      });
      return flattenedPeIds;
    } else {
      return ids;
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
