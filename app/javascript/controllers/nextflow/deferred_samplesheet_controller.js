import { Controller } from "@hotwired/stimulus";
import {
  createHiddenInput,
  formDataToJsonParams,
  normalizeParams,
} from "utilities/form";
import { FIELD_CLASSES } from "utilities/styles";
import { announce } from "utilities/live_region";
import merge from "deepmerge";

export default class extends Controller {
  static targets = [
    "tableBody",
    "submit",
    "error",
    "errorMessage",
    "form",
    "formFieldError",
    "formFieldErrorMessage",
    "samplesheetMessagesContainer",
    "submissionSpinner",
    "samplesheetSpinner",
    "updateSamplesSpinner",
    "samplesheetProperties",
    "fileAttributes",
    "trTemplate",
    "thTemplate",
    "tdTemplate",
    "sampleIdentifierTemplate",
    "dropdownTemplate",
    "fileTemplate",
    "metadataTemplate",
    "textInputTemplate",
    "dataPayload",
    "emptyState",
    "updateSamplesCheckbox",
    "updateSamplesLabel",
    "sampleAttributes",
    "samplesheetParamsForm",
    "samplesheetReadyTemplate",
    "ariaLive",
  ];

  static values = {
    dataMissingError: { type: String },
    formError: { type: String },
    url: { type: String },
    noSelectedFile: { type: String },
    automatedWorkflow: { type: Boolean },
    nameMissing: { type: String },
    allowedToUpdateSamplesString: { type: String },
    notAllowedToUpdateSamplesString: { type: String },
    processingError: { type: String },
    loadingCompleteAnnouncement: { type: String },
  };

  static outlets = [
    "selection",
    "nextflow--samplesheet--header",
    "nextflow--samplesheet--pagination",
  ];

  #columnNames;
  #requiredColumns = [];

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

  // sample data is contained within a nested object, so we'll extract the sample_ids from the object and utilize
  // allSampleIds array for indexes on the samplesheet table
  #allSampleIds;

  // samplesheetAttributes will contain the file global IDs, however we still require the file IDs and filenames for
  // the file_selector when users want to change the selected file, which will be contained in fileAttributes
  #fileAttributes;

  #allowedToUpdateSamples;

  // current sample 'indexes' present on table, used by metadata and table loading
  #startingIndex;
  #lastIndex;

  connect() {
    this.element.setAttribute("data-controller-connected", "true");
  }

  disconnect() {
    if (this.hasSamplesheetParamsFormTarget && this.boundAmendForm) {
      this.samplesheetParamsFormTarget.removeEventListener(
        "turbo:before-fetch-request",
        this.boundAmendForm,
      );
    }
  }

