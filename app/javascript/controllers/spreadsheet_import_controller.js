import { Controller } from "@hotwired/stimulus";
import * as XLSX from "xlsx";

export default class extends Controller {
  static targets = [
    "sampleNameColumn",
    "projectPUIDColumn",
    "sampleDescriptionColumn",
    "staticProject",
    "submitButton",
  ];

  static values = {
    selectSample: String,
    selectDescription: String,
    selectProject: String,
  };

  #allHeaders;
  #selectedHeaders = { sampleColumn: null, descriptionColumn: null };
  #blankValues = {
    sampleColumn: this.selectSampleValue,
    descriptionColumn: this.selectDescriptionValue,
  };

  connect() {
    if (this.hasProjectPUIDColumnTarget) {
      this.#selectedHeaders["projectColumn"] = null;
      this.#blankValues["projectColumn"] = this.selectProjectValue;
    }
  }

  changeInputValue(event) {
    switch (event.target.id) {
      case "sampleColumn":
        this.#updateInputValue(this.sampleNameColumnTarget, event.target.value);
        this.#refreshInputOptionsForAllFields();
        break;
      case "projectColumn":
        this.#updateInputValue(
          this.projectPUIDColumnTarget,
          event.target.value,
        );
        this.#refreshInputOptionsForAllFields();
        break;
      case "descriptionColumn":
        this.#updateInputValue(
          this.sampleDescriptionColumnTarget,
          event.target.value,
        );
        this.#refreshInputOptionsForAllFields();
        break;
    }
  }

  #updateInputValue(target, value) {
    this.#selectedHeaders[target.id] = value;
  }

  readFile(event) {
    const { files } = event.target;

    this.#clearFormOptions();

    if (!files.length) {
      return;
    }

    const reader = new FileReader();
    reader.readAsArrayBuffer(files[0]);

    reader.onload = () => {
      const workbook = XLSX.read(reader.result, { sheetRows: 1 });
      const worksheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[worksheetName];
      this.#allHeaders = XLSX.utils
        .sheet_to_json(worksheet, {
          header: 1,
        })[0]
        .sort();
      this.#setAutoSelections();
      if (this.hasStaticProjectTarget) {
        this.#enableTarget(this.staticProjectTarget);
      }
      this.checkFormInputsReadyForSubmit();
    };
  }

  #clearFormOptions() {
    this.#selectedHeaders = { sampleColumn: null, descriptionColumn: null };
    this.sampleNameColumnTarget.innerHTML = "";
    this.#disableTarget(this.sampleNameColumnTarget);
    if (this.hasProjectPUIDColumnTarget) {
      this.#selectedHeaders["projectColumn"] = null;
      this.projectPUIDColumnTarget.innerHTML = "";
      this.#disableTarget(this.projectPUIDColumnTarget);
    }
    this.sampleDescriptionColumnTarget.innerHTML = "";
    this.#disableTarget(this.sampleDescriptionColumnTarget);
    this.submitButtonTarget.disabled = true;
  }

  #setAutoSelections() {
    if (this.#allHeaders.includes("sample_name")) {
      this.#updateInputValue(this.sampleNameColumnTarget, "sample_name");
    } else if (this.#allHeaders.includes("sample")) {
      this.#updateInputValue(this.sampleNameColumnTarget, "sample");
    }

    if (this.#allHeaders.includes("description")) {
      this.#updateInputValue(this.sampleDescriptionColumnTarget, "description");
    }

    if (
      this.#allHeaders.includes("project_puid") &&
      this.hasProjectPUIDColumnTarget
    ) {
      this.#updateInputValue(this.projectPUIDColumnTarget, "project_puid");
    }

    this.#refreshInputOptionsForAllFields();
  }

  #refreshInputOptionsForAllFields() {
    this.#refreshInputOptions(
      this.sampleNameColumnTarget,
      this.#selectedHeaders["sampleColumn"],
    );
    if (this.hasProjectPUIDColumnTarget) {
      this.#refreshInputOptions(
        this.projectPUIDColumnTarget,
        this.#selectedHeaders["projectColumn"],
      );
    }
    this.#refreshInputOptions(
      this.sampleDescriptionColumnTarget,
      this.#selectedHeaders["descriptionColumn"],
    );
    this.checkFormInputsReadyForSubmit();
  }

  #refreshInputOptions(columnTarget, currentSelection) {
    // filter out used options
    let unselectedHeaders = this.#allHeaders.filter(
      (item) => !Object.values(this.#selectedHeaders).includes(item),
    );

    // rebuild select options list
    columnTarget.innerHTML = "";

    // add blank value
    let option = document.createElement("option");
    option.value = "";
    option.text = this.#blankValues[columnTarget.id];
    columnTarget.append(option);

    // add currently selected option
    if (currentSelection) {
      let option = document.createElement("option");
      option.value = currentSelection;
      option.text = currentSelection;
      columnTarget.append(option);
      columnTarget.value = currentSelection;
    }

    // add unused options
    for (let header of unselectedHeaders) {
      let option = document.createElement("option");
      option.value = header;
      option.text = header;
      columnTarget.append(option);
    }
    this.#enableTarget(columnTarget);
  }

  checkFormInputsReadyForSubmit() {
    let projectSelected;
    let staticProjectSelected;
    if (this.hasProjectPUIDColumnTarget) {
      projectSelected = this.projectPUIDColumnTarget.value;
      staticProjectSelected = this.staticProjectTarget.value;
    }

    if (
      this.sampleNameColumnTarget.value &&
      (projectSelected || staticProjectSelected)
    ) {
      this.submitButtonTarget.disabled = false;
    } else {
      this.submitButtonTarget.disabled = true;
    }
  }

  #disableTarget(target) {
    target.disabled = true;
  }

  #enableTarget(target) {
    target.disabled = false;
  }
}
