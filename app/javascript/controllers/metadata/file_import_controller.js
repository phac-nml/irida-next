import * as XLSX from "xlsx";

import { Controller } from "@hotwired/stimulus";
import { notifyRefreshControllers } from "utilities/refresh";

export default class extends Controller {
  static outlets = ["viral--sortable-lists--two-lists-selection", "refresh"];
  static targets = [
    "sampleIdColumn",
    "metadataColumns",
    "submitButton",
    "error",
    "sortableListsTemplate",
    "sortableListsItemTemplate",
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
      this.#sortableListsConnect();
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
        this.#sortableListsConnect();
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
      this.#unhideElement(this.metadataColumnsTarget);
      this.metadataColumnsTarget.innerHTML =
        this.sortableListsTemplateTarget.innerHTML;

      columns.forEach((column) => {
        const formattedColumn = column.replace(/\s+/g, "-");
        const template =
          this.sortableListsItemTemplateTarget.content.cloneNode(true);
        template.querySelector("li").firstElementChild.id =
          `${formattedColumn}_unselected`;
        template.querySelector("li").lastElementChild.innerText = column;
        template.querySelector("li").id = formattedColumn;
        this.metadataColumnsTarget
          .querySelector("#selected-list")
          .append(template);
      });
      this.submitButtonTarget.disabled = !columns.length;
    } else {
      this.#hideElement(this.metadataColumnsTarget);
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
      this.#hideElement(this.metadataColumnsTarget);
      this.errorTarget.setAttribute("aria-disabled", "true");
    }
  }

  #enableDialogState() {
    this.#enableTarget(this.submitButtonTarget);
    if (this.hasMetadataColumnsTarget) {
      this.#addMetadataColumns();
    }
  }

  #disableErrorState() {
    this.#hideElement(this.errorTarget);
  }

  #enableErrorState() {
    this.#unhideElement(this.errorTarget);
    this.#disableTarget(this.submitButtonTarget);
  }

  #hideElement(element) {
    element.classList.add("hidden");
    element.setAttribute("aria-hidden", "true");
  }

  #unhideElement(element) {
    element.classList.remove("hidden");
    element.removeAttribute("aria-hidden");
  }

  #sortableListsConnect() {
    if (this.hasViralSortableListsTwoListsSelectionOutlet) {
      this.viralSortableListsTwoListsSelectionOutlet.idempotentConnect();
    }
  }

  handleSubmit() {
    notifyRefreshControllers(this);
  }
}
