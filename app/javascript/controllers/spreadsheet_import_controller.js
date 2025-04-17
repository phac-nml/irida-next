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

  #defaultSampleColumnHeaders = [
    "sample_name",
    "sample name",
    "sample",
    "sample_id",
    "sample id",
  ];

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
      const headers = XLSX.utils.sheet_to_json(worksheet, {
        header: 1,
      })[0];
      // sort case insensitively
      this.#allHeaders = headers.sort(function (a, b) {
        return a.toLowerCase().localeCompare(b.toLowerCase());
      });
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
      this.#selectedHeaders["sampleColumn"],
      unselectedHeaders,
    );
    if (this.hasProjectPUIDColumnTarget) {
      this.#refreshInputOptions(
        this.projectPUIDColumnTarget,
        this.#selectedHeaders["projectColumn"],
        unselectedHeaders,
      );
    }
    this.#refreshInputOptions(
      this.sampleDescriptionColumnTarget,
      this.#selectedHeaders["descriptionColumn"],
      unselectedHeaders,
    );
    this.checkFormInputsReadyForSubmit();
  }

  #refreshInputOptions(columnTarget, currentSelection, unselectedHeaders) {
    // rebuild select options list
    columnTarget.innerHTML = "";

    // add blank value
    columnTarget.append(this.#createInputOption(
      "",
      this.#blankValues[columnTarget.id],
    ));

    // add currently selected option
    if (currentSelection) {
      columnTarget.append(this.#createInputOption(currentSelection, currentSelection));
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
          columnTarget.append(this.#createInputOption(
            copyUnselectedHeaders[sampleIndex],
            copyUnselectedHeaders[sampleIndex],
          ));
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
    // set default to true so project imports can by pass project selection validation
    let projectSelected = true;
    let staticProjectSelected = true;
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

  #createInputOptions(column, values) {
    for (let value of values) {
      column.append(this.#createInputOption(value, value));
    }
  }

  #createInputOption(value, text) {
    let option = document.createElement("option");
    option.value = value;
    option.text = text;
    return option
  }

  #processUnselectedHeaders() {
    // filter out used options
    return this.#allHeaders.filter(
      (item) => !Object.values(this.#selectedHeaders).includes(item),
    );
  }
}
