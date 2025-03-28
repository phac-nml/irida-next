import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
  static targets = [
    "field",
    "submitBtn",
    "addAll",
    "removeAll",
    "templateSelector",
    "itemTemplate",
  ];

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
  #originalAvailableList;

  connect() {
    this.idempotentConnect();
  }

  idempotentConnect() {
    // Get a handle on the available and selected lists
    this.availableList = document.getElementById(this.availableListValue);
    this.selectedList = document.getElementById(this.selectedListValue);

    if (this.availableList && this.selectedList) {
      // Get a handle on the original available list
      this.#originalAvailableList = [
        ...this.availableList.querySelectorAll("li"),
        ...this.selectedList.querySelectorAll("li"),
      ];
      Object.freeze(this.#originalAvailableList);

      this.#setInitialSelectAllState(this.availableList, this.addAllTarget);
      this.#setInitialSelectAllState(this.selectedList, this.removeAllTarget);

      this.buttonStateListener = this.#checkStates.bind(this);
      this.selectedList.addEventListener("drop", this.buttonStateListener);
      this.availableList.addEventListener("drop", this.buttonStateListener);
    }
  }

  addAll(event) {
    event.preventDefault();
    this.availableList.innerHTML = "";
    this.selectedList.append(...this.#originalAvailableList);
    this.#checkStates();
  }

  removeAll(event) {
    event.preventDefault();
    this.availableList.append(...this.#originalAvailableList);
    this.selectedList.innerHTML = "";
    this.#checkStates();
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

    if (this.hasTemplateSelectorTarget) {
      this.#checkTemplateSelectorState();
      this.#cleanupAvailableList();
    }
  }

  #cleanupAvailableList() {
    const itemsToRemove = Array.from(
      this.availableList.querySelectorAll("li"),
    ).filter((li) => !this.#originalAvailableList.includes(li));

    itemsToRemove.forEach((li) => li.remove());
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
        if (typeof option.dataset.fields !== "undefined") {
          const templateFields = JSON.stringify(
            JSON.parse(option.dataset.fields),
          );
          if (templateFields === selectedListValues) {
            template = option.value;
            break;
          }
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

      // Reset the lists to their initial state
      // Move all items to available list in one operation for better performance
      this.availableList.innerHTML = "";
      this.selectedList.innerHTML = "";
      this.availableList.append(...this.#originalAvailableList);

      // Handle "none" template selection by removing all items
      if (templateId === "none") {
        return;
      }

      // Sort items into selected/available lists based on template fields
      // but maintain the order of the items in the template fields
      const fields = JSON.parse(selectedOption.dataset.fields);
      const items = Array.from(this.availableList.querySelectorAll("li"));
      const textFields = Array.from(items).map((item) => item.innerText);

      fields.forEach((element) => {
        const index = textFields.indexOf(element);
        if (index !== -1) {
          this.selectedList.append(items[index]);
          items.splice(index, 1);
          textFields.splice(index, 1);
        } else {
          const template = this.itemTemplateTarget.content.cloneNode(true);
          template.querySelector("li").innerText = element;
          template.querySelector("li").id = element.replace(/\s+/g, "-");
          this.selectedList.append(template);
        }
      });
      this.availableList.append(...items);

      this.#checkButtonStates();
    } catch (error) {
      console.error("Error setting template:", error);
    }
  }
}
