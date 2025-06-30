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
    "checkmarkTemplate",
    "hiddenCheckmarkTemplate",
  ];

  static values = {
    selectedList: String,
    availableList: String,
    fieldName: String,
  };

  #originalAvailableList;

  #lastClickedOption;
  #shiftSelectionOption;

  connect() {
    // Get a handle on the available and selected lists
    this.availableList = document.getElementById(this.availableListValue);
    this.selectedList = document.getElementById(this.selectedListValue);

    this.selectedList.addEventListener("drop", this.buttonStateListener);
    this.availableList.addEventListener("drop", this.buttonStateListener);

    this.buttonStateListener = this.#checkStates.bind(this);
    this.boundEndShiftSelect = this.#endShiftSelect.bind(this);

    // this.availableList.addEventListener("keyup", this.boundTest);
    this.#setInitialTabIndex();
    this.idempotentConnect();
  }

  idempotentConnect() {
    if (this.availableList && this.selectedList) {
      // Get a handle on the original available list
      this.#originalAvailableList = [
        ...this.availableList.querySelectorAll("li"),
        ...this.selectedList.querySelectorAll("li"),
      ];
      Object.freeze(this.#originalAvailableList);

      this.#checkStates();
    }
  }

  #setInitialTabIndex() {
    const availableListFirstOption = this.availableList.firstElementChild;
    const selectedListFirstOption = this.selectedList.firstElementChild;
    if (availableListFirstOption) {
      availableListFirstOption.tabIndex = 0;
      availableListFirstOption.setAttribute("data-tabbable", "true");
    }
    if (selectedListFirstOption) {
      selectedListFirstOption.tabIndex = 0;
      selectedListFirstOption.setAttribute("data-tabbable", "true");
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
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = !(
        !disableState && this.selectedList.querySelectorAll("li").length > 0
      );
    }
  }

  #setAddOrRemoveButtonDisableState(button, disableState) {
    if (disableState && !button.disabled) {
      button.disabled = true;
      button.setAttribute("aria-disabled", "true");
    } else if (!disableState && button.disabled) {
      button.disabled = false;
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
    this.selectedList.removeEventListener("drop", this.buttonStateListener);
    this.availableList.removeEventListener("drop", this.buttonStateListener);
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
          this.#createListItem(element, this.selectedList);
        }
      });
      this.availableList.append(...items);

      this.#checkButtonStates();
    } catch (error) {
      console.error("Error setting template:", error);
    }
  }

  navigateList(event) {
    const handler = this.#getKeyboardHandler(event.key);
    if (handler) {
      if (event.key !== "Tab") event.preventDefault();
      handler.call(this, event);
      this.#checkStates();
    }
  }

  #getKeyboardHandler(key) {
    const handlers = {
      " ": this.handleSelection.bind(this),
      Enter: this.addSelection.bind(this),
      Delete: this.removeSelection.bind(this),
      ArrowUp: (event) => this.#handleVerticalNavigation(event, "up", "single"),
      ArrowDown: (event) =>
        this.#handleVerticalNavigation(event, "down", "single"),
      Home: (event) => this.#handleVerticalNavigation(event, "up", "fullList"),
      End: (event) => this.#handleVerticalNavigation(event, "down", "fullList"),
      a: (event) => this.#selectAll(event),
    };
    return handlers[key];
  }

  handleSelection(event) {
    const option = event.target;

    this.#selectOrUnselectOption(option);
    this.#setTabIndexes(option);
  }

  handleClick(event) {
    const option = event.target;
    if (event.shiftKey) {
      this.#handleShiftClick(option);
    } else {
      this.#lastClickedOption = option;
      this.#selectOrUnselectOption(option);
    }
    this.#setTabIndexes(option);
  }

  #handleShiftClick(option) {
    const listOptions = Array.from(option.parentNode.querySelectorAll("li"));
    if (
      this.#lastClickedOption &&
      this.#lastClickedOption.parentNode === option.parentNode
    ) {
      const lastClickedIndex = listOptions.indexOf(this.#lastClickedOption);
      const currentClickedIndex = listOptions.indexOf(option);

      this.#unselectListOptions(option.parentNode);
      this.#selectOptionRange(
        currentClickedIndex,
        lastClickedIndex,
        listOptions,
      );
    } else {
      for (let i = 0; i < listOptions.length; i++) {
        this.#addSelectedAttributes(listOptions[i]);

        if (listOptions[i] === option) {
          break;
        }
      }
      this.#lastClickedOption = listOptions[0];
    }
  }

  #selectOrUnselectOption(option) {
    if (option.querySelector(`#${option.innerText}_unselected`)) {
      this.#addSelectedAttributes(option);
    } else {
      this.#removeSelectedAttributes(option);
    }
  }

  addSelection(event) {
    if (
      event.type == "keydown" &&
      event.target.parentNode != this.availableList
    )
      return;
    const selectedOptions = this.availableList.querySelectorAll(
      'li[aria-selected="true"]',
    );
    if (selectedOptions.length > 0) {
      for (let i = 0; i < selectedOptions.length; i++) {
        this.#removeSelectedAttributes(selectedOptions[i]);
        this.selectedList.appendChild(selectedOptions[i]);
      }
      selectedOptions[0].focus();
      this.#setTabIndexes(selectedOptions[0]);
    }
  }

  removeSelection(event) {
    if (event.type == "keydown" && event.target.parentNode != this.selectedList)
      return;
    const selectedOptions = this.selectedList.querySelectorAll(
      'li[aria-selected="true"]',
    );

    if (selectedOptions.length > 0) {
      for (let i = 0; i < selectedOptions.length; i++) {
        this.#removeSelectedAttributes(selectedOptions[i]);
        this.availableList.appendChild(selectedOptions[i]);
      }
      selectedOptions[0].focus();
      this.#setTabIndexes(selectedOptions[0]);
    }
  }

  #selectOptionRange(indexOne, indexTwo, listOptions) {
    const lowerIndex = indexOne > indexTwo ? indexTwo : indexOne;
    const higherIndex = indexOne < indexTwo ? indexTwo : indexOne;

    for (let i = lowerIndex; i <= higherIndex; i++) {
      this.#addSelectedAttributes(listOptions[i]);
    }
  }

  #handleVerticalNavigation(event, direction, navigateSize) {
    const selectedOptionNodeList = event.target.parentNode.querySelectorAll(
      'li[aria-selected="true"]',
    );

    // if 1 selected option exists and is in Selected list, move the option with up/down keyboard navigation,
    // else move focus up and down list without moving any options
    let selectedOption;
    if (
      selectedOptionNodeList.length === 1 &&
      event.type === "keydown" &&
      (event.key === "ArrowUp" || event.key === "ArrowDown") &&
      event.altKey &&
      event.target.getAttribute("aria-selected") === "true" &&
      event.target.parentNode === this.selectedList
    ) {
      selectedOption = selectedOptionNodeList[0];
    } else {
      selectedOption = null;
    }

    // navigate up/down one option (ArrowUp/Down) or to the top/bottom of list (Home/End)
    const targetOption =
      navigateSize === "single"
        ? direction === "up"
          ? event.target.previousElementSibling
          : event.target.nextElementSibling
        : direction === "up"
          ? event.target.parentNode.firstElementChild
          : event.target.parentNode.lastElementChild;
    this.#navigateListUpAndDown(
      direction === "up" ? "up" : "down",
      targetOption,
      selectedOption,
      event,
    );
  }

  #navigateListUpAndDown(direction, targetOption, selectedOption, event) {
    // return if no target option (eg: keyboard ArrowUp when already on the top option)
    if (!targetOption) return;
    if (selectedOption) {
      selectedOption.remove();
      targetOption.insertAdjacentElement(
        direction === "up" ? "beforebegin" : "afterend",
        selectedOption,
      );
      selectedOption.focus();
    } else {
      if (event.shiftKey) {
        const list = event.target.parentNode;
        this.#unselectListOptions(list);
        if (!list.hasAttribute("shift-select")) {
          this.#shiftSelectionOption = event.target;
          this.#setListForShiftKeyboardSelection(list);
        }
        const listOptions = Array.from(list.querySelectorAll("li"));
        let navigatedSelectionIndex = listOptions.indexOf(event.target);
        direction === "up"
          ? navigatedSelectionIndex--
          : navigatedSelectionIndex++;

        const startingSelectionIndex = listOptions.indexOf(
          this.#shiftSelectionOption,
        );
        this.#selectOptionRange(
          startingSelectionIndex,
          navigatedSelectionIndex,
          listOptions,
        );
      }
      targetOption.focus();
    }
  }

  #setListForShiftKeyboardSelection(list) {
    list.setAttribute("shift-select", "enabled");
    list.addEventListener("keyup", this.boundEndShiftSelect);
  }

  #endShiftSelect(event) {
    // .addEventListener("blur", this.boundTest);
    if (event.key == "Shift") {
      const list = event.target.parentNode;
      list.removeAttribute("shift-select");
      list.removeEventListener("keyup", this.boundEndShiftSelect);
    }
  }

  #selectAll(event) {
    event.preventDefault();
    if (!event.ctrlKey) return;
    const listNode = event.target.parentNode;
    const allOptions = listNode.querySelectorAll("li");
    const unselectedOptions = listNode.querySelectorAll(
      'li[aria-selected="false"]',
    );
    // if everything is selected, unselect
    // else select all
    if (unselectedOptions.length == 0) {
      this.#unselectListOptions(listNode);
    } else {
      for (let i = 0; i < allOptions.length; i++) {
        if (allOptions[i].getAttribute("aria-selected") === "false") {
          this.#addSelectedAttributes(allOptions[i]);
        }
      }
    }
  }

  #unselectListOptions(list) {
    const listOptions = list.querySelectorAll("li");
    for (let i = 0; i < listOptions.length; i++) {
      if (listOptions[i].getAttribute("aria-selected") === "true") {
        this.#removeSelectedAttributes(listOptions[i]);
      }
    }
  }

  // add checkmark to option
  #addSelectedAttributes(option) {
    const checkmark = this.checkmarkTemplateTarget.content.cloneNode(true);
    checkmark.querySelector("span").id = `${option.innerText}_selected`;
    option
      .querySelector(`#${option.innerText}_unselected`)
      .replaceWith(checkmark);
    option.setAttribute("aria-selected", "true");
  }

  // remove checkmark from option
  #removeSelectedAttributes(option) {
    const hiddenCheckmark =
      this.hiddenCheckmarkTemplateTarget.content.cloneNode(true);
    hiddenCheckmark.querySelector("span").id = `${option.innerText}_unselected`;

    option
      .querySelector(`#${option.innerText}_selected`)
      .replaceWith(hiddenCheckmark);

    option.setAttribute("aria-selected", "false");
  }

  // used for dynamic/changing listing values
  updateMetadataListing({ detail: { content } }) {
    let newMetadata = content["metadata"];
    let existingMetadata = { available: [], selected: [] };

    // check which values already exist in lists; prevents moving metadata between lists that have already been moved
    // by user
    this.availableList.querySelectorAll("li").forEach((availableMetadata) => {
      if (newMetadata.includes(availableMetadata.innerText)) {
        existingMetadata["available"].push(availableMetadata.innerText);
        newMetadata.splice(newMetadata.indexOf(availableMetadata.innerText), 1);
      }
    });

    this.selectedList.querySelectorAll("li").forEach((selectedMetadata) => {
      if (newMetadata.includes(selectedMetadata.innerText)) {
        existingMetadata["selected"].push(selectedMetadata.innerText);
        newMetadata.splice(newMetadata.indexOf(selectedMetadata.innerText), 1);
      }
    });

    // reset lists
    this.availableList.innerHTML = "";
    this.selectedList.innerHTML = "";

    // add new metadata to the selected list
    let selectedMetadata = existingMetadata["selected"].concat(newMetadata);

    // repopulate lists with existing and new metadata
    existingMetadata["available"].forEach((metadata) => {
      this.#createListItem(metadata, this.availableList);
    });

    selectedMetadata.forEach((metadata) => {
      this.#createListItem(metadata, this.selectedList);
    });

    this.idempotentConnect();
  }

  #createListItem(element, list) {
    let template = this.itemTemplateTarget.content.cloneNode(true);
    template.querySelector("li").innerText = element;
    template.querySelector("li").id = element.replace(/\s+/g, "-");
    list.append(template);
  }

  #setTabIndexes(currentOption) {
    const oldTabbableOptions = currentOption.parentNode.querySelectorAll(
      '[data-tabbable="true"]',
    );

    if (oldTabbableOptions) {
      for (let i = 0; i < oldTabbableOptions.length; i++) {
        oldTabbableOptions[i].tabIndex = "-1";
        oldTabbableOptions[i].removeAttribute("data-tabbable");
      }
    }

    if (currentOption.parentNode === this.selectedList) {
      this.#verifyListHasTabIndex(this.availableList);
    } else {
      this.#verifyListHasTabIndex(this.selectedList);
    }
    currentOption.setAttribute("data-tabbable", "true");
    currentOption.tabIndex = "0";
  }

  #verifyListHasTabIndex(list) {
    if (
      list.firstElementChild &&
      !list.querySelector('[data-tabbable="true"]')
    ) {
      list.firstElementChild.tabIndex = "0";
      list.firstElementChild.setAttribute("data-tabbable", "true");
    }
  }
}
