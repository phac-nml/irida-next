import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {

  static targets = ["field", "submitBtn", "addAll", "removeAll"];

  static values = {
    selectedList: String,
    availableList: String,
    fieldName: String,
    selectAllEnabled: Boolean
  };

  #disabledClasses = ["pointer-events-none", "cursor-not-allowed", "text-slate-300", "dark:text-slate-700"];
  #enabledClasses = ["underline", "hover:no-underline"]

  connect() {
    this.availableList = document.getElementById(this.availableListValue)
    this.selectedList = document.getElementById(this.selectedListValue)
    this.fullListItems = this.#constructFullListItems(this.availableList, this.selectedList)
    this.#setInitialSelectAllState(this.availableList, this.addAllTarget)
    this.#setInitialSelectAllState(this.selectedList, this.removeAllTarget)
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

  #constructFullListItems(listOne, listTwo) {
    const listOneItems = Array.prototype.slice.call(listOne.querySelectorAll('li'))
    const listTwoItems = Array.prototype.slice.call(listTwo.querySelectorAll('li'))
    return listOneItems.concat(listTwoItems)
  }

  #setInitialSelectAllState(list, button) {
    const list_values = list.querySelectorAll("li")
    if (list_values.length == 0) {
      button.classList.add(...this.#disabledClasses)
      button.setAttribute("aria-disabled", "true")
    } else {
      button.classList.add(...this.#enabledClasses)
    }
  }

  #checkButtonStates() {
    const selected_values = this.selectedList.querySelectorAll("li")
    const available_values = this.availableList.querySelectorAll("li")
    if (selected_values.length == 0) {
      this.#setSubmitButtonDisableState(true)
      if (this.selectAllEnabledValue) {
        this.#setAddOrRemoveButtonDisableState(this.removeAllTarget, true)
        this.#setAddOrRemoveButtonDisableState(this.addAllTarget, false)
      }
    } else if (available_values.length == 0) {
      this.#setSubmitButtonDisableState(false)
      if (this.selectAllEnabledValue) {
        this.#setAddOrRemoveButtonDisableState(this.removeAllTarget, false)
        this.#setAddOrRemoveButtonDisableState(this.addAllTarget, true)
      }
    } else {
      this.#setSubmitButtonDisableState(false)
      if (this.selectAllEnabledValue) {
        this.#setAddOrRemoveButtonDisableState(this.removeAllTarget, false)
        this.#setAddOrRemoveButtonDisableState(this.addAllTarget, false)
      }
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

  constructParams() {
    const list_values = this.selectedList.querySelectorAll("li")

    for (const list_value of list_values) {
      this.fieldTarget.appendChild(
        createHiddenInput(
          this.fieldNameValue,
          list_value.innerText
        )
      );
    }
  }
}
