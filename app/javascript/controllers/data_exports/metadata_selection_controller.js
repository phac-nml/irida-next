import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {

  static targets = ["field"];

  static values = {
    selectedList: {
      type: String,
    },
    availableList: {
      type: String,
    }
  };

  connect() {
    this.availableList = document.getElementById(this.availableListValue)
    this.selectedList = document.getElementById(this.selectedListValue)
    this.fullListItems = this.availableList.querySelectorAll("li")
  }

  addAll() {
    for (let item of this.fullListItems) {
      this.selectedList.append(item)
    }
  }

  removeAll() {
    for (let item of this.fullListItems) {
      this.availableList.append(item)
    }
  }

  constructMetadataParams() {
    const metadata_fields = document.getElementById(this.selectedListValue).querySelectorAll("li")

    for (let metadata_field of metadata_fields) {
      this.fieldTarget.appendChild(
        createHiddenInput(
          `data_export[export_parameters][metadata_fields][]`,
          metadata_field.innerText
        )
      );
    }
  }
}
