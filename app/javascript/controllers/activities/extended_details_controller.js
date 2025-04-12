import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "previousBtn",
    "nextBtn",
    "pagination",
    "paginationContainer",
    "sampleAttributes",
    "tbody",
    "listContainer"
  ];

  static values = {
    numCols: { type: Number, default: 2 }
  };

  #pagination_button_disabled_state = [
    "cursor-default",
    "text-slate-600",
    "bg-slate-50",
    "dark:bg-slate-700",
    "dark:text-slate-400",
    "pointer-events-none",
  ];
  #pagination_button_enabled_state = [
    "text-slate-500",
    "bg-white",
    "hover:bg-slate-100",
    "hover:text-slate-700",
    "dark:bg-slate-800",
    "dark:text-slate-400",
    "dark:hover:bg-slate-700",
    "dark:hover:text-white",
    "cursor",
    "cursor-pointer",
  ];

  // pagination page params
  #currentPage;
  #lastPage;

  #currentSampleIndexes = [];
  #sampleData = [];


  #sampleAttributes;

  connect() {
    if (this.hasSampleAttributesTarget) {
      this.#setInitialData();
    }
  }

  #setInitialData() {
    this.#sampleAttributes = JSON.parse(
      this.sampleAttributesTarget.innerText,
     );

     if(this.hasTbodyTarget) {
      let objectEntries = Object.entries(this.#sampleAttributes);
      for(let entry in objectEntries) this.#sampleData.push(objectEntries[entry]);
     } else {
      this.#sampleData = this.#sampleAttributes
     }

    // set initial sample indexes to include all samples
    this.#setAllSamples();
    this.#setPagination();
    this.#loadData();
  }

  #loadData() {
    if (this.#currentSampleIndexes.length > 0) {
      let startingIndex = (this.#currentPage - 1) * 5;
      let lastIndex = startingIndex + 5;

      if (
        this.#currentPage == this.#lastPage &&
        this.#currentSampleIndexes.length % 5 != 0
      ) {
        lastIndex = (this.#currentSampleIndexes.length % 5) + startingIndex;
      }

      let indexRangeData = this.#sampleData.slice(startingIndex,lastIndex);
      if(this.hasTbodyTarget) {
        this.#generateTableRows(indexRangeData);
      } else {
        this.#generateListItems(indexRangeData);
      }
    }
  }

  #setAllSamples() {
    this.#currentSampleIndexes = [
      ...Array(Object.keys(this.#sampleAttributes).length).keys(),
    ];
  }

  #setPagination() {
    this.#currentPage = 1;
    this.paginationContainerTarget.innerHTML = "";
    this.#lastPage = Math.ceil(this.#currentSampleIndexes.length / 5);

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

    if(this.hasTbodyTarget) {
      this.tbodyTarget.innerHTML = ""
    } else {
      this.listContainerTarget.innerHTML = ""
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
    button.classList.remove(...this.#pagination_button_enabled_state);
    button.classList.add(...this.#pagination_button_disabled_state);
  }

  #enablePaginationButton(button) {
    button.disabled = false;
    button.classList.remove(...this.#pagination_button_disabled_state);
    button.classList.add(...this.#pagination_button_enabled_state);
  }

  #generateTableRows(data) {
    for (let i = 0; i < data.length; i++) {
      let tr = document.createElement("tr");

      for(let j = 0; j < this.numColsValue; j++)
      {
        let td= document.createElement("td");
        td.className = "px-3 py-3";
        td.innerText = data[i][j];
        tr.appendChild(td);
      }

      this.tbodyTarget.appendChild(tr);
    }
  }

  #generateListItems(data) {
    for (let i = 0; i < data.length; i++) {
      let li = document.createElement("li");
      let containerDiv = document.createElement("div");
      let iconDiv = document.createElement("div");
      let paragraphDiv = document.createElement("div");
      let paragraph = document.createElement("p");

      li.className = "pt-3 pb-3 sm:pb-4 sm:pt-4";
      containerDiv.className = "flex items-center space-x-4 rtl:space-x-reverse"
      iconDiv.className = "shrink-0"
      paragraphDiv.className = "flex-1 min-w-0"
      paragraph.className = "text-sm text-gray-500 truncate dark:text-gray-400"

      containerDiv.appendChild(iconDiv);
      paragraphDiv.appendChild(paragraph);
      paragraph.innerHTML = data[i];
      containerDiv.appendChild(paragraphDiv)
      li.appendChild(containerDiv)
      this.listContainerTarget.appendChild(li);
    }
  }
}
