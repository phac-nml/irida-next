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

  static values = {
    group: Boolean
  }

  #header_map = {};

  #headers = [];

  #curr_sample_name = null;
  #curr_project_puid = null;
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
    if (this.groupValue) {
      this.#disableTarget(this.projectPUIDColumnTarget);
    }
    this.#disableTarget(this.sampleDescriptionColumnTarget);
  }

  changeSampleNameInput(event) {
    this.#header_map[this.#curr_sample_name] = false;
    const { value } = event.target;
    this.#curr_sample_name = value;
    this.#header_map[this.#curr_sample_name] = true;
    this.#refreshInputOptionsForAllFields();
    this.#checkFormInputsReadyForSubmit();
  }

  changeProjectPUIDInput(event) {
    this.#header_map[this.#curr_project_puid] = false;
    const { value } = event.target;
    this.#curr_project_puid = value;
    this.#header_map[this.#curr_project_puid] = true;
    this.#refreshInputOptionsForAllFields();
    this.#checkFormInputsReadyForSubmit();
  }

  changeSampleDescriptionInput(event) {
    this.#header_map[this.#curr_sample_description] = false;
    const { value } = event.target;
    this.#curr_sample_description = value;
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
    this.#removeInputOptions(this.sampleNameColumnTarget);
    this.#disableTarget(this.sampleNameColumnTarget);
    if (this.groupValue) {
      this.#removeInputOptions(this.projectPUIDColumnTarget);
      this.#disableTarget(this.projectPUIDColumnTarget);
    }
    this.#removeInputOptions(this.sampleDescriptionColumnTarget);
    this.#disableTarget(this.sampleDescriptionColumnTarget);
    // this.#removeMetadataColumns();
    this.submitButtonTarget.disabled = true;
  }

  #buildHeaderMap() {
    this.#header_map = {}
    this.#headers.forEach(h => {
      this.#header_map[h] = false;
    })
  }

  #initSelection() {
    this.#curr_sample_name = null;
    this.#curr_project_puid = null;
    this.#curr_sample_description = null;
  }

  #refreshInputOptionsForAllFields() {
    this.#refreshInputOptions(this.sampleNameColumnTarget, this.#curr_sample_name)
    if (this.groupValue) {
      this.#refreshInputOptions(this.projectPUIDColumnTarget, this.#curr_project_puid)
    }
    this.#refreshInputOptions(this.sampleDescriptionColumnTarget, this.#curr_sample_description)
  }

  #refreshInputOptions(columnTarget, current_selection) {
    // filter out fields other headers are using, but not this target's own selection
    let headers = this.#headers.filter( (header) =>
      (header != current_selection) &&  !(this.#header_map[header])
    );

    // delete the old input options, except for one that is currently selected
    this.#removeInputOptions(columnTarget, current_selection);

    // build a list of new input options based on above filtering
    for (let header of headers) {
      const option = document.createElement("option");
      option.value = header;
      option.text = header;
      columnTarget.append(option);
    }
    this.#enableTarget(columnTarget);
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
    var puid_value = true
    if (this.groupValue) {
      puid_value = this.hasProjectPUIDColumnTarget;
    }

    if (this.hasSampleNameColumnTarget && puid_value ){
        this.submitButtonTarget.disabled = false;
    } else {
      this.submitButtonTarget.disabled = true;
    }
  }

  #removeInputOptions(target, current = null) {
    // When a current selection is passed in, it does not get removed.
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
