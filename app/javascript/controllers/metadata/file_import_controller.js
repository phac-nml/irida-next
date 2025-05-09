import * as XLSX from "xlsx";

import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "sampleIdColumn",
    "metadataColumns",
    "submitButton",
    "error",
  ];

  #defaultSampleColumnHeaders = [
    "sample_name",
    "sample name",
    "sample",
    "sample_id",
    "sample id",
    "sample_puid",
    "sample puid",
  ];

  #ignoreList = [
    "sample_name",
    "sample name",
    "sample",
    "sample_id",
    "sample id",
    "sample_puid",
    "sample puid",
    "project id",
    "project_id",
    "project_puid",
    "project puid",
    "created_at",
    "updated_at",
    "last_updated_at",
    "description",
  ];

  #headers = [];

  changeSampleIDInput(event) {
    const { value } = event.target;
    if (value) {
      this.#enableDialogState();
    } else {
      this.#resetDialogState();
    }
  }

  readFile(event) {
    const { files } = event.target;

    this.#removeSampleIDInputOptions();
    this.#resetDialogState();
    this.#disableErrorState();
    if (!files.length) {
      return;
    }

    const reader = new FileReader();
    reader.readAsArrayBuffer(files[0]);

    reader.onload = () => {
      const workbook = XLSX.read(reader.result, { sheetRows: 1 });
      const worksheetName = workbook.SheetNames[0];
      const worksheet = workbook.Sheets[worksheetName];
      this.#headers = XLSX.utils.sheet_to_json(worksheet, { header: 1 })[0];
      this.#addSampleIDInputOptions();
    };
  }

  #removeSampleIDInputOptions() {
    this.#removeInputOptions(this.sampleIdColumnTarget);
    this.#disableTarget(this.sampleIdColumnTarget);
  }

  #addSampleIDInputOptions() {
    for (let header of this.#headers) {
      const option = document.createElement("option");
      option.value = header;
      option.text = header;
      this.sampleIdColumnTarget.append(option);
    }
    // lower case to test for case insensitivity
    const allHeadersToLowerCase = this.#headers.map((header) =>
      header.toLowerCase(),
    );
    for (const sampleColumnHeader of this.#defaultSampleColumnHeaders) {
      const sampleIndex = allHeadersToLowerCase.indexOf(sampleColumnHeader);
      if (sampleIndex > -1) {
        this.sampleIdColumnTarget.value = this.#headers[sampleIndex];
        this.#enableDialogState();
        break;
      }
    }
    this.#enableTarget(this.sampleIdColumnTarget);
  }

  #addMetadataColumns() {
    let columns = this.#headers.filter(
      (header) =>
        !this.#ignoreList.includes(header.toLowerCase()) &&
        header.toLowerCase() != this.sampleIdColumnTarget.value.toLowerCase(),
    );
    if (columns.length > 0) {
      this.metadataColumnsTarget.classList.remove("hidden");
      this.sendMetadata(columns);
    } else {
      this.metadataColumnsTarget.classList.add("hidden");
      this.#enableErrorState();
    }
  }

  #removeInputOptions(target) {
    while (target.options.length > 1) {
      target.remove(target.options.length - 1);
    }
  }

  #disableTarget(target) {
    target.disabled = true;
    target.setAttribute("aria-disabled", "true");
  }

  #enableTarget(target) {
    target.disabled = false;
    target.removeAttribute("aria-disabled");
  }

  #resetDialogState() {
    this.#disableTarget(this.submitButtonTarget);
    if (this.hasMetadataColumnsTarget) {
      this.metadataColumnsTarget.classList.add("hidden");
    }
  }

  #enableDialogState() {
    this.#enableTarget(this.submitButtonTarget);
    if (this.hasMetadataColumnsTarget) {
      this.#addMetadataColumns();
    }
  }

  #disableErrorState() {
    this.errorTarget.classList.add("hidden");
    this.errorTarget.setAttribute("aria-disabled", "true");
  }

  #enableErrorState() {
    this.errorTarget.classList.remove("hidden");
    this.errorTarget.removeAttribute("aria-hidden");
    this.#disableTarget(this.submitButtonTarget);
  }

  sendMetadata(unselectedHeaders) {
    this.dispatch("sendMetadata", {
      detail: {
        content: { metadata: unselectedHeaders },
      },
    });
  }
}
