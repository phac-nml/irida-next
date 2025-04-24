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
    for (let i = 0; i < table_data.length; i++) {
      let tr = document.createElement("tr");

      for (let j = 0; j < this.numColsValue; j++) {
        let td = document.createElement("td");
        let span = document.createElement("span");
        td.className = "px-3 py-3";
        span.className =
          "bg-green-100 ml-2 dark:bg-green-900 dark:text-green-300 font-medium px-2.5 py-0.5 rounded-full text-green-800 text-xs";

        // Sample Name - (Existing PUID [copied from] or New Puid [copied to])
        td.innerText = table_data[i]["sample_name"];
        if (j == 0) {
          span.innerHTML = table_data[i]["sample_puid"];
          td.appendChild(span);
        } else if (j == 1) {
          span.innerHTML = table_data[i]["clone_puid"];
          td.appendChild(span);
        } else {
          span.innerHTML = "";
        }
        tr.appendChild(td);
      }

      this.tbodyTarget.appendChild(tr);
    }
  }

  // Generate list items in format SAMPLE_NAME <SAMPLE_PUID>
  #generateListItems(list_data) {
    for (let i = 0; i < list_data.length; i++) {
      let li = document.createElement("li");
      let containerDiv = document.createElement("div");
      let iconDiv = document.createElement("div");
      let paragraphDiv = document.createElement("div");
      let paragraph = document.createElement("p");
      let span = document.createElement("span");

      li.className = "pt-3 pb-3 sm:pb-4 sm:pt-4";
      containerDiv.className =
        "flex items-center space-x-4 rtl:space-x-reverse";
      iconDiv.className = "shrink-0";
      paragraphDiv.className = "flex-1 min-w-0";
      paragraph.className =
        "text-sm text-slate-500 truncate dark:text-slate-400";
      span.className =
        "bg-green-100 ml-2 dark:bg-green-900 dark:text-green-300 font-medium px-2.5 py-0.5 rounded-full text-green-800 text-xs";

      containerDiv.appendChild(iconDiv);
      span.innerHTML = list_data[i]["sample_puid"];
      paragraphDiv.appendChild(paragraph);
      // Sample Name - Sample Puid
      paragraph.innerHTML = list_data[i]["sample_name"];
      paragraph.appendChild(span);
      containerDiv.appendChild(paragraphDiv);
      li.appendChild(containerDiv);
      this.listContainerTarget.appendChild(li);
    }
  }
}
