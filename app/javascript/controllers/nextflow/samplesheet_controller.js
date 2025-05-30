import { Controller } from "@hotwired/stimulus";
import { formDataToJsonParams } from "utilities/form";

export default class extends Controller {
  static targets = [
    "tableBody",
    "submit",
    "error",
    "errorMessage",
    "form",
    "spinner",
    "workflowAttributes",
    "samplesheetProperties",
    "trTemplate",
    "thTemplate",
    "tdTemplate",
    "sampleIdentifierTemplate",
    "dropdownTemplate",
    "fileTemplate",
    "metadataTemplate",
    "textTemplate",
    "previousBtn",
    "nextBtn",
    "pageNum",
    "dataPayload",
    "filter",
    "paginationTemplate",
    "paginationContainer",
    "emptyState",
    "metadataHeaderForm",
  ];

  static values = {
    dataMissingError: { type: String },
    submissionError: { type: String },
    url: { type: String },
    noSelectedFile: { type: String },
    processingRequest: { type: String },
    filteringSamples: { type: String },
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

  #metadata_parameter_updated_state = [
    "ring-2",
    "ring-primary-500",
    "dark:ring-primary-600",
  ];

  // The samplesheet will use FormData, allowing us to create the inputs of a form without the associated DOM elements.
  #formData = new FormData();

  #columnNames;
  #requiredColumns = [];

  // pagination page params
  #currentPage;
  #lastPage;

  // sample data within the samplesheet is centered around which index they're at.
  // Main use case for having an array of sample indexes is for filtering,
  // where we can easily access samples via a wide range of indexes when the sample list is filtered down
  #currentSampleIndexes = [];

  #filterableColumns = [];
  #totalSamples;

  // samplesheetProperties contains all the parameters of each field type to the associated pipeline
  #samplesheetProperties;

  // samplesheetAttributes contains the specific sample values for table rendering and form submission
  #samplesheetAttributes;

  connect() {
    if (this.hasWorkflowAttributesTarget) {
      this.#setSamplesheetParametersAndData();
      this.#disableProcessingState();
    }
  }