  sampleAttributesTargetConnected() {
    const dataAttributes = this.sampleAttributesTarget.dataset;
    this.#samplesheetAttributes = JSON.parse(
      dataAttributes.sampleAttributes || "{}",
    );
    this.#allowedToUpdateSamples = JSON.parse(
      dataAttributes.allowedToUpdateSamples || "false",
    );
    this.#allSampleIds = Object.keys(this.#samplesheetAttributes);

    this.#fileAttributes = JSON.parse(this.fileAttributesTarget.innerHTML);
    this.fileAttributesTarget.remove();

    if (Object.keys(this.#samplesheetAttributes).length === 0) {
      this.samplesheetSpinnerTarget.remove();
      this.#enableErrorState(this.processingErrorValue);
    } else {
      // remove node after retrieving data
      this.sampleAttributesTarget.remove();
      this.#processSamplesheet();
    }
  }

  #processSamplesheet() {
    this.#setSamplesheetParametersAndData();
    this.#disableProcessingState();
    if (this.hasNextflowSamplesheetHeaderOutlet) {
      this.nextflowSamplesheetHeaderOutlet.samplesheetReady();
    }
    this.#addLoadingCompleteMessage();
  }

  #addLoadingCompleteMessage() {
    this.samplesheetMessagesContainerTarget.innerHTML = "";

    const samplesheetReadyMessage =
      this.samplesheetReadyTemplateTarget.content.cloneNode(true);
    this.samplesheetMessagesContainerTarget.appendChild(
      samplesheetReadyMessage,
    );
    announce(this.loadingCompleteAnnouncementValue, {
      element: this.ariaLiveTarget,
    });
  }

  #setSamplesheetParametersAndData() {
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

    // set initial sample indexes to include all samples
    this.#setCurrentSampleIndexesToAll();

    // specify the available columns for filtering
    this.#setFilterableColumns();

    // setup pagination
    this.#promptPaginationAndLoadTable();
  }

  submitSamplesheet(event) {
    event.preventDefault();
    this.#enableSubmissionState();
    // 50ms timeout allows the browser to update the DOM elements enabling the overlay prior to starting the submission
    setTimeout(() => {
      // By default we set nameValid to true
      let nameValid = true;

      // If the workflow execution is not an automated workflow execution,
      // we check to see if the name is valid
      if (this.automatedWorkflowValue == false) {
        nameValid = this.#validateWorkflowExecutionName();
      }

      if (nameValid) {
        this.#disableFormFieldErrorState();

        const missingData = this.#validateData();
        if (Object.keys(missingData).length > 0) {
          this.#disableSubmissionState();
          let errorMsg = this.dataMissingErrorValue;
          for (const sample in missingData) {
            errorMsg =
              errorMsg + `\n - ${sample}: ${missingData[sample].join(", ")}`;
          }
          this.#enableErrorState(errorMsg);
        } else {
          this.#disableErrorState();

          this.formTarget.addEventListener(
            "turbo:before-fetch-request",
            (event) => {
              event.detail.fetchOptions.body = JSON.stringify(
                this.#compactFormData(),
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
      } else {
        this.#disableSubmissionState();
        this.#enableFormFieldErrorState(this.formErrorValue);
      }
    }, 50);
  }

  #validateData() {
    const missingData = {};
    this.#requiredColumns.forEach((requiredColumn) => {
      for (
        let i = 0;
        i < Object.keys(this.#samplesheetAttributes).length;
        i++
      ) {
        const sampleId = this.#allSampleIds[i];
        if (!this.#retrieveSampleData(sampleId, requiredColumn)) {
          const sample = this.#retrieveSampleData(sampleId, "sample");
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

  #disableProcessingState() {
    this.submitTarget.disabled = false;
    this.samplesheetSpinnerTarget.remove();
    this.updateSamplesSpinnerTarget.remove();
    if (this.hasUpdateSamplesLabelTarget) {
      const container = this.updateSamplesLabelTarget.parentNode;
      container.classList.remove("hidden");
      container.setAttribute("aria-hidden", false);
      this.updateSamplesLabelTarget.innerHTML = "";
      if (this.#allowedToUpdateSamples) {
        this.updateSamplesLabelTarget.innerText =
          this.allowedToUpdateSamplesStringValue;
        this.updateSamplesCheckboxTarget.disabled = false;
        this.updateSamplesCheckboxTarget.setAttribute("aria-disabled", "false");
      } else {
        this.updateSamplesLabelTarget.innerText =
          this.notAllowedToUpdateSamplesStringValue;
        this.updateSamplesLabelTarget.classList.add("pointer-events-none");
        this.updateSamplesCheckboxTarget.checked = false;
        this.updateSamplesCheckboxTarget.disabled = true;
        this.updateSamplesCheckboxTarget.setAttribute("aria-disabled", "true");
      }
    }
  }

  #enableSubmissionState() {
    this.submitTarget.disabled = true;
    this.submissionSpinnerTarget.classList.remove("hidden");
  }

  #disableSubmissionState() {
    this.submissionSpinnerTarget.classList.add("hidden");
    this.submitTarget.disabled = false;
  }

  #disableErrorState() {
    this.errorTarget.classList.add("hidden");
    this.errorMessageTarget.innerHTML = "";
  }

  #enableErrorState(message) {
    this.errorTarget.classList.remove("hidden");
    this.errorMessageTarget.innerHTML = message;
    this.errorMessageTarget.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
  }

  #enableFormFieldErrorState(message) {
    this.formFieldErrorTarget.classList.remove("hidden");
    this.formFieldErrorMessageTarget.innerHTML = message;
    this.formFieldErrorTarget.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
    this.samplesheetMessagesContainerTarget.innerHTML = "";
  }

  #disableFormFieldErrorState() {
    this.formFieldErrorTarget.classList.add("hidden");
    this.formFieldErrorMessageTarget.innerHTML = "";
  }

  #setSampleData(sampleId, columnName, value) {
    this.#samplesheetAttributes[sampleId]["samplesheet_params"][columnName] =
      value;
  }

  #retrieveSampleData(sampleId, columnName) {
    return this.#samplesheetAttributes[sampleId]["samplesheet_params"][
      columnName
    ];
  }

  // handles changes to text and dropdown cells
  updateEditableSamplesheetData(event) {
    const sampleId = event.params.sampleId;
    const columnName = event.params.columnName;
    const value = event.target.value;
    this.#setSampleData(sampleId, columnName, value);
  }

  // handles changes to file cells; triggered by nextflow/file_controller.js
  #updateFileData(files) {
    const sample_id = files["attachable_id"];
    files["files"].forEach((file, index) => {
      this.#fileAttributes[sample_id][file["property"]].attachment_id = file.id;
      this.#fileAttributes[sample_id][file["property"]].filename = file[
        "filename"
      ]
        ? file["filename"]
        : this.noSelectedFileValue;

      this.#samplesheetAttributes[sample_id]["samplesheet_params"][
        file["property"]
      ] = file.global_id;
      this.#updateCell(file["property"], sample_id, "file_cell", index === 0);
    });
  }

  #updateMetadata(metadata, headers) {
    this.#samplesheetAttributes = merge(this.#samplesheetAttributes, metadata);
    for (let i = this.#startingIndex; i < this.#lastIndex; i++) {
      headers.forEach((header) => {
        this.#updateCell(
          header,
          this.#allSampleIds[this.#currentSampleIndexes[i]],
          "metadata_cell",
          false,
        );
      });
    }
  }

  loadTableData(currentPage, lastPage) {
    // delete the table data and reload with new indexes
    this.tableBodyTarget.innerHTML = "";
    if (this.#currentSampleIndexes.length > 0) {
      this.emptyStateTarget.classList.add("hidden");
      this.#startingIndex = (currentPage - 1) * 5;
      this.#lastIndex = this.#startingIndex + 5;
      if (
        currentPage == lastPage &&
        this.#currentSampleIndexes.length % 5 != 0
      ) {
        this.#lastIndex =
          (this.#currentSampleIndexes.length % 5) + this.#startingIndex;
      }
      for (let i = this.#startingIndex; i < this.#lastIndex; i++) {
        const sampleId = this.#allSampleIds[this.#currentSampleIndexes[i]];
        const tableRow = this.#generateTableRow();

        this.#columnNames.forEach((columnName) => {
          const cell = this.#generateTableCell(
            columnName,
            sampleId,
            this.#columnNames.indexOf(columnName) == 0,
          );
          switch (this.#samplesheetProperties[columnName]["cell_type"]) {
            case "sample_cell":
            case "sample_name_cell":
              this.#insertSampleContent(cell, columnName, sampleId);
              break;
            case "dropdown_cell":
              this.#insertDropdownContent(
                cell,
                columnName,
                sampleId,
                this.#samplesheetProperties[columnName]["enum"],
              );
              break;
            case "fastq_cell":
            case "file_cell":
              this.#insertFileContent(cell, columnName, sampleId);
              break;
            case "metadata_cell":
              this.#insertMetadataContent(cell, columnName, sampleId);
              break;
            case "input_cell":
              this.#insertTextInputContent(cell, columnName, sampleId);
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

  #generateTableCell(columnName, sampleId, headerCell) {
    const template = headerCell
      ? this.thTemplateTarget.content.cloneNode(true)
      : this.tdTemplateTarget.content.cloneNode(true);
    const cell = template.firstElementChild;
    cell.id = `${sampleId}_${columnName}`;
    return cell;
  }

  #insertSampleContent(cell, columnName, sampleId) {
    const sampleContent =
      this.sampleIdentifierTemplateTarget.content.cloneNode(true);

    sampleContent.querySelector("div").textContent = this.#retrieveSampleData(
      sampleId,
      columnName,
    );

    cell.appendChild(sampleContent);
  }

  #insertDropdownContent(cell, columnName, sampleId, options) {
    const name = `${sampleId}_${columnName}`;
    const id = `${sampleId}_${columnName}_dropdown`;

    const dropdownContent = this.dropdownTemplateTarget.content.cloneNode(true);
    const selectNode = dropdownContent.querySelector("select");
    selectNode.setAttribute("aria-label", columnName);
    this.#setDataAttributes(selectNode, name, id, sampleId, columnName);

    for (let j = 0; j < options.length; j++) {
      const option = document.createElement("option");
      option.value = options[j];
      option.innerHTML = options[j];
      dropdownContent.querySelector("select").appendChild(option);
    }

    dropdownContent.querySelector("select").value = this.#retrieveSampleData(
      sampleId,
      columnName,
    );

    cell.appendChild(dropdownContent);
  }

  #insertFileContent(cell, columnName, sampleId) {
    const fileContent = this.fileTemplateTarget.content.cloneNode(true);
    const fileLink = fileContent.querySelector("a");
    // Build URL parameters
    const params = new URLSearchParams({
      "file_selector[attachable_id]": sampleId,
      "file_selector[attachable_type]": "Sample",
      "file_selector[pattern]": this.#samplesheetProperties[columnName].pattern,
      "file_selector[property]": columnName,
      "file_selector[selected_id]":
        this.#fileAttributes[sampleId][columnName].attachment_id,
      "file_selector[namespace_id]": fileLink.getAttribute("data-namespace-id"),
    });

    // Add required properties
    const requiredProperties = [...this.#requiredColumns];

    // Check if sample column is required
    if (this.#samplesheetProperties.sample?.required) {
      requiredProperties.push("sample");
    }

    // Add required properties to params
    requiredProperties.forEach((prop) => {
      params.append("file_selector[required_properties][]", prop);
    });

    // Set link attributes
    const href = `/-/workflow_executions/file_selector/new?${params.toString()}`;
    const linkId = `${sampleId}_${columnName}_file_link`;
    const filename = this.#fileAttributes[sampleId][columnName].filename;
    fileLink.setAttribute("href", href);
    fileLink.id = linkId;
    fileLink.textContent = filename;

    // Append to cell
    cell.appendChild(fileContent);
  }

  #insertMetadataContent(cell, columnName, sampleId) {
    const metadataValue = this.#retrieveSampleData(sampleId, columnName);
    if (metadataValue) {
      const metadataContent =
        this.metadataTemplateTarget.content.cloneNode(true);
      metadataContent.querySelector("span").textContent = metadataValue;
      cell.appendChild(metadataContent);
    } else {
      this.#insertTextInputContent(cell, columnName, sampleId);
    }
  }

  #insertTextInputContent(cell, columnName, sampleId) {
    const textInputContent =
      this.textInputTemplateTarget.content.cloneNode(true);
    const name = `${sampleId}_${columnName}`;
    const id = `${sampleId}_${columnName}_input`;
    const input = textInputContent.querySelector("input");
    const label = textInputContent.querySelector("label");

    this.#setDataAttributes(input, name, id, sampleId, columnName);

    label.setAttribute("for", id);
    label.textContent = name;

    const inputValue = this.#retrieveSampleData(sampleId, columnName);
    if (inputValue) {
      input.value = inputValue;
    }

    cell.appendChild(textInputContent);
  }

  #setDataAttributes(node, name, id, sampleId, columnName) {
    node.setAttribute("name", name);
    node.setAttribute("id", id);
    node.setAttribute(
      "data-nextflow--deferred-samplesheet-sample-id-param",
      sampleId,
    );
    node.setAttribute(
      "data-nextflow--deferred-samplesheet-column-name-param",
      columnName,
    );
  }

  #updateCell(columnName, sampleId, cellType, focusCell) {
    const cell = document.getElementById(`${sampleId}_${columnName}`);
    if (cell) {
      cell.innerHTML = "";
      if (cellType == "file_cell") {
        this.#insertFileContent(cell, columnName, sampleId);
      } else {
        this.#insertMetadataContent(cell, columnName, sampleId);
      }
      if (focusCell) {
        cell.firstElementChild.focus();
      }
    }
  }

  #setCurrentSampleIndexesToAll() {
    this.#currentSampleIndexes = [
      ...Array(Object.keys(this.#allSampleIds).length).keys(),
    ];
  }

  // check samplesheet properties for sample and sample_name and add them as filterable if present
  #setFilterableColumns() {
    if (Object.hasOwn(this.#samplesheetProperties, "sample")) {
      this.#filterableColumns.push("sample");
    }

    if (Object.hasOwn(this.#samplesheetProperties, "sample_name")) {
      this.#filterableColumns.push("sample_name");
    }
  }

  #compactFormData() {
    const compactFormData = new FormData(this.formTarget);

    const params = formDataToJsonParams(compactFormData);
    params["workflow_execution"]["samples_workflow_executions_attributes"] =
      Object.values(this.#samplesheetAttributes);
    return params;
  }

  #validateWorkflowExecutionName() {
    const name = document.getElementById("workflow_execution_name");
    let hasErrors = false;

    if (name.value === "") {
      hasErrors = true;
    }

    if (hasErrors) {
      this.#addNameFieldErrorState();
      return false;
    } else {
      this.#removeNameFieldErrorState();
    }

    return true;
  }

  #addNameFieldErrorState() {
    const nameError = document.getElementById(
      "workflow_execution_name_error",
    ).lastElementChild;
    const nameErrorSpan = nameError.getElementsByClassName("grow")[0];
    const name = document.getElementById("workflow_execution_name");
    const nameHint = document.getElementById("workflow_execution_name_hint");
    const nameField = document.getElementById("workflow_execution_name_field");

    name.setAttribute("autofocus", true);
    name.setAttribute("aria-invalid", true);
    name.setAttribute("aria-describedBy", "workflow_execution_name_error");
    name.classList.remove(...FIELD_CLASSES["VALID"]);
    name.classList.add(...FIELD_CLASSES["ERROR"]);
    nameError.classList.remove("hidden");
    nameErrorSpan.innerHTML = this.nameMissingValue;
    nameErrorSpan.classList.add(...FIELD_CLASSES["ERROR_SPAN"]);
    nameHint.classList.add("hidden");
    nameField.classList.add("invalid");
  }

  #removeNameFieldErrorState() {
    const nameError = document.getElementById(
      "workflow_execution_name_error",
    ).lastElementChild;
    const nameErrorSpan = nameError.getElementsByClassName("grow")[0];
    const name = document.getElementById("workflow_execution_name");
    const nameHint = document.getElementById("workflow_execution_name_hint");
    const nameField = document.getElementById("workflow_execution_name_field");

    name.removeAttribute("autofocus", false);
    name.removeAttribute("aria-invalid");
    name.removeAttribute("aria-describedBy");
    name.classList.remove(...FIELD_CLASSES["ERROR"]);
    name.classList.add(...FIELD_CLASSES["VALID"]);
    nameError.classList.add("hidden");
    nameErrorSpan.innerHTML = "";
    nameErrorSpan.classList.remove(...FIELD_CLASSES["ERROR_SPAN"]);
    nameHint.classList.remove("hidden");
    nameField.classList.remove("invalid");
  }

  samplesheetPropertiesTargetConnected() {
    this.#samplesheetProperties =
      this.samplesheetPropertiesTarget.dataset.properties;
    this.boundAmendForm = this.amendForm.bind(this);

    this.samplesheetParamsFormTarget.addEventListener(
      "turbo:before-fetch-request",
      this.boundAmendForm,
    );
    this.#submitSamplesheetParams();
  }

  amendForm(event) {
    const formData = new FormData(this.samplesheetParamsFormTarget);
    event.detail.fetchOptions.body = JSON.stringify(this.#toJson(formData));
    event.detail.fetchOptions.headers["Content-Type"] = "application/json";

    event.detail.resume();
  }

  #toJson(formData) {
    const params = formDataToJsonParams(formData);
    if (this.hasSelectionOutlet) {
      normalizeParams(
        params,
        "sample_ids[]",
        this.selectionOutlet.getOrCreateStoredItems(),
        0,
      );
    }
    return params;
  }

  #submitSamplesheetParams() {
    const fragment = document.createDocumentFragment();

    fragment.appendChild(
      createHiddenInput("properties", this.#samplesheetProperties),
    );

    this.#samplesheetProperties = JSON.parse(this.#samplesheetProperties);
    // clear the now unnecessary DOM element
    this.samplesheetPropertiesTarget.remove();

    this.samplesheetParamsFormTarget.appendChild(fragment);
    this.samplesheetParamsFormTarget.requestSubmit();
  }

  dataPayloadTargetConnected() {
    const payloadType =
      this.dataPayloadTarget.getAttribute("data-payload-type");
    if (payloadType === "metadata") {
      const metadata = JSON.parse(
        this.dataPayloadTarget.getAttribute("data-metadata"),
      );
      const headers = JSON.parse(
        this.dataPayloadTarget.getAttribute("data-headers"),
      );
      this.#updateMetadata(metadata, headers);
    } else if (payloadType === "files") {
      const files = JSON.parse(
        this.dataPayloadTarget.getAttribute("data-files"),
      );
      this.#updateFileData(files);
    }

    this.dataPayloadTarget.remove();
  }

  // when filtering samples, we will add the indexes of samples that fit the filter into the #currentSampleIndexes array.
  // we can then easily access each sample's data via its index and still paginate in pages of 5
  applyFilter(filterValue) {
    if (filterValue) {
      this.#currentSampleIndexes = [];
      for (let i = 0; i < this.#totalSamples; i++) {
        for (let j = 0; j < this.#filterableColumns.length; j++) {
          if (
            this.#samplesheetAttributes[this.#allSampleIds[i]][
              "samplesheet_params"
            ][this.#filterableColumns[j]]
              .toLowerCase()
              .includes(filterValue.toLowerCase())
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
    this.#promptPaginationAndLoadTable();
  }

  #promptPaginationAndLoadTable() {
    this.nextflowSamplesheetPaginationOutlet.setPagination(
      this.#currentSampleIndexes.length,
    );
  }

  retrieveSampleIds() {
    return this.#allSampleIds;
  }
}
