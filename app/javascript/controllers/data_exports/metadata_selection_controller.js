import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {

  static targets = ["field", "submitBtn"];

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
    this.selectedList.addEventListener("mouseover", () => { this.#checkSubmitState() })
  }

  addAll() {
    for (const item of this.fullListItems) {
      this.selectedList.append(item)
    }

    this.#setSubmitButtonDisableState(false)
  }

  removeAll() {
    for (const item of this.fullListItems) {
      this.availableList.append(item)
    }

    this.#setSubmitButtonDisableState(true)
  }

  #checkSubmitState() {
    const selected_metadata = this.selectedList.querySelectorAll("li")
    if (selected_metadata.length > 0) {
      this.#setSubmitButtonDisableState(false)
    } else {
      this.#setSubmitButtonDisableState(true)
    }
  }

  #setSubmitButtonDisableState(disableState) {
    if (!disableState && this.selectedList.querySelectorAll("li").length > 0) {
      this.submitBtnTarget.disabled = false
    } else {
      this.submitBtnTarget.disabled = true
    }
  }


  constructMetadataParams() {
    const metadata_fields = document.getElementById(this.selectedListValue).querySelectorAll("li")

    for (const metadata_field of metadata_fields) {
      this.fieldTarget.appendChild(
        createHiddenInput(
          `data_export[export_parameters][metadata_fields][]`,
          metadata_field.innerText
        )
      );
    }
  }
}