  #setSamplesheetParametersAndData() {
    this.#samplesheetProperties = JSON.parse(
      this.samplesheetPropertiesTarget.innerHTML,
    );
    // clear the now unnecessary DOM element
    this.samplesheetPropertiesTarget.remove();

    this.#samplesheetAttributes = JSON.parse(
      this.workflowAttributesTarget.innerText,
    );
    // clear the now unnecessary DOM element
    this.workflowAttributesTarget.remove();

    this.#totalSamples = Object.keys(this.#samplesheetAttributes).length;
    this.#columnNames = Object.keys(this.#samplesheetProperties);

    // set required columns
    for (const column in this.#samplesheetProperties) {
      // automatically autoloaded into samplesheet
      if (column === "sample") {
        continue;
      }
      if (this.#samplesheetProperties[column]["required"]) {
        this.#requiredColumns.push(column);
      }
    }
    // enter all initial/autoloaded sample data into FormData
    this.#setInitialSamplesheetData();

    // set initial sample indexes to include all samples
    this.#setCurrentSampleIndexesToAll();

    // specify the available columns for filtering
    this.#setFilterableColumns();

    // setup pagination
    this.#setPagination();
    // render samplesheet table
    this.#loadTableData();
  }

  #setInitialSamplesheetData() {
    for (const index in this.#samplesheetAttributes) {
      for (const sample_attrs in this.#samplesheetAttributes[index]) {
        if (sample_attrs == "sample_id") {
          // specifically adds sample to form
          this.#setFormData(
            `workflow_execution[samples_workflow_executions_attributes][${index}][${sample_attrs}]`,
            this.#samplesheetAttributes[index][sample_attrs],
          );
          continue;
        }
        for (const property in this.#samplesheetAttributes[index][
          sample_attrs
        ]) {
          // adds all remaining sample data to form (files, metadata, etc.)
          this.#setFormData(
            `workflow_execution[samples_workflow_executions_attributes][${index}][${sample_attrs}][${property}]`,
            this.#samplesheetAttributes[index][sample_attrs][property][
              "form_value"
            ],
          );
        }
      }
    }
  }

  submitSamplesheet(event) {
    event.preventDefault();
    this.#enableProcessingState(this.processingRequestValue);
    // 50ms timeout allows the browser to update the DOM elements enabling the overlay prior to starting the submission
    setTimeout(() => {
      let missingData = this.#validateData();
      if (Object.keys(missingData).length > 0) {
        this.#disableProcessingState();
        let errorMsg = this.dataMissingErrorValue;
        for (const sample in missingData) {
          errorMsg =
            errorMsg + `\n - ${sample}: ${missingData[sample].join(", ")}`;
        }
        this.#enableErrorState(errorMsg);
      } else {
        this.#combineFormData();

        this.formTarget.addEventListener(
          "turbo:before-fetch-request",
          (event) => {
            event.detail.fetchOptions.body = JSON.stringify(
              formDataToJsonParams(this.#formData),
            );
            event.detail.fetchOptions.headers["Content-Type"] =
              "application/json";

            event.detail.resume();
          },
          {
            once: true,
          },
        );
        this.formTarget.requestSubmit();
      }
    }, 50);
  }

  #validateData() {
    let missingData = {};
    this.#requiredColumns.forEach((requiredColumn) => {
      for (
        let i = 0;
        i < Object.keys(this.#samplesheetAttributes).length;
        i++
      ) {
        if (!this.#retrieveFormData(i, requiredColumn)) {
          let sample = this.#retrieveFormData(i, "sample");
          if (sample in missingData) {
            missingData[sample].push(requiredColumn);
          } else {
            missingData[sample] = [requiredColumn];
          }
        }
      }
    });
    return missingData;
  }

  // combines parameter form data with samplesheet form data
  #combineFormData() {
    const parameterData = new FormData(this.formTarget);
    for (const parameter of parameterData.entries()) {
      this.#setFormData(parameter[0], parameter[1]);
    }
  }

  #enableProcessingState(message) {
    document.getElementById("nextflow-spinner-message").innerHTML = message;
    this.submitTarget.disabled = true;
    this.spinnerTarget.classList.remove("hidden");
  }

  #disableProcessingState() {
    this.submitTarget.disabled = false;
    this.spinnerTarget.classList.add("hidden");
  }

  #enableErrorState(message) {
    this.errorTarget.classList.remove("hidden");
    this.errorMessageTarget.innerHTML = message;
    this.errorMessageTarget.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
  }

  #setFormData(inputName, inputValue) {
    this.#formData.set(inputName, inputValue);
  }

  #retrieveFormData(index, columnName) {
    return this.#formData.get(
      `workflow_execution[samples_workflow_executions_attributes][${index}][samplesheet_params][${columnName}]`,
    );
  }

  // handles changes to text and dropdown cells
  updateEditableSamplesheetData(event) {
    this.#setFormData(event.target.name, event.target.value);
  }

  // handles changes to file cells; triggered by nextflow/file_controller.js
  updateFileData({ detail: { content } }) {
    content["files"].forEach((file, index) => {
      this.#setFormData(
        `workflow_execution[samples_workflow_executions_attributes][${content["index"]}][samplesheet_params][${file["property"]}]`,
        file["global_id"],
      );

      // update samplesheetParams filename with the new filename to be displayed in samplesheet table
      // as this is the only place to retrieve filename unlike all other fields that can be retrieved
      // via formData (files are stored by globalID in formData)
      let filename = file["filename"]
        ? file["filename"]
        : this.noSelectedFileValue;

      this.#samplesheetAttributes[content["index"]]["samplesheet_params"][
        file["property"]
      ]["filename"] = filename;

      this.#samplesheetAttributes[content["index"]]["samplesheet_params"][
        file["property"]
      ]["attachment_id"] = file["id"];

      this.#updateCell(
        file["property"],
        content["index"],
        "file_cell",
        index === 0,
      );
    });
    this.#clearPayload();
  }

  // handles changes to metadata autofill; triggered by nextflow/metadata_controller.js
  updateMetadata({ detail: { content } }) {
    for (const index in content["metadata"]) {
      this.#setFormData(
        `workflow_execution[samples_workflow_executions_attributes][${index}][samplesheet_params][${content["property"]}]`,
        content["metadata"][index],
      );
      this.#updateCell(content["property"], index, "metadata_cell", false);
    }
    this.#clearPayload();
  }

  #loadTableData() {
    if (this.#currentSampleIndexes.length > 0) {
      this.emptyStateTarget.classList.add("hidden");
      const startingIndex = (this.#currentPage - 1) * 5;
      let lastIndex = startingIndex + 5;
      if (
        this.#currentPage == this.#lastPage &&
        this.#currentSampleIndexes.length % 5 != 0
      ) {
        lastIndex = (this.#currentSampleIndexes.length % 5) + startingIndex;
      }
      for (let i = startingIndex; i < lastIndex; i++) {
        const sampleIndex = this.#currentSampleIndexes[i];
        const tableRow = this.#generateTableRow();

        this.#columnNames.forEach((columnName) => {
          const cell = this.#generateTableCell(
            columnName,
            sampleIndex,
            this.#columnNames.indexOf(columnName) == 0,
          );
          switch (this.#samplesheetProperties[columnName]["cell_type"]) {
            case "sample_cell":
            case "sample_name_cell":
              this.#insertSampleContent(cell, columnName, sampleIndex);
              break;
            case "dropdown_cell":
              this.#insertDropdownContent(
                cell,
                columnName,
                sampleIndex,
                this.#samplesheetProperties[columnName]["enum"],
              );
              break;
            case "fastq_cell":
            case "file_cell":
              this.#insertFileContent(cell, columnName, sampleIndex);
              break;
            case "metadata_cell":
              this.#insertMetadataContent(cell, columnName, sampleIndex);
              break;
            case "input_cell":
              this.#insertTextContent(cell, columnName, sampleIndex);
              break;
          }
          // add cell content to the row
          tableRow.appendChild(cell);
        });
        // add row to tbody once row contains all content
        this.tableBodyTarget.appendChild(tableRow);
      }
    } else {
      this.emptyStateTarget.classList.remove("hidden");
    }
  }

  #generateTableRow() {
    const template = this.trTemplateTarget.content.cloneNode(true);
    const tableRow = template.firstElementChild;
    return tableRow;
  }

  #generateTableCell(columnName, index, headerCell) {
    const template = headerCell
      ? this.thTemplateTarget.content.cloneNode(true)
      : this.tdTemplateTarget.content.cloneNode(true);
    const cell = template.firstElementChild;
    cell.id = `${index}_${columnName}`;
    return cell;
  }

  #insertSampleContent(cell, columnName, index) {
    const sampleContent = this.sampleIdentifierTemplateTarget.innerHTML.replace(
      /SAMPLE_IDENTIFIER/g,
      this.#retrieveFormData(index, columnName),
    );
    cell.insertAdjacentHTML("beforeend", sampleContent);
  }

  #insertDropdownContent(cell, columnName, index, options) {
    const dropdown = this.dropdownTemplateTarget.innerHTML
      .replace(/INDEX_PLACEHOLDER/g, index)
      .replace(/COLUMN_NAME_PLACEHOLDER/g, columnName);

    cell.insertAdjacentHTML("beforeend", dropdown);
    let select = cell.lastElementChild;
    for (let j = 0; j < options.length; j++) {
      let option = document.createElement("option");
      option.value = options[j];
      option.innerHTML = options[j];
      select.appendChild(option);
    }

    select.value = this.#retrieveFormData(index, columnName);
  }

  #insertFileContent(cell, columnName, index) {
    let pattern = this.#samplesheetProperties[columnName]["pattern"];
    if (pattern) {
      // Need to encode pattern so that + is not interpreted as a space, etc.
      pattern = encodeURIComponent(pattern);
    }

    const file = this.fileTemplateTarget.innerHTML
      .replace(/INDEX_PLACEHOLDER/g, index)
      .replace(/PROPERTY_PLACEHOLDER/g, columnName)
      .replace(
        /ATTACHABLE_ID_PLACEHOLDER/g,
        this.#samplesheetAttributes[index]["sample_id"],
      )
      .replace(/ATTACHABLE_TYPE_PLACEHOLDER/g, "Sample")
      .replace(
        /SELECTED_ID_PLACEHOLDER/g,
        this.#samplesheetAttributes[index]["samplesheet_params"][columnName][
          "attachment_id"
        ],
      )
      .replace(/PATTERN_PLACEHOLDER/g, pattern)
      .replace(
        /FILENAME_PLACEHOLDER/g,
        this.#samplesheetAttributes[index]["samplesheet_params"][columnName][
          "filename"
        ],
      );
    cell.insertAdjacentHTML("beforeend", file);
  }

  #insertMetadataContent(cell, columnName, index) {
    const metadataValue = this.#retrieveFormData(index, columnName);
    if (metadataValue) {
      const metadata = this.metadataTemplateTarget.innerHTML.replace(
        /METADATA_PLACEHOLDER/g,
        this.#retrieveFormData(index, columnName),
      );
      cell.insertAdjacentHTML("beforeend", metadata);
    } else {
      this.#insertTextContent(cell, columnName, index);
    }
  }

  #insertTextContent(cell, columnName, index) {
    const text = this.textTemplateTarget.innerHTML
      .replace(
        /NAME_PLACEHOLDER/g,
        `workflow_execution[samples_workflow_executions_attributes][${index}][samplesheet_params][${columnName}]`,
      )
      .replace(
        /ID_PLACEHOLDER/g,
        `workflow_execution_samples_workflow_executions_attributes_${index}_samplesheet_params_${columnName}`,
      );

    cell.insertAdjacentHTML("beforeend", text);
    // requery to retrieve HTML node rather than textNode
    let textCell = cell.lastElementChild;
    const formValue = this.#retrieveFormData(index, columnName);
    if (formValue) {
      textCell.value = formValue;
    }
  }

  #setPagination() {
    this.#currentPage = 1;
    this.paginationContainerTarget.innerHTML = "";
    // set last page based on number of samples
    this.#lastPage = Math.ceil(this.#currentSampleIndexes.length / 5);
    // create the page dropdown options if there's more than one page
    if (this.#lastPage > 1) {
      this.paginationContainerTarget.insertAdjacentHTML(
        "beforeend",
        this.paginationTemplateTarget.innerHTML,
      );
      this.#generatePageNumberDropdown();
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
    if (this.#lastPage > 1) {
      this.#verifyPaginationButtonStates();
    }
    // delete the table data and reload with new indexes
    this.tableBodyTarget.innerHTML = "";
    this.#loadTableData();
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

  #generatePageNumberDropdown() {
    // page 1 is already added by default
    for (let i = 2; i < this.#lastPage + 1; i++) {
      let option = document.createElement("option");
      option.value = i;
      option.innerHTML = i;
      this.pageNumTarget.appendChild(option);
    }
  }

  #updateCell(columnName, index, cellType, focusCell) {
    const cell = document.getElementById(`${index}_${columnName}`);
    if (cell) {
      cell.innerHTML = "";
      if (cellType == "file_cell") {
        this.#insertFileContent(cell, columnName, index);
      } else {
        this.#insertMetadataContent(cell, columnName, index);
      }
      if (focusCell) {
        cell.firstElementChild.focus();
      }
    }
  }

  #clearPayload() {
    if (this.hasDataPayloadTarget) {
      this.dataPayloadTarget.remove();
    }
  }

  #setCurrentSampleIndexesToAll() {
    this.#currentSampleIndexes = [
      ...Array(Object.keys(this.#samplesheetAttributes).length).keys(),
    ];
  }

  // when filtering samples, we will add the indexes of samples that fit the filter into the #currentSampleIndexes array.
  // we can then easily access each sample's data via its index and still paginate in pages of 5
  filter() {
    this.#enableProcessingState(this.filteringSamplesValue);
    // 50ms timeout allows the browser to update the DOM elements enabling the overlay prior to starting the filtering process
    setTimeout(() => {
      if (this.filterTarget.value) {
        this.#currentSampleIndexes = [];
        for (let i = 0; i < this.#totalSamples; i++) {
          for (let j = 0; j < this.#filterableColumns.length; j++) {
            if (
              this.#samplesheetAttributes[i]["samplesheet_params"][
                this.#filterableColumns[j]
              ]["form_value"]
                .toLowerCase()
                .includes(this.filterTarget.value.toLowerCase())
            ) {
              this.#currentSampleIndexes.push(i);
              break;
            }
          }
        }
      } else {
        // reset table to include all samples if filter is empty
        this.#setCurrentSampleIndexesToAll();
      }

      this.#disableProcessingState();
      this.#setPagination();
      this.#updatePageData();
    }, 50);
  }

  // check samplesheet properties for sample and sample_name and add them as filterable if present
  #setFilterableColumns() {
    if (this.#samplesheetProperties.hasOwnProperty("sample")) {
      this.#filterableColumns.push("sample");
    }

    if (this.#samplesheetProperties.hasOwnProperty("sample_name")) {
      this.#filterableColumns.push("sample_name");
    }
  }

  handleMetadataSelection(event) {
    const metadataSamplesheetColumn = event.target.getAttribute(
      "data-metadata-header",
    );
    const metadataField = event.target.value;
    let metadataParameter = document.querySelector(
      `input[data-metadata-header-name="${metadataSamplesheetColumn}"]`,
    );

    if (metadataParameter) {
      metadataParameter.value = metadataField;
      metadataParameter.classList.add(
        ...this.#metadata_parameter_updated_state,
      );

      setTimeout(() => {
        metadataParameter.classList.remove(
          ...this.#metadata_parameter_updated_state,
        );
      }, 1000);
    }

    const metadataForm = this.metadataHeaderFormTarget.innerHTML
      .replace(/HEADER_PLACEHOLDER/g, metadataSamplesheetColumn)
      .replace(/FIELD_PLACEHOLDER/g, metadataField);

    this.element.insertAdjacentHTML("beforeend", metadataForm);

    setTimeout(() => {
      // wait until form--json-submission controller has connected
      while (!this.element.lastElementChild.hasAttribute("data-connected")) {}
      this.element.lastElementChild.requestSubmit();
      this.element.lastElementChild.remove();
    }, 100);
  }

  #compactFormData() {
    const compactFormData = new FormData();
    for (const [key, value] of this.#formData.entries()) {
      // exclude empty values from form data for samplesheet_params
      if (!(/[samplesheet_params]/.test(key) && value === "")) {
        compactFormData.append(key, value);
      }
    }
    return compactFormData;
  }
}
