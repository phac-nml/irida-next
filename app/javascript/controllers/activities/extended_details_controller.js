import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "previousBtn",
    "nextBtn",
    "pagination",
    "paginationContainer",
    "extendedDetailsData",
    "tbody",
    "listContainer",
  ];

  static values = {
    numCols: { type: Number, default: 2 },
    activityType: { type: String, default: "" },
  };

  // pagination page params
  #currentPage;
  #lastPage;

  #currentDataIndexes = [];
  #data = [];

  connect() {
    if (this.hasExtendedDetailsDataTarget) {
      this.#setInitialData();
      this.element.setAttribute("data-controller-connected", "true");
    }
  }

  #setInitialData() {
    this.#data = JSON.parse(this.extendedDetailsDataTarget.innerText);

    // set initial data indexes to include all samples
    this.#setAllSampleIndexes();

    this.#setPagination();
    this.#loadData();
  }

  #loadData() {
    if (this.#currentDataIndexes.length > 0) {
      let startingIndex = (this.#currentPage - 1) * 5;
      let lastIndex = startingIndex + 5;

      if (
        this.#currentPage == this.#lastPage &&
        this.#currentDataIndexes.length % 5 != 0
      ) {
        lastIndex = (this.#currentDataIndexes.length % 5) + startingIndex;
      }

      let indexRangeData = this.#data.slice(startingIndex, lastIndex);
      if (this.hasTbodyTarget) {
        this.#generateTableRows(indexRangeData);
      } else {
        // If activityType value is set, this else statement
        // can be updated to call the relevant method required
        // based on the activityType
        this.#generateListItems(indexRangeData);
      }
    }
  }

  #setAllSampleIndexes() {
    this.#currentDataIndexes = [
      ...Array(Object.keys(this.#data).length).keys(),
    ];
  }

  #setPagination() {
    this.#currentPage = 1;
    this.paginationContainerTarget.innerHTML = "";
    this.#lastPage = Math.ceil(this.#currentDataIndexes.length / 5);

    if (this.#lastPage > 1) {
      this.paginationContainerTarget.insertAdjacentHTML(
        "beforeend",
        this.paginationTarget.innerHTML,
      );
    }
  }

  previousPage() {
    this.#currentPage -= 1;
    this.#updatePageData();
  }

  nextPage() {
    this.#currentPage += 1;
    this.#updatePageData();
  }

  #updatePageData() {
    if (this.#lastPage > 1) {
      this.#verifyPaginationButtonStates();
    }

    if (this.hasTbodyTarget) {
      this.tbodyTarget.innerHTML = "";
    } else {
      this.listContainerTarget.innerHTML = "";
    }

    this.#loadData();
  }

  #verifyPaginationButtonStates() {
    if (this.#currentPage == 1) {
      this.#disablePaginationButton(this.previousBtnTarget);
      this.#enablePaginationButton(this.nextBtnTarget);
    } else if (this.#currentPage == this.#lastPage) {
      this.#disablePaginationButton(this.nextBtnTarget);
      this.#enablePaginationButton(this.previousBtnTarget);
    } else {
      this.#enablePaginationButton(this.nextBtnTarget);
      this.#enablePaginationButton(this.previousBtnTarget);
    }
  }

  #disablePaginationButton(button) {
    button.disabled = true;
  }

  #enablePaginationButton(button) {
    button.disabled = false;
  }

  // Generate table rows in format <td>SAMPLE_NAME <SAMPLE_PUID></td><td>SAMPLE_NAME <CLONE_PUID></td>
  #generateTableRows(table_data) {
    if ("content" in document.createElement("template")) {
      for (let i = 0; i < table_data.length; i++) {
        const template = document.querySelector("#sampleCloneTableRow");
        const clone = template.content.cloneNode(true);
        const sampleNameSelector = "span:nth-child(1)";
        const puidSelector = "span:nth-child(2)";
        let tds = clone.querySelectorAll("td");
        let sampleName = table_data[i]["sample_name"];
        let samplePuid = table_data[i]["sample_puid"];
        let clonePuid = table_data[i]["clone_puid"];

        tds[0].querySelector(sampleNameSelector).textContent = sampleName;
        tds[0].querySelector(puidSelector).textContent = samplePuid;

        tds[1].querySelector(sampleNameSelector).textContent = sampleName;
        tds[1].querySelector(puidSelector).textContent = clonePuid;

        this.tbodyTarget.appendChild(clone);
      }
    }
  }

  // Generate list items in format SAMPLE_NAME <SAMPLE_PUID>
  #generateListItems(list_data) {
    if ("content" in document.createElement("template")) {
      for (let i = 0; i < list_data.length; i++) {
        const template = document.querySelector("#listRow");
        const clone = template.content.cloneNode(true);
        let li = clone.querySelector("li");

        li.querySelector("p > span:nth-child(1)").textContent =
          list_data[i]["sample_name"];
        li.querySelector("p > span:nth-child(2)").textContent =
          list_data[i]["sample_puid"];

        this.listContainerTarget.appendChild(clone);
      }
    }
  }
}
