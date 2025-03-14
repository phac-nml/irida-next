import { Controller } from "@hotwired/stimulus";
import * as XLSX from "xlsx";

export default class extends Controller {
  static targets = [
    "sampleNameColumn",
    "projectPUIDColumn",
    "sampleDescriptionColumn",
    "sortableListsTemplate",
    "sortableListsItemTemplate",
    "submitButton",
  ];

  #headers = [];
  #disabled_classes = [
    "bg-slate-50",
    "border",
    "border-slate-300",
    "text-slate-900",
    "text-sm",
    "rounded-lg",
    "focus:ring-blue-500",
    "focus:border-blue-500",
    "block",
    "w-full",
    "p-2.5",
    "dark:bg-slate-700",
    "dark:border-slate-600",
    "dark:placeholder-slate-400",
    "dark:text-white",
    "dark:focus:ring-blue-500",
    "dark:focus:border-blue-500",
  ];

  connect() {
    this.#disableTarget(this.sampleNameColumnTarget);
    this.#disableTarget(this.projectPUIDColumnTarget);
    this.#disableTarget(this.sampleDescriptionColumnTarget);
  }

  changeSampleNameInput(event) {
    const { value } = event.target;
    this.#checkFormInputs();

    // if (value) {
    //   if (this.hasMetadataColumnsTarget) {
    //     this.#addMetadataColumns();
    //   } else {
    //     this.submitButtonTarget.disabled = false;
    //   }
    // } else {
    //   if (this.hasMetadataColumnsTarget) {
    //     this.#removeMetadataColumns();
    //   } else {
    //     this.submitButtonTarget.disabled = true;
    //   }
    // }
  }

  changeProjectPUIDInput(event) {
    const { value } = event.target;
    this.#checkFormInputs();
  }

  changeSampleDescriptionInput(event) {
    const { value } = event.target;
    this.#checkFormInputs();
  }

  readFile(event) {
    const { files } = event.target;

    this.#removeSampleNameInputOptions();
    this.#removeProjectPUIDInputOptions();
    this.#removeSampleDescriptionInputOptions();
    // this.#removeMetadataColumns();
    this.submitButtonTarget.disabled = true;

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
      this.#addSampleNameInputOptions();
      this.#addProjectPUIDInputOptions();
      this.#addSampleDescriptionInputOptions();
    };
  }

  #removeSampleNameInputOptions() {
    this.#removeInputOptions(this.sampleNameColumnTarget);
    this.#disableTarget(this.sampleNameColumnTarget);
  }

  #addSampleNameInputOptions() {
    for (let header of this.#headers) {
      const option = document.createElement("option");
      option.value = header;
      option.text = header;
      this.sampleNameColumnTarget.append(option);
    }
    this.#enableTarget(this.sampleNameColumnTarget);
  }

  #removeProjectPUIDInputOptions() {
    this.#removeInputOptions(this.projectPUIDColumnTarget);
    this.#disableTarget(this.projectPUIDColumnTarget);
  }

  #addProjectPUIDInputOptions() {
    for (let header of this.#headers) {
      const option = document.createElement("option");
      option.value = header;
      option.text = header;
      this.projectPUIDColumnTarget.append(option);
    }
    this.#enableTarget(this.projectPUIDColumnTarget);
  }

  #removeSampleDescriptionInputOptions() {
    this.#removeInputOptions(this.sampleDescriptionColumnTarget);
    this.#disableTarget(this.sampleDescriptionColumnTarget);
  }

  #addSampleDescriptionInputOptions() {
    for (let header of this.#headers) {
      const option = document.createElement("option");
      option.value = header;
      option.text = header;
      this.sampleDescriptionColumnTarget.append(option);
    }
    this.#enableTarget(this.sampleDescriptionColumnTarget);
  }

  // #removeMetadataColumns() {
  //   if (this.hasMetadataColumnsTarget) {
  //     this.metadataColumnsTarget.innerHTML = "";
  //   }
  // }

  // #addMetadataColumns() {
  //   const ignoreList = [
  //     "sample name",
  //     "project id",
  //     "description",
  //     "created_at",
  //     "updated_at",
  //     "last_updated_at",
  //   ];

  //   let columns = this.#headers.filter(
  //     (header) =>
  //       !ignoreList.includes(header.toLowerCase()) &&
  //       header.toLowerCase() != this.sampleNameColumnTarget.value.toLowerCase(),
  //   );

  //   this.metadataColumnsTarget.innerHTML =
  //     this.sortableListsTemplateTarget.innerHTML;

  //   columns.forEach((column) => {
  //     const template =
  //       this.sortableListsItemTemplateTarget.content.cloneNode(true);
  //     template.querySelector("li").innerText = column;
  //     template.querySelector("li").id = column.replace(/\s+/g, "-");
  //     this.metadataColumnsTarget.querySelector("#selected").append(template);
  //   });
  //   this.submitButtonTarget.disabled = !columns.length;
  // }

  #checkFormInputs() {
    if (this.hasSampleNameColumnTarget && this.hasProjectPUIDColumnTarget){
      this.submitButtonTarget.disabled = false;
    } else {
      this.submitButtonTarget.disabled = true;
    }
  }

  #removeInputOptions(target) {
    while (target.options.length > 1) {
      target.remove(target.options.length - 1);
    }
  }

  #disableTarget(target) {
    target.disabled = true;
    target.classList.add(...this.#disabled_classes);
  }

  #enableTarget(target) {
    target.disabled = false;
    target.classList.remove(...this.#disabled_classes);
  }
}
