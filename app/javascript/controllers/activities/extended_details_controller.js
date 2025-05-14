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
    "workflowTableRow",
    "importSampleTableRow",
    "groupSampleTransferTableRow",
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

      // If activityType value is set, this else statement
      // can be updated to call the relevant method required
      // based on the activityType
      if (this.hasTbodyTarget) {
        if (this.activityTypeValue === "workflow_execution_destroy") {
          this.#generateWorkflowTableRows(indexRangeData);
        } else if (
          this.activityTypeValue === "group_import_samples" ||
          this.activityTypeValue === "group_samples_destroy"
        ) {
          // table row format: SAMPLE_NAME (SAMPLE_PUID) | PROJECT_PUID
          this.#generateSampleAndProjectTableRows(indexRangeData);
        } else if (this.activityTypeValue === "group_sample_transfer") {
          this.#generateGroupSampleTransferTableRows(indexRangeData);
        } else {
          this.#generateTableRows(indexRangeData);
        }
      } else {
        this.#generateSampleListItems(indexRangeData);
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

  // Generate table row in format WORKFLOW_NAME | WORKFLOW_ID
  #generateWorkflowTableRows(table_data) {
    if ("content" in document.createElement("template")) {
      const template = this.workflowTableRowTarget;
      const fragment = document.createDocumentFragment();
      const workflowNameSelector =
        "span[data-activities--extended_details-target='workflowName']";
      const workflowIdSelector =
        "span[data-activities--extended_details-target='workflowId']";

      table_data.forEach((data) => {
        const clone = template.content.cloneNode(true);
        const tds = clone.querySelectorAll("td");

        const updateTextContent = (tdIndex, content, selector) => {
          const td = tds[tdIndex];
          td.querySelector(selector).textContent = content;
        };
        updateTextContent(0, data["workflow_name"], workflowNameSelector);
        updateTextContent(1, data["workflow_id"], workflowIdSelector);

        fragment.appendChild(clone);
      });

      this.tbodyTarget.appendChild(fragment);
    }
  }

  #generateSampleAndProjectTableRows(table_data) {
    if ("content" in document.createElement("template")) {
      const template = this.importSampleTableRowTarget;
      const fragment = document.createDocumentFragment();
      const sampleNameSelector =
        "span[data-activities--extended_details-target='sampleName']";
      const puidSelector = "span:nth-child(2)";
      const projectIdSelector =
        "span[data-activities--extended_details-target='projectId']";

      table_data.forEach((data) => {
        const clone = template.content.cloneNode(true);
        const tds = clone.querySelectorAll("td");

        const updateTextContent = (tdIndex, sampleName, puid) => {
          const td = tds[tdIndex];
          if (tdIndex === 0) {
            td.querySelector(sampleNameSelector).textContent = sampleName;
            td.querySelector(puidSelector).textContent = puid;
          } else {
            td.querySelector(projectIdSelector).textContent =
              data["project_puid"];
          }
        };

        updateTextContent(0, data["sample_name"], data["sample_puid"]);
        updateTextContent(1, data["project_puid"], projectIdSelector);

        fragment.appendChild(clone);
      });

      this.tbodyTarget.appendChild(fragment);
    }
  }

  #generateGroupSampleTransferTableRows(table_data) {
    if ("content" in document.createElement("template")) {
      const template = this.groupSampleTransferTableRowTarget;
      const fragment = document.createDocumentFragment();
      const sampleNameSelector =
        "span[data-activities--extended_details-target='sampleName']";
      const puidSelector = "span:nth-child(2)";
      const transferredFromSelector =
        "span[data-activities--extended_details-target='transferredFrom']";
      const transferredToSelector =
        "span[data-activities--extended_details-target='transferredTo']";

      table_data.forEach((data) => {
        const clone = template.content.cloneNode(true);
        const tds = clone.querySelectorAll("td");

        const updateTextContent = (tdIndex, data, puid) => {
          const td = tds[tdIndex];
          if (tdIndex === 0) {
            td.querySelector(sampleNameSelector).textContent = data;
            td.querySelector(puidSelector).textContent = puid;
          } else if (tdIndex === 1) {
            td.querySelector(transferredFromSelector).textContent = data;
            td.querySelector(puidSelector).textContent = puid;
          } else {
            td.querySelector(transferredToSelector).textContent = data;
            td.querySelector(puidSelector).textContent = puid;
          }
        };

        updateTextContent(0, data["sample_name"], data["sample_puid"]);
        updateTextContent(
          1,
          data["source_project_name"],
          data["source_project_puid"],
        );
        updateTextContent(
          2,
          data["target_project_name"],
          data["target_project_puid"],
        );

        fragment.appendChild(clone);
      });

      this.tbodyTarget.appendChild(fragment);
    }
  }
}
