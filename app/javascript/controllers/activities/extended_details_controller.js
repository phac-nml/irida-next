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
    "sampleCloneTableRow",
    "listRow",
    "ariaLabels",
    "itemName",
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
  #paginationAriaLabels = {};

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
        if (this.activityTypeValue === "workflow_execution_destroy") {
          this.#generateWorkflowListItems(indexRangeData);
        } else {
          this.#generateSampleListItems(indexRangeData);
        }
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
      this.#paginationAriaLabels = JSON.parse(this.ariaLabelsTarget.innerText);
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

    if (button == this.previousBtnTarget) {
      button.setAttribute(
        "aria-label",
        this.#paginationAriaLabels["previous"]["disabled"],
      );
    } else {
      button.setAttribute(
        "aria-label",
        this.#paginationAriaLabels["next"]["disabled"],
      );
    }
  }

  #enablePaginationButton(button) {
    button.disabled = false;

    if (button == this.previousBtnTarget) {
      button.setAttribute(
        "aria-label",
        this.#paginationAriaLabels["previous"]["enabled"],
      );
    } else {
      button.setAttribute(
        "aria-label",
        this.#paginationAriaLabels["next"]["enabled"],
      );
    }
  }

  // Generate table rows in format <td>SAMPLE_NAME <SAMPLE_PUID></td><td>SAMPLE_NAME <CLONE_PUID></td>
  #generateTableRows(table_data) {
    if ("content" in document.createElement("template")) {
      const template = this.sampleCloneTableRowTarget;
      const fragment = document.createDocumentFragment();
      const sampleNameSelector =
        "span[data-activities--extended_details-target='sampleName']";
      const puidSelector = "span:nth-child(2)";

      table_data.forEach((data) => {
        const clone = template.content.cloneNode(true);
        const tds = clone.querySelectorAll("td");

        const updateTextContent = (tdIndex, sampleName, puid) => {
          const td = tds[tdIndex];
          td.querySelector(sampleNameSelector).textContent = sampleName;
          td.querySelector(puidSelector).textContent = puid;
        };

        updateTextContent(0, data["sample_name"], data["sample_puid"]);
        updateTextContent(1, data["sample_name"], data["clone_puid"]);

        fragment.appendChild(clone);
      });

      this.tbodyTarget.appendChild(fragment);
    }
  }

  // Generate list items in format SAMPLE_NAME <SAMPLE_PUID>
  #generateSampleListItems(list_data) {
    if ("content" in document.createElement("template")) {
      const template = this.listRowTarget;
      const fragment = document.createDocumentFragment();

      list_data.forEach((data) => {
        const clone = template.content.cloneNode(true);
        const li = clone.querySelector("li");

        li.querySelector(
          "span[data-activities--extended_details-target='itemName']",
        ).textContent = data["sample_name"];
        li.querySelector("p > span:nth-child(2)").textContent =
          data["sample_puid"];

        fragment.appendChild(clone);
      });

      this.listContainerTarget.appendChild(fragment);
    }
  }

  // Generate list items in format WORKFLOW_NAME <WORKFLOW_ID>
  #generateWorkflowListItems(listData) {
    if ("content" in document.createElement("template")) {
      const template = this.listRowTarget;
      const fragment = document.createDocumentFragment();

      listData.forEach((data) => {
        const clone = template.content.cloneNode(true);
        const li = clone.querySelector("li");

        li.querySelector(
          "span[data-activities--extended_details-target='itemName']",
        ).textContent = data["workflow_name"];
        li.querySelector("p > span:nth-child(2)").textContent =
          data["workflow_id"];

        fragment.appendChild(clone);
      });

      this.listContainerTarget.appendChild(fragment);
    }
  }
}
