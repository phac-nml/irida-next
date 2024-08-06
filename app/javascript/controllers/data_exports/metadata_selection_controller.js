import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {

  static targets = ["field", "submitBtn", "addAll", "removeAll"];

  static values = {
    selectedList: {
      type: String,
    },
    availableList: {
      type: String,
    }
  };

  #disabledClasses = ["pointer-events-none", "cursor-not-allowed", "text-slate-300", "dark:text-slate-700"];
  #enabledClasses = ["underline", "hover:no-underline"]

  connect() {
    this.availableList = document.getElementById(this.availableListValue)
    this.selectedList = document.getElementById(this.selectedListValue)
    this.fullListItems = this.availableList.querySelectorAll("li")
    this.selectedList.addEventListener("mouseover", () => { this.#checkButtonStates() })
    this.availableList.addEventListener("mouseover", () => { this.#checkButtonStates() })
  }

  addAll() {
    for (const item of this.fullListItems) {
      this.selectedList.append(item)
    }
    this.#checkButtonStates()
  }

  removeAll() {
    for (const item of this.fullListItems) {
      this.availableList.append(item)
    }
    this.#checkButtonStates()
  }

  #checkButtonStates() {
    const selected_metadata = this.selectedList.querySelectorAll("li")
    const available_metadata = this.availableList.querySelectorAll("li")
    if (selected_metadata.length == 0) {
      this.#setSubmitButtonDisableState(true)
      this.#setAddOrRemoveButtonDisableState(this.removeAllTarget, true)
      this.#setAddOrRemoveButtonDisableState(this.addAllTarget, false)
    } else if (available_metadata.length == 0) {
      this.#setSubmitButtonDisableState(false)
      this.#setAddOrRemoveButtonDisableState(this.removeAllTarget, false)
      this.#setAddOrRemoveButtonDisableState(this.addAllTarget, true)
    } else {
      this.#setSubmitButtonDisableState(false)
      this.#setAddOrRemoveButtonDisableState(this.removeAllTarget, false)
      this.#setAddOrRemoveButtonDisableState(this.addAllTarget, false)
    }
  }

  #setSubmitButtonDisableState(disableState) {
    this.submitBtnTarget.disabled = !(!disableState && this.selectedList.querySelectorAll("li").length > 0);
  }

  #setAddOrRemoveButtonDisableState(button, disableState) {
    if (disableState && !button.classList.contains("pointer-events-none")) {
      button.classList.remove(...this.#enabledClasses)
      button.classList.add(...this.#disabledClasses)
      button.setAttribute("aria-disabled", "true")
    } else if (!disableState && button.classList.contains("pointer-events-none")) {
      button.classList.remove(...this.#disabledClasses)
      button.classList.add(...this.#enabledClasses)
      button.removeAttribute("aria-disabled")
    }
  }

  constructMetadataParams() {
    const metadata_fields = this.selectedList.querySelectorAll("li")

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
