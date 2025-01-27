import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "table",
    "processing",
    "submit",
    "error",
    "errorMessage",
    "form",
    "workflowAttributes",
    "samplesheetProperties",
    "cellContainer",
    "sampleIdentifierCell",
    "dropdownCell",
    "fileCell",
    "metadataCell",
    "textCell",
    "previousBtn",
    "nextBtn",
    "pageNum",
    "metadataIndexStart",
    "metadataIndexEnd",
  ];

  static values = {
    attachmentsError: { type: String },
    submissionError: { type: String },
    url: { type: String },
    workflow: { type: Object },
    noSelectedFile: { type: String },
  };

  #error_state = ["border-red-300", "dark:border-red-800"];
  #default_state = ["border-transparent"];

  #pagination_button_disabled_state = [
    "cursor-default",
    "text-slate-600",
    "bg-slate-50",
    "dark:bg-slate-700",
    "dark:text-slate-400",
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
  ];

  // The samplesheet will use FormData, allowing us to create the inputs of a form without the associated DOM elements.
  #formData = new FormData();
  #currentPage = 1;
  #lastPage;
  #samplesheetProperties = JSON.parse(
    this.samplesheetPropertiesTarget.innerHTML,
  );
  #columnNames = Object.keys(this.#samplesheetProperties);

  connect() {
    console.log("properties");
    console.log(this.#samplesheetProperties);
    if (this.hasWorkflowAttributesTarget) {
      this.samplesheetParams = JSON.parse(
        this.workflowAttributesTarget.innerText,
      );
      this.#setInitialSamplesheetData();
      this.#lastPage = Math.ceil(
        Object.keys(this.samplesheetParams).length / 5,
      );
      if (this.#lastPage == 1) {
        this.#disablePaginationButton(this.nextBtnTarget);
      }
      this.#generatePageNumberDropdown();
      this.#loadPageData();
    }
  }

  #setInitialSamplesheetData() {
    console.log("params");
    console.log(this.samplesheetParams);
    for (const index in this.samplesheetParams) {
      for (const sample_attrs in this.samplesheetParams[index]) {
        if (sample_attrs == "sample_id") {
          // specifically adds sample to form
          this.#setFormData(
            `workflow_execution[samples_workflow_executions_attributes][${index}][${sample_attrs}]`,
            this.samplesheetParams[index][sample_attrs],
          );
          continue;
        }
        for (const property in this.samplesheetParams[index][sample_attrs]) {
          // adds all remaining sample data to form (files, metadata, etc.)
          this.#setFormData(
            `workflow_execution[samples_workflow_executions_attributes][${index}][${sample_attrs}][${property}]`,
            this.samplesheetParams[index][sample_attrs][property]["form_value"],
          );
        }
      }
    }
  }

  // handles changes to text and dropdown cells
  updateEditableSamplesheetData(event) {
    this.#setFormData(event.target.name, event.target.value);
  }

  // handles changes to metadata autofill and file cells
  updateFileData({ detail: { content } }) {
    this.#setFormData(content.inputName, content.inputValue);

    // update samplesheetParams cell_value with the new filename to be displayed in samplesheet table
    // as this is the only place to retrieve filename unlike all other fields that can be retrieved
    // via formData (files are stored by globalID in formData)
    let filename = content["file"]["filename"]
      ? content["file"]["filename"]
      : this.noSelectedFileValue;
    this.samplesheetParams[content["file"]["index"]]["samplesheet_params"][
      content["file"]["property"]
    ]["cell_value"] = filename;
  }

  updateMetadata({ detail: { content } }) {
    for (const formName in content["metadata"]) {
      this.#setFormData(formName, content["metadata"][formName]);
    }
    this.#clearSamplesheetTable();
    this.#loadPageData();
  }

  submitSamplesheet(event) {
    event.preventDefault();
    this.#enableProcessingState();
    // only required file cells require an additional validation step. The rest of the cells are either autofilled or
    // validated by the browser required fields
    let readyToSubmit = this.#validateFileCells();
    if (!readyToSubmit) {
      this.#disableProcessingState();
      this.#enableErrorState(this.attachmentsErrorValue);
    } else {
      this.#combineFormData();
      fetch(this.urlValue, {
        method: "POST",
        body: new URLSearchParams(this.#formData),
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
      }).then((response) => {
        this.#disableProcessingState();
        if (response.redirected && response.statusText == "OK") {
          window.location.href = response.url;
        } else {
          this.#enableErrorState(this.submissionErrorValue);
        }
      });
    }
  }

  #setFormData(inputName, inputValue) {
    this.#formData.set(inputName, inputValue);
  }

  #retrieveFormData(index, columnName) {
    return this.#formData.get(
      `workflow_execution[samples_workflow_executions_attributes][${index}][samplesheet_params][${columnName}]`,
    );
  }

  #validateFileCells() {
    let readyToSubmit = true;
    const missingRequiredFileCells = document.querySelectorAll(
      "[data-file-missing='true']",
    );
    if (missingRequiredFileCells.length > 0) {
      missingRequiredFileCells.forEach((fileCell) => {
        fileCell.classList.remove(...this.#default_state);
        fileCell.classList.add(...this.#error_state);
        readyToSubmit = false;
      });

      // revalidates file cells incase they need to be changed from error to default state
      const filledRequiredFileCells = document.querySelectorAll(
        "[data-file-missing='false']",
      );
      filledRequiredFileCells.forEach((fileCell) => {
        fileCell.classList.add(...this.#default_state);
        fileCell.classList.remove(...this.#error_state);
      });
    }
    return readyToSubmit;
  }

  // combines parameter form data with samplesheet form data
  #combineFormData() {
    const parameterData = new FormData(this.formTarget);
    for (const parameter of parameterData.entries()) {
      this.#setFormData(parameter[0], parameter[1]);
    }
  }

  #enableProcessingState() {
    this.submitTarget.disabled = true;
    if (this.hasTableTarget) {
      this.tableTarget.appendChild(
        this.processingTarget.content.cloneNode(true),
      );
    }
  }

  #disableProcessingState() {
    this.submitTarget.disabled = false;
    if (this.hasTableTarget) {
      this.tableTarget.removeChild(this.tableTarget.lastElementChild);
    }
  }

  #enableErrorState(message) {
    this.errorTarget.classList.remove("hidden");
    this.errorMessageTarget.innerHTML = message;
  }

  #loadPageData() {
    let startingIndex = (this.#currentPage - 1) * 5;
    let lastIndex = startingIndex + 5;
    if (
      this.#currentPage == this.#lastPage &&
      Object.keys(this.samplesheetParams).length % 5 != 0
    ) {
      lastIndex =
        (Object.keys(this.samplesheetParams).length % 5) + startingIndex;
    }

    if (this.hasMetadataIndexStartTarget) {
      this.#updateMetadataIndexes(startingIndex, lastIndex);
    }

    this.#columnNames.forEach((columnName) => {
      let columnNode = document.getElementById(`metadata-${columnName}-column`);
      for (let i = startingIndex; i < lastIndex; i++) {
        let container = this.#generateCellContainer(columnNode);
        switch (this.#samplesheetProperties[columnName]["cell_type"]) {
          case "sample_cell":
          case "sample_name_cell":
            this.#generateSampleCell(container, columnName, i);
            break;
          case "dropdown_cell":
            this.#generateDropdownCell(
              container,
              columnName,
              i,
              this.#samplesheetProperties[columnName]["enum"],
            );
            break;
          case "fastq_cell":
          case "file_cell":
            this.#generateFileCell(container, columnName, i);
            break;
          case "metadata_cell":
            this.#generateMetadataCell(container, columnName, i);
            break;
          case "input_cell":
            this.#generateTextCell(container, columnName, i);
            break;
          default:
            this.#generateSampleCell(container, columnName, i);
        }
      }
    });
  }

  #updateMetadataIndexes(startingIndex, endingIndex) {
    for (let metadataIndexStartTarget of this.metadataIndexStartTargets) {
      metadataIndexStartTarget.value = startingIndex;
    }
    for (let metadataIndexEndTarget of this.metadataIndexEndTargets) {
      metadataIndexEndTarget.value = endingIndex;
    }
  }

  #cleanupMetadataFields(property) {
    let metadataColumn = document.getElementById(`metadata-${property}-column`);
    for (const metadataField of metadataColumn.children) {
      if (metadataField.hidden) {
        console.log("hiddin");
        // metadataField.remove();
      }
    }
  }

  // inserting the template html then requerying it out via lastElementChild turns the node from textNode into an
  // HTML element we can manipulate via appendChild, insertHTML, etc.
  #generateCellContainer(columnNode) {
    let newCellContainer = this.cellContainerTarget.innerHTML;
    columnNode.insertAdjacentHTML("beforeend", newCellContainer);
    return columnNode.lastElementChild;
  }

  #generateSampleCell(container, columnName, index) {
    let childNode = this.sampleIdentifierCellTarget.innerHTML.replace(
      /CELL_PLACEHOLDER/g,
      this.#retrieveFormData(index, columnName),
    );
    container.insertAdjacentHTML("beforeend", childNode);
  }

  #generateDropdownCell(container, columnName, index, options) {
    let childNode = this.dropdownCellTarget.innerHTML
      .replace(/INDEX_PLACEHOLDER/g, index)
      .replace(/COLUMN_NAME_PLACEHOLDER/g, columnName);

    container.insertAdjacentHTML("beforeend", childNode);
    let select = container.querySelector("select");
    for (let j = 0; j < options.length; j++) {
      let option = document.createElement("option");
      option.value = options[j];
      option.innerHTML = options[j];
      select.appendChild(option);
    }

    select.value = this.#retrieveFormData(index, columnName);
  }

  #generateFileCell(container, columnName, index) {
    let childNode = this.fileCellTarget.innerHTML
      .replace(/INDEX_PLACEHOLDER/g, index)
      .replace(/PROPERTY_PLACEHOLDER/g, columnName)
      .replace(
        /ATTACHABLE_ID_PLACEHOLDER/g,
        this.samplesheetParams[index]["sample_id"],
      )
      .replace(/ATTACHABLE_TYPE_PLACEHOLDER/g, "Sample")
      .replace(
        /SELECTED_ID_PLACEHOLDER/g,
        this.samplesheetParams[index]["samplesheet_params"][columnName][
          "attachment_id"
        ],
      )
      .replace(
        /FILE_TYPE_PLACEHOLDER/g,
        this.#samplesheetProperties[columnName]["cell_type"] == "fastq_cell"
          ? "fastq"
          : "other",
      )
      .replace(
        /CELL_VALUE_PLACEHOLDER/g,
        this.samplesheetParams[index]["samplesheet_params"][columnName][
          "cell_value"
        ],
      );
    container.insertAdjacentHTML("beforeend", childNode);

    // sets the verification attribute (whether a file cell is required and has a selection) for required file cells
    if (this.#samplesheetProperties[columnName]["required"]) {
      let fileNode = document.getElementById(
        `${this.samplesheetParams[index]["sample_id"]}_${columnName}`,
      );
      fileNode.setAttribute(
        "data-file-missing",
        this.samplesheetParams[index]["samplesheet_params"][columnName][
          "attachment_id"
        ]
          ? "false"
          : "true",
      );
    }
  }

  #generateMetadataCell(container, columnName, index) {
    let metadataValue = this.#retrieveFormData(index, columnName);
    if (metadataValue) {
      let childNode = this.metadataCellTarget.innerHTML.replace(
        /METADATA_VALUE_PLACEHOLDER/g,
        this.#retrieveFormData(index, columnName),
      );
      container.insertAdjacentHTML("beforeend", childNode);
    } else {
      this.#generateTextCell(container, columnName, index);
    }
  }

  #generateTextCell(container, columnName, index) {
    let childNode = this.textCellTarget.innerHTML
      .replace(
        /NAME_PLACEHOLDER/g,
        `workflow_execution[samples_workflow_executions_attributes][${index}][samplesheet_params][${columnName}]`,
      )
      .replace(
        /ID_PLACEHOLDER/g,
        `workflow_execution_samples_workflow_executions_attributes_${index}_samplesheet_params_${columnName}`,
      );

    container.insertAdjacentHTML("beforeend", childNode);
    const form_value = this.#retrieveFormData(index, columnName);
    if (form_value) {
      container.lastElementChild.value = form_value;
    }
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
    this.#verifyButtonStates();
    this.#clearSamplesheetTable();
    this.#loadPageData();
  }

  #verifyButtonStates() {
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

  #generatePageNumberDropdown() {
    let pageSelection = this.pageNumTarget;

    for (let i = 1; i < this.#lastPage + 1; i++) {
      let option = document.createElement("option");
      option.value = i;
      option.innerHTML = i;
      pageSelection.appendChild(option);
    }
    pageSelection.value = 1;
  }

  #clearSamplesheetTable() {
    this.#columnNames.forEach((columnName) => {
      document.getElementById(`metadata-${columnName}-column`).innerHTML = "";
    });
  }
}

// console.log(this.#samplesheetProperties);

// console.log(this.samplesheetParams);
