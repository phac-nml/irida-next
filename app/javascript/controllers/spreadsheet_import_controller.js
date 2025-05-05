import { Controller } from "@hotwired/stimulus";
import * as XLSX from "xlsx";

export default class extends Controller {
  static targets = [
    "sampleNameColumn",
    "projectPUIDColumn",
    "sampleDescriptionColumn",
    "submitButton",
    "metadata",
  ];

  static values = {
    selectSample: String,
    selectDescription: String,
    selectProject: String,
  };

  #defaultSampleColumnHeaders = [
    "sample_name",
    "sample name",
    "sample",
    "sample_id",
    "sample id",
  ];

  #allHeaders;
  #selectedHeaders = {
    spreadsheet_import_sample_name_column: null,
    spreadsheet_import_sample_description_column: null,
  };
  #blankValues = {
    spreadsheet_import_sample_name_column: this.selectSampleValue,
    spreadsheet_import_sample_description_column: this.selectDescriptionValue,
  };

  connect() {
    if (this.hasProjectPUIDColumnTarget) {
      this.#selectedHeaders["spreadsheet_import_project_puid_column"] = null;
      this.#blankValues["spreadsheet_import_project_puid_column"] =
        this.selectProjectValue;
      this.staticProjectInput = document.getElementById(
        "spreadsheet_import_static_project_id",
      );
    }
  }

  changeInputValue(event) {
    switch (event.target.id) {
      case this.sampleNameColumnTarget.id:
        this.#updateInputValue(this.sampleNameColumnTarget, event.target.value);
        this.#refreshInputOptionsForAllFields();
        break;
      case this.sampleDescriptionColumnTarget.id:
        this.#updateInputValue(
          this.sampleDescriptionColumnTarget,
          event.target.value,
        );
        this.#refreshInputOptionsForAllFields();
        break;
      case this.projectPUIDColumnTarget.id:
        this.#updateInputValue(
          this.projectPUIDColumnTarget,
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
      const headers = XLSX.utils.sheet_to_json(worksheet, {
        header: 1,
      })[0];
      // sort case insensitively
      this.#allHeaders = headers.sort(function (a, b) {
        return a.toLowerCase().localeCompare(b.toLowerCase());
      });
      this.#setAutoSelections();
      this.checkFormInputsReadyForSubmit();
    };
  }

  #clearFormOptions() {
    this.#selectedHeaders = {
      spreadsheet_import_sample_name_column: null,
      spreadsheet_import_sample_description_column: null,
    };
    this.#resetSelectInput(this.sampleNameColumnTarget);
    if (this.hasProjectPUIDColumnTarget) {
      this.#selectedHeaders["spreadsheet_import_project_puid_column"] = null;
      this.#resetSelectInput(this.projectPUIDColumnTarget);
    }
    this.#resetSelectInput(this.sampleDescriptionColumnTarget);
    this.submitButtonTarget.disabled = true;
  }

  #setAutoSelections() {
    // lower case to test for case insensitivity
    const allHeadersToLowerCase = this.#allHeaders.map((header) =>
      header.toLowerCase(),
    );
    for (const sampleColumnHeader of this.#defaultSampleColumnHeaders) {
      const sampleIndex = allHeadersToLowerCase.indexOf(sampleColumnHeader);
      if (sampleIndex > -1) {
        this.#updateInputValue(
          this.sampleNameColumnTarget,
          this.#allHeaders[sampleIndex],
        );
        break;
      }
    }

    const descriptionIndex = allHeadersToLowerCase.indexOf("description");
    if (descriptionIndex > -1) {
      this.#updateInputValue(
        this.sampleDescriptionColumnTarget,
        this.#allHeaders[descriptionIndex],
      );
    }

    if (this.hasProjectPUIDColumnTarget) {
      const projectIndex = allHeadersToLowerCase.indexOf("project_puid");
      if (projectIndex > -1) {
        this.#updateInputValue(
          this.projectPUIDColumnTarget,
          this.#allHeaders[projectIndex],
        );
      }
    }

    this.#refreshInputOptionsForAllFields();
  }

  #refreshInputOptionsForAllFields() {
    const unselectedHeaders = this.#processUnselectedHeaders();
    this.#refreshInputOptions(
      this.sampleNameColumnTarget,
      this.#selectedHeaders["spreadsheet_import_sample_name_column"],
      unselectedHeaders,
    );
    if (this.hasProjectPUIDColumnTarget) {
      this.#refreshInputOptions(
        this.projectPUIDColumnTarget,
        this.#selectedHeaders["spreadsheet_import_project_puid_column"],
        unselectedHeaders,
      );
    }
    this.#refreshInputOptions(
      this.sampleDescriptionColumnTarget,
      this.#selectedHeaders["spreadsheet_import_sample_description_column"],
      unselectedHeaders,
    );

    if (unselectedHeaders.length > 0) {
      this.sendMetadata(unselectedHeaders);
      this.metadataTarget.classList.remove("hidden");
    } else {
      this.metadataTarget.classList.add("hidden");
    }
    this.checkFormInputsReadyForSubmit();
  }

  #refreshInputOptions(columnTarget, currentSelection, unselectedHeaders) {
    // rebuild select options list
    columnTarget.innerHTML = "";

    // add blank value
    this.#appendBlankValue(columnTarget);

    // add currently selected option
    if (currentSelection) {
      columnTarget.append(
        this.#createInputOption(currentSelection, currentSelection),
      );
      columnTarget.value = currentSelection;
    }

    // add unused options

    // if sample column, move all additional sample headers to top of option, remaining under
    // else just add headers normally
    if (columnTarget === this.sampleNameColumnTarget) {
      // copy unselected headers as we'll be removing array values
      // also create a copy that lower cases all values to test for case insensitivity
      let copyUnselectedHeaders = unselectedHeaders.slice();
      let lowerCasedUnselectedHeaders = copyUnselectedHeaders.map((header) =>
        header.toLowerCase(),
      );
      for (const sampleColumnHeader of this.#defaultSampleColumnHeaders) {
        const sampleIndex =
          lowerCasedUnselectedHeaders.indexOf(sampleColumnHeader);
        if (sampleIndex > -1) {
          columnTarget.append(
            this.#createInputOption(
              copyUnselectedHeaders[sampleIndex],
              copyUnselectedHeaders[sampleIndex],
            ),
          );
          // remove sample header so only 'non-sample' headers remain
          copyUnselectedHeaders.splice(sampleIndex, 1);
          lowerCasedUnselectedHeaders.splice(sampleIndex, 1);
        }
      }
      this.#createInputOptions(columnTarget, copyUnselectedHeaders);
    } else {
      this.#createInputOptions(columnTarget, unselectedHeaders);
    }
    this.#enableTarget(columnTarget);
  }

  checkFormInputsReadyForSubmit() {
    console.log("in check form inputs");
    // set default to true so project imports can by pass project selection validation
    let projectSelected = true;
    let staticProjectSelected = true;
    if (this.hasProjectPUIDColumnTarget) {
      projectSelected = this.projectPUIDColumnTarget.value;
      staticProjectSelected = this.staticProjectInput.value;
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

  #createInputOptions(column, values) {
    for (let value of values) {
      column.append(this.#createInputOption(value, value));
    }
  }

  #createInputOption(value, text) {
    let option = document.createElement("option");
    option.value = value;
    option.text = text;
    return option;
  }

  #processUnselectedHeaders() {
    // filter out used options
    return this.#allHeaders.filter(
      (item) => !Object.values(this.#selectedHeaders).includes(item),
    );
  }

  #resetSelectInput(columnTarget) {
    columnTarget.innerHTML = "";
    this.#appendBlankValue(columnTarget);
    this.#disableTarget(columnTarget);
  }

  #appendBlankValue(columnTarget) {
    columnTarget.append(
      this.#createInputOption("", this.#blankValues[columnTarget.id]),
    );
  }

  sendMetadata(unselectedHeaders) {
    this.dispatch("sendMetadata", {
      detail: {
        content: { metadata: unselectedHeaders },
      },
    });
  }
}
