import { Controller } from "@hotwired/stimulus";
import * as XLSX from "xlsx";

export default class extends Controller {
  static targets = [
    "sampleNameColumn",
    // "projectPUIDColumn",
    "sampleDescriptionColumn",
    "sortableListsTemplate",
    "sortableListsItemTemplate",
    "submitButton",
  ];

  #header_map = {};

  #headers = [];

  #curr_sample_name = null;
  #curr_sample_description = null;

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
    // this.#disableTarget(this.projectPUIDColumnTarget);
    this.#disableTarget(this.sampleDescriptionColumnTarget);
  }

  changeSampleNameInput(event) {
    this.#header_map[this.#curr_sample_name] = false;
    const { value } = event.target;
    this.#curr_sample_name = value.toLowerCase();
    this.#header_map[this.#curr_sample_name] = true;
    this.#refreshInputOptionsForAllFields();
    this.#checkFormInputsReadyForSubmit();
  }

  changeSampleDescriptionInput(event) {
    this.#header_map[this.#curr_sample_description] = false;
    const { value } = event.target;
    this.#curr_sample_description = value.toLowerCase();
    this.#header_map[this.#curr_sample_description] = true;
    this.#refreshInputOptionsForAllFields();
    this.#checkFormInputsReadyForSubmit();
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
      this.#headers = XLSX.utils.sheet_to_json(worksheet, { header: 1 })[0];
      this.#buildHeaderMap();
      this.#initSelection();
      this.#refreshInputOptionsForAllFields()
    };
  }

  #clearFormOptions() {
    this.#removeSampleNameInputOptions();
    // this.#removeProjectPUIDInputOptions();
    this.#removeSampleDescriptionInputOptions();
    // this.#removeMetadataColumns();
    this.submitButtonTarget.disabled = true;
  }


  #buildHeaderMap() {
    this.#header_map = {}
    this.#headers.forEach(h => {
      this.#header_map[h.toLowerCase()] = false;
    })
  }

  #initSelection() {
    this.#curr_sample_name = null;
    this.#curr_sample_description = null;
  }

  #removeSampleNameInputOptions() {
    this.#removeInputOptions(this.sampleNameColumnTarget);
    this.#disableTarget(this.sampleNameColumnTarget);
  }

  #refreshInputOptionsForAllFields() {
    this.#refreshInputOptions(this.sampleNameColumnTarget, this.#curr_sample_name)
    this.#refreshInputOptions(this.sampleDescriptionColumnTarget, this.#curr_sample_description)
  }

  #refreshInputOptions(columnTarget, current_selection) {
    let headers = this.#headers.filter( (header) =>
      // !(this.#header_map[header.toLowerCase()])
      (header.toLowerCase() != current_selection) &&  !(this.#header_map[header.toLowerCase()])
    );

    this.#removeInputOptions(columnTarget, current_selection);

    for (let header of headers) {
      const option = document.createElement("option");
      option.value = header;
      option.text = header;
      columnTarget.append(option);
    }
    this.#enableTarget(columnTarget);
  }

  #removeSampleDescriptionInputOptions() {
    this.#removeInputOptions(this.sampleDescriptionColumnTarget);
    this.#disableTarget(this.sampleDescriptionColumnTarget);
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

  #checkFormInputsReadyForSubmit() {
    if (this.hasSampleNameColumnTarget ){//&& this.hasProjectPUIDColumnTarget){
      this.submitButtonTarget.disabled = false;
    } else {
      this.submitButtonTarget.disabled = true;
    }
  }

  #removeInputOptions(target, current = null) {
    // When a current selection is passed it, it does not get removed.
    var post_length = 1
    if (current == null){
      post_length = 0
    }

    var rev_index = target.options.length - 1;
    while (target.options.length > post_length + 1){
      if(current != target.options[rev_index].value){
        target.remove(rev_index);
      }
      rev_index = rev_index - 1;
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
