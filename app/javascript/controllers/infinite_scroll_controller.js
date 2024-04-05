import { Controller } from "@hotwired/stimulus";
import _ from "lodash";
export default class extends Controller {
  static outlets = ["selection"];
  static targets = ["all", "pageForm", "pageFormContent", "scrollable"];

  #page = 1;

  connect() {
    this.allIds = this.selectionOutlet.getStoredSamples();
    this.submitForm();
    this.#makeFormInputs();
  }

  scroll() {
    if (
      this.scrollableTarget.scrollHeight - this.scrollableTarget.scrollTop <=
      this.scrollableTarget.clientHeight + 1
    ) {
      this.submitForm();
    }
  }

  #makePagedInputs() {
    const itemsPerPage = 100;
    const start = (this.#page - 1) * itemsPerPage;
    const end = this.#page * itemsPerPage;
    const ids = this.allIds.slice(start, end);
    this.pageFormContentTarget.innerHTML = "";
    for (const id of ids) {
      this.pageFormContentTarget.appendChild(
        this.#createHiddenInput("sample_ids[]", id),
      );
    }
    this.pageFormContentTarget.appendChild(
      this.#createHiddenInput("page", this.#page),
    );
    this.pageFormContentTarget.appendChild(
      this.#createHiddenInput("has_next", ids.length === itemsPerPage),
    );
    this.pageFormContentTarget.appendChild(
      this.#createHiddenInput("format", "turbo_stream"),
    );
    this.#page++;
  }

  #makeFormInputs() {
    const chunkedIds = _.chunk(this.allIds, 100);

    // iterate over each chunk and add the ides as hidden inputs to this.allTarget.  After each chunk, use a timeout to allow other code to run
    let i = 0;
    const interval = setInterval(() => {
      if (i < chunkedIds.length) {
        const ids = chunkedIds[i];
        for (const id of ids) {
          this.allTarget.appendChild(
            this.#createHiddenInput("transfer[sample_ids][]", id),
          );
        }
        i++;
      } else {
        clearInterval(interval);
      }
    }, 100);
  }

  #createHiddenInput(name, value) {
    const element = document.createElement("input");
    element.type = "hidden";
    element.id = name;
    element.name = name;
    element.value = value;
    return element;
  }

  submitForm() {
    this.#makePagedInputs();
    this.pageFormTarget.requestSubmit();
  }
}
