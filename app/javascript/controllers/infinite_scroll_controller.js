import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from '../utilities/form';

export default class extends Controller {
  static outlets = ["selection"];
  static targets = ["all", "pageForm", "pageFormContent", "scrollable"];
  static values = {
    fieldName: String,
    pagedFieldName: String
  }

  #page = 1;

  connect() {
    this.allIds = this.selectionOutlet.getStoredSamples();
    this.#makePagedHiddenInputs();
    this.#makeAllHiddenInputs();
  }

  scroll() {
    if (
      this.scrollableTarget.scrollHeight - this.scrollableTarget.scrollTop <=
      this.scrollableTarget.clientHeight + 1
    ) {
      this.#makePagedHiddenInputs();
    }
  }

  #makePagedHiddenInputs() {
    const itemsPerPage = 100;
    const start = (this.#page - 1) * itemsPerPage;
    const end = this.#page * itemsPerPage;
    const ids = this.allIds.slice(start, end);

    if(ids && ids.length){
      const fragment = document.createDocumentFragment();
      for (const id of ids) {
        fragment.appendChild(
          createHiddenInput(this.pagedFieldNameValue, id),
        );
      }
      fragment.appendChild(
        createHiddenInput("page", this.#page),
      );
      fragment.appendChild(
        createHiddenInput("format", "turbo_stream"),
      );
      this.pageFormContentTarget.innerHTML = "";
      this.pageFormContentTarget.appendChild(fragment);
      this.#page++;
      this.pageFormTarget.requestSubmit();
    }
  }

  #makeAllHiddenInputs() {
    const fragment = document.createDocumentFragment();
    for (const id of this.allIds) {
      fragment.appendChild(createHiddenInput(this.fieldNameValue, id));
    }
    this.allTarget.appendChild(fragment);
  }

  clear(){
    this.selectionOutlet.clear();
  }
}