import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
  static targets = ["field", "submitBtn", "addAll", "removeAll", "templateSelector"];

  static values = {
    selectedList: String,
    availableList: String,
    fieldName: String,
  };

  #disabledClasses = [
    "pointer-events-none",
    "cursor-not-allowed",
    "text-slate-300",
    "dark:text-slate-700",
  ];
  #enabledClasses = ["underline", "hover:no-underline"];

  connect() {
    this.availableList = document.getElementById(this.availableListValue);
    this.selectedList = document.getElementById(this.selectedListValue);
    this.allListItems = this.#constructAllListItems(
      this.availableList,
      this.selectedList,
    );
    this.#setInitialSelectAllState(this.availableList, this.addAllTarget);
    this.#setInitialSelectAllState(this.selectedList, this.removeAllTarget);

    this.buttonStateListener = this.#checkStates.bind(this);
    this.selectedList.addEventListener("drop", this.buttonStateListener);
    this.availableList.addEventListener("drop", this.buttonStateListener);
  }

  addAll(event) {
    event.preventDefault();

    for (const item of this.allListItems) {
      this.selectedList.append(item);
    }
    this.templateSelectorTarget.value = "none";
    this.#checkButtonStates();
  }

  removeAll(event) {
    event.preventDefault();

    for (const item of this.allListItems) {
      this.availableList.append(item);
    }
    this.templateSelectorTarget.value = "none";
    this.#checkButtonStates();
  }

  #constructAllListItems(listOne, listTwo) {
    const listOneItems = Array.prototype.slice.call(
      listOne.querySelectorAll("li"),
    );
    const listTwoItems = Array.prototype.slice.call(
      listTwo.querySelectorAll("li"),
    );
    return listOneItems.concat(listTwoItems);
  }

  #setInitialSelectAllState(list, button) {
    const list_values = list.querySelectorAll("li");
    if (list_values.length === 0) {
      button.classList.add(...this.#disabledClasses);
      button.setAttribute("aria-disabled", "true");
    } else {
      button.classList.add(...this.#enabledClasses);
    }
  }

  #checkStates() {
    this.#checkButtonStates();
    this.#checkTemplateSelectorState();
  }

  #checkButtonStates() {
    const selected_values = this.selectedList.querySelectorAll("li");
    const available_values = this.availableList.querySelectorAll("li");
    if (selected_values.length === 0) {
      this.#setSubmitButtonDisableState(true);
      this.#setAddOrRemoveButtonDisableState(this.removeAllTarget, true);
      this.#setAddOrRemoveButtonDisableState(this.addAllTarget, false);
    } else if (available_values.length === 0) {
      this.#setSubmitButtonDisableState(false);
      this.#setAddOrRemoveButtonDisableState(this.removeAllTarget, false);
      this.#setAddOrRemoveButtonDisableState(this.addAllTarget, true);
    } else {
      this.#setSubmitButtonDisableState(false);
      this.#setAddOrRemoveButtonDisableState(this.removeAllTarget, false);
      this.#setAddOrRemoveButtonDisableState(this.addAllTarget, false);
    }
  }

  #checkTemplateSelectorState() {
    const selected_values = this.selectedList.querySelectorAll("li");
    if (selected_values.length === 0) {
      this.templateSelectorTarget.value = "none";
    } else {
      const selectedListValues = JSON.stringify(
        Array.from(selected_values).map((li) => li.innerText),
      );

      let template = "none";
      for (const option of this.templateSelectorTarget.options) {
        const templateFields = option.dataset.fields;
        if (templateFields === selectedListValues) {
          template = option.value;
          break;
        }
      }
      this.templateSelectorTarget.value = template;
    }
  }

  #setSubmitButtonDisableState(disableState) {
    this.submitBtnTarget.disabled = !(
      !disableState && this.selectedList.querySelectorAll("li").length > 0
    );
  }

  #setAddOrRemoveButtonDisableState(button, disableState) {
    if (disableState && !button.classList.contains("pointer-events-none")) {
      button.classList.remove(...this.#enabledClasses);
      button.classList.add(...this.#disabledClasses);
      button.setAttribute("aria-disabled", "true");
    } else if (
      !disableState &&
      button.classList.contains("pointer-events-none")
    ) {
      button.classList.remove(...this.#disabledClasses);
      button.classList.add(...this.#enabledClasses);
      button.removeAttribute("aria-disabled");
    }
  }

  constructParams() {
    this.fieldTarget.innerHTML = null;
    const list_values = this.selectedList.querySelectorAll("li");

    for (const list_value of list_values) {
      this.fieldTarget.appendChild(
        createHiddenInput(this.fieldNameValue, list_value.innerText),
      );
    }
  }

  disconnect() {
    this.selectedList.removeEventListener(
      "mouseover",
      this.buttonStateListener,
    );
    this.availableList.removeEventListener(
      "mouseover",
      this.buttonStateListener,
    );
  }

  /**
   * Handles template selection and updates the available/selected lists accordingly
   * @param {Event} event - The template selection change event
   */
  setTemplate(event) {
    try {
      const target = event.target;

      // Validate target exists
      if (!target) {
        console.error("Template selection target not found");
        return;
      }

      const templateId = target.value;
      const selectedOption = target.options[target.selectedIndex];

      // Validate selected option exists
      if (!selectedOption) {
        console.error("No template option selected");
        return;
      }

      const fields = selectedOption.dataset.fields || "";

      // Get all list items from both lists
      const allItems = this.#constructAllListItems(
        this.availableList,
        this.selectedList,
      );

      // Handle "none" template selection by removing all items
      if (templateId === "none") {
        this.removeAll(event);
        return;
      }

      // Sort items into selected/available lists based on template fields
      allItems.forEach((item) => {
        if (!item || !item.innerText) {
          console.warn("Invalid list item encountered");
          return;
        }

        if (fields.includes(item.innerText)) {
          this.selectedList.append(item);
        } else {
          this.availableList.append(item);
        }
      });

      this.#checkButtonStates();
    } catch (error) {
      console.error("Error setting template:", error);
    }
  }
}
