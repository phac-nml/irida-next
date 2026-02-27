import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["paginationContainer", "previousBtn", "nextBtn", "pageNum"];

  static outlets = [
    "nextflow--deferred-samplesheet",
    "nextflow--samplesheet--templates",
  ];

  #currentPage;
  #lastPage;

  setPagination(totalSampleNum) {
    this.#currentPage = 1;
    this.paginationContainerTarget.innerHTML = "";
    // set last page based on number of samples
    this.#lastPage = Math.ceil(totalSampleNum / 5);
    // create the page dropdown options if there's more than one page
    if (this.#lastPage > 1) {
      const template =
        this.nextflowSamplesheetTemplatesOutlet.cloneTemplate(
          "paginationTemplate",
        );
      this.paginationContainerTarget.appendChild(template);
      this.#generatePageNumberDropdown();
      this.#verifyPaginationButtonStates();
    }
    this.#promptLoadTable();
  }

  previousPage() {
    this.#currentPage -= 1;
    this.pageNumTarget.value = this.#currentPage;
    this.#updatePageData();
  }

  nextPage() {
    this.#currentPage += 1;
    this.pageNumTarget.value = this.#currentPage;
    this.#updatePageData();
  }

  pageSelected() {
    this.#currentPage = parseInt(this.pageNumTarget.value);
    this.#updatePageData();
  }

  #updatePageData() {
    if (this.#lastPage > 1) {
      this.#verifyPaginationButtonStates();
    }
    this.#promptLoadTable();
  }

  #verifyPaginationButtonStates() {
    if (this.#currentPage == 1) {
      this.previousBtnTarget.disabled = true;
      this.nextBtnTarget.disabled = false;
    } else if (this.#currentPage == this.#lastPage) {
      this.previousBtnTarget.disabled = false;
      this.nextBtnTarget.disabled = true;
    } else {
      this.previousBtnTarget.disabled = false;
      this.nextBtnTarget.disabled = false;
    }
  }

  #generatePageNumberDropdown() {
    // page 1 is already added by default
    for (let i = 2; i < this.#lastPage + 1; i++) {
      const option = document.createElement("option");
      option.value = i;
      option.innerHTML = i;
      this.pageNumTarget.appendChild(option);
    }
  }

  #promptLoadTable() {
    this.nextflowDeferredSamplesheetOutlet.loadTableData(
      this.#currentPage,
      this.#lastPage,
    );
  }
}
