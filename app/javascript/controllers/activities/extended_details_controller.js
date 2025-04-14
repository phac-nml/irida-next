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
      this.element.setAttribute("data-controller-connected", "true");
    }
  }

  #setInitialData() {
    this.#sampleAttributes = JSON.parse(
      this.sampleAttributesTarget.innerText,
     );

    this.#sampleData = this.#sampleAttributes

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
        let span = document.createElement("span");
        td.className = "px-3 py-3";
        span.className = "bg-green-100 ml-2 dark:bg-green-900 dark:text-green-300 font-medium px-2.5 py-0.5 rounded-full text-green-800 text-xs";

        // Sample Name - (Existing [copied from] or New Puid [copied to])
        td.innerText = data[i][0];
        span.innerHTML = data[i][j+1];
        td.appendChild(span);
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
      let span = document.createElement("span");

      li.className = "pt-3 pb-3 sm:pb-4 sm:pt-4";
      containerDiv.className = "flex items-center space-x-4 rtl:space-x-reverse"
      iconDiv.className = "shrink-0"
      paragraphDiv.className = "flex-1 min-w-0"
      paragraph.className = "text-sm text-gray-500 truncate dark:text-gray-400"
      span.className = "bg-green-100 ml-2 dark:bg-green-900 dark:text-green-300 font-medium px-2.5 py-0.5 rounded-full text-green-800 text-xs";

      containerDiv.appendChild(iconDiv);
      span.innerHTML = data[i][1];
      paragraphDiv.appendChild(paragraph);
      // Sample Name - Sample Puid
      paragraph.innerHTML = data[i][0];
      paragraph.appendChild(span);
      containerDiv.appendChild(paragraphDiv)
      li.appendChild(containerDiv)
      this.listContainerTarget.appendChild(li);
    }
  }
}
