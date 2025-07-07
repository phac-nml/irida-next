import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
  static targets = [
    "field",
    "submitBtn",
    "addButton",
    "removeButton",
    "upButton",
    "downButton",
    "templateSelector",
    "itemTemplate",
    "checkmarkTemplate",
    "hiddenCheckmarkTemplate",
    "ariaLiveUpdate",
  ];

  static values = {
    selectedList: String,
    availableList: String,
    fieldName: String,
    ariaLiveUpdateAdded: String,
    ariaLiveUpdateRemoved: String,
  };

  #originalAvailableList;

  #lastClickedOption;
  #shiftSelectionOption;

  connect() {
    this.buttonStateListener = this.#checkStates.bind(this);
    this.boundEndShiftSelect = this.#endShiftSelect.bind(this);
    // Get a handle on the available and selected lists
    this.idempotentConnect();
  }

  idempotentConnect() {
    this.availableList = document.getElementById(this.availableListValue);
    this.selectedList = document.getElementById(this.selectedListValue);
    if (this.availableList && this.selectedList) {
      this.selectedList.addEventListener("drop", this.buttonStateListener);
      this.availableList.addEventListener("drop", this.buttonStateListener);

      // Get a handle on the original available list
      this.#originalAvailableList = [
        ...this.availableList.querySelectorAll("li"),
        ...this.selectedList.querySelectorAll("li"),
      ];
      Object.freeze(this.#originalAvailableList);

      // sets the first element in each list to be tabbable (ie: tabIndex = 0)
      this.#setInitialTabIndex();
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
    const availableListSelectedOptions = this.#getSelectedOptions(
      this.availableList,
    );
    const selectedListSelectedOptions = this.#getSelectedOptions(
      this.selectedList,
    );

    // disable add button if no options selected in available list
    this.#setButtonDisableState(
      this.addButtonTarget,
      availableListSelectedOptions.length == 0,
    );

    // disable remove button if no options selected in selected list
    this.#setButtonDisableState(
      this.removeButtonTarget,
      selectedListSelectedOptions.length == 0,
    );

    // disable up/down buttons unless exactly 1 option selected in selected list
    this.#setButtonDisableState(
      this.upButtonTarget,
      selectedListSelectedOptions.length != 1,
    );

    this.#setButtonDisableState(
      this.downButtonTarget,
      selectedListSelectedOptions.length != 1,
    );

    // disable submit if no options in selected list
    this.#setSubmitButtonDisableState(
      this.selectedList.querySelectorAll("li").length === 0,
    );
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

  #setButtonDisableState(button, disableState) {
    if (disableState && !button.disabled) {
      button.disabled = true;
      button.setAttribute("aria-disabled", "true");
    } else if (!disableState && button.disabled) {
      button.disabled = false;
      button.removeAttribute("aria-disabled");
    }
  }

  #getSelectedOptions(list) {
    return list.querySelectorAll('li[aria-selected="true"]');
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

  handleKeyboardInput(event) {
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
    this.#updateListAttributes(option);
  }

  #selectOrUnselectOption(option) {
    if (
      option.querySelector(
        `span[id="${this.#validateId(option.innerText)}_unselected"`,
      )
    ) {
      this.#addSelectedAttributes(option);
    } else {
      this.#removeSelectedAttributes(option);
    }
  }

  #selectOptionRange(indexOne, indexTwo, listOptions) {
    const lowerIndex = indexOne > indexTwo ? indexTwo : indexOne;
    const higherIndex = indexOne < indexTwo ? indexTwo : indexOne;

    for (let i = lowerIndex; i <= higherIndex; i++) {
      this.#addSelectedAttributes(listOptions[i]);
    }
  }

  addSelection(event) {
    if (
      event.type == "keydown" &&
      event.target.parentNode != this.availableList
    )
      return;

    this.#performSelection(
      event.type === "keydown",
      this.availableList,
      this.selectedList,
    );
  }

  removeSelection(event) {
    if (event.type == "keydown" && event.target.parentNode != this.selectedList)
      return;
    this.#performSelection(
      event.type === "keydown",
      this.selectedList,
      this.availableList,
    );
  }

  #performSelection(keydown, sourceList, targetList) {
    let focusTarget = null;

    if (keydown) {
      focusTarget = this.#getFocusTargetAfterSelection(sourceList);
    }
    const selectedOptions = this.#getSelectedOptions(sourceList);

    let selectedOptionsText = [];
    if (selectedOptions.length > 0) {
      for (let i = 0; i < selectedOptions.length; i++) {
        selectedOptionsText.push(selectedOptions[i].innerText);
        this.#removeSelectedAttributes(selectedOptions[i]);
        targetList.appendChild(selectedOptions[i]);
      }
      if (focusTarget) focusTarget.focus();
      this.#updateListAttributes(selectedOptions[0]);
    }

    let ariaLiveUpdateString =
      sourceList === this.selectedList
        ? this.ariaLiveUpdateRemovedValue
        : this.ariaLiveUpdateAddedValue;

    this.#updateAriaLive(
      ariaLiveUpdateString.concat(selectedOptionsText.join(", ")),
    );

    this.#checkStates();
  }

  #getFocusTargetAfterSelection(list) {
    const currentFocusedElement = document.activeElement;

    // if current focus element is a selected element, find next unselected
    // else if current focus element not selected, just return as we will keep the current focus
    if (currentFocusedElement.getAttribute("aria-selected") === "true") {
      let nextUnselected = currentFocusedElement.nextElementSibling;

      // check list 'downwards' if there's an unselected option
      while (nextUnselected) {
        if (nextUnselected.getAttribute("aria-selected") === "false") {
          return nextUnselected;
        } else {
          nextUnselected = nextUnselected.nextElementSibling;
          if (!nextUnselected) break;
        }
      }

      // if after going downwards, no unselected options were found, check 'upwards'
      nextUnselected = currentFocusedElement.previousElementSibling;
      while (nextUnselected) {
        if (nextUnselected.getAttribute("aria-selected") === "false") {
          return nextUnselected;
        } else {
          nextUnselected = nextUnselected.previousElementSibling;
          if (!nextUnselected) break;
        }
      }
      // if no unselected options found, change focus to list
      list.focus();
    } else {
      return null;
    }
  }

  // handles going up and down list via keyboard (ArrowUp, ArrowDown, Home, End)
  #handleVerticalNavigation(event, direction, navigateSize) {
    const selectedOptionNodeList = this.#getSelectedOptions(
      event.target.parentNode,
    );

    // check if user is moving an option up and down list, or just navigating
    let selectedOption;
    if (
      // check the following:
      // 1. In Selected List (ordering is irrelevant in Available list)
      // 2. only 1 option selected
      // 3. user is using ArrowUp/Down (not Home/End)
      // 4. Alt key is being used
      // 5. user is on the selected option and not a different option
      event.target.parentNode === this.selectedList &&
      selectedOptionNodeList.length === 1 &&
      (event.key === "ArrowUp" || event.key === "ArrowDown") &&
      event.altKey &&
      event.target.getAttribute("aria-selected") === "true"
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
    if (targetOption) {
      this.#updateListAttributes(targetOption);
    }
  }

  // NavigateListUpAndDown handles all the following use cases:
  // 1. User is navigating via keyboard with ArrowUp/Down and Home/End
  // 2. User is selecting options with Shift+ArrowUp/Down
  // 3. User is moving a selected option up/down list via keyboard input
  // 4. User is moving a selected option up/down list via Up/Down buttons

  // params:
  // direction: up/down
  // targetOption: the option user is navigating towards (ie: if going up 1 stop from option 2, target option is option 1)
  // selectedOption: option that user is moving up/down list, is null if user is just navigating
  #navigateListUpAndDown(direction, targetOption, selectedOption, event) {
    // return if no target option (eg: keyboard ArrowUp when already on the top option)
    if (!targetOption) return;
    // user is moving an option up/down list
    if (selectedOption) {
      selectedOption.remove();
      targetOption.insertAdjacentElement(
        direction === "up" ? "beforebegin" : "afterend",
        selectedOption,
      );
      // if using keyboard, keep focus on the moving option
      if (event.type === "keydown") {
        selectedOption.focus();
      }
    } else {
      //  user is selecting items by Shift+ArrowUp/Down
      if (event.shiftKey) {
        // get list, unselect all the options in preparation to re-select options
        const list = event.target.parentNode;
        this.#unselectListOptions(list);
        // set the list into 'select' mode, where we set which option is the shift selection is based around
        // and add a listener to the list for when the user releases shift and we can stop the shift-select
        if (!list.hasAttribute("shift-select")) {
          this.#shiftSelectionOption = event.target;
          this.#setListForShiftKeyboardSelection(list);
        }
        // get index of target option, and add/remove an index point based on direction
        // as the event.target is 'behind' by an index
        // eg: we're on option 2 (index 1), and push Shift+ArrowDown, event.target index will return 2 (where we want
        // index 3), so we add 1 based on ArrowDown
        const listOptions = Array.from(list.querySelectorAll("li"));
        let navigatedSelectionIndex = listOptions.indexOf(event.target);
        direction === "up"
          ? navigatedSelectionIndex--
          : navigatedSelectionIndex++;

        // index of selection where shift select is centered around
        const startingSelectionIndex = listOptions.indexOf(
          this.#shiftSelectionOption,
        );
        // make selections based on indexes
        this.#selectOptionRange(
          startingSelectionIndex,
          navigatedSelectionIndex,
          listOptions,
        );
      }
      targetOption.focus();
    }
  }

  // user is shift selecting items by keyboard, we add a listener for when shift is keyup'd
  #setListForShiftKeyboardSelection(list) {
    list.setAttribute("shift-select", "enabled");
    list.addEventListener("keyup", this.boundEndShiftSelect);
  }

  // remove shift select attributes upon shift keyup
  #endShiftSelect(event) {
    if (event.key == "Shift") {
      const list = event.target.parentNode;
      list.removeAttribute("shift-select");
      list.removeEventListener("keyup", this.boundEndShiftSelect);
      this.#shiftSelectionOption = null;
    }
  }

  // handles up and down buttons
  moveSelection(event) {
    const selectedOption = this.#getSelectedOptions(this.selectedList)[0];
    const listOptions = Array.from(this.selectedList.querySelectorAll("li"));
    const selectedOptionIndex = listOptions.indexOf(selectedOption);

    let targetOption;
    let direction;
    if (event.target === this.upButtonTarget) {
      if (selectedOptionIndex != 0) {
        targetOption = listOptions[selectedOptionIndex - 1];
      }
      direction = "up";
    } else {
      if (selectedOptionIndex != listOptions.length - 1) {
        targetOption = listOptions[selectedOptionIndex + 1];
      }
      direction = "down";
    }

    this.#navigateListUpAndDown(direction, targetOption, selectedOption, event);
  }

  // handles normal click and shift click events
  handleClick(event) {
    const option = event.target;
    if (event.shiftKey) {
      this.#handleShiftClick(option);
    } else {
      this.#lastClickedOption = option;
      this.#selectOrUnselectOption(option);
    }
    this.#updateListAttributes(option);
    this.#checkButtonStates();
  }

  #handleShiftClick(option) {
    const listOptions = Array.from(option.parentNode.querySelectorAll("li"));
    // if there was an option clicked, we base the shift click around that option
    // else shift click from top of list
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
    checkmark.querySelector("span").id =
      `${this.#validateId(option.innerText)}_selected`;
    option
      .querySelector(
        `span[id="${this.#validateId(option.innerText)}_unselected"`,
      )
      .replaceWith(checkmark);
    option.setAttribute("aria-selected", "true");
  }

  // remove checkmark from option
  #removeSelectedAttributes(option) {
    const hiddenCheckmark =
      this.hiddenCheckmarkTemplateTarget.content.cloneNode(true);
    hiddenCheckmark.querySelector("span").id =
      `${this.#validateId(option.innerText)}_unselected`;

    option
      .querySelector(`span[id="${this.#validateId(option.innerText)}_selected"`)
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
    template.querySelector("li").firstElementChild.id =
      `${this.#validateId(element)}_unselected`;
    template.querySelector("li").lastElementChild.innerText = element;
    template.querySelector("li").id = this.#validateId(element);
    list.append(template);
  }

  // Handles 2 things:
  // 1. ensures that each list contains only 1 option that is tabbable. important for refreshing after
  // options have been moved between lists
  // 2. Updates aria-activedescendants
  #updateListAttributes(currentOption) {
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
    this.#updateAriaActiveDescendant(currentOption, currentOption.parentNode);
  }

  #verifyListHasTabIndex(list) {
    const firstChild = list.firstElementChild;
    if (firstChild && !list.querySelector('[data-tabbable="true"]')) {
      firstChild.tabIndex = "0";
      firstChild.setAttribute("data-tabbable", "true");
      this.#updateAriaActiveDescendant(firstChild, list);
    } else {
      this.#updateAriaActiveDescendant(firstChild, list);
    }
  }

  // replace whitespace with hyphen
  #validateId(id) {
    return id.replace(/\s+/g, "-");
  }

  #updateAriaLive(updateString) {
    this.ariaLiveUpdateTarget.innerText = updateString;
  }

  #updateAriaActiveDescendant(option, list) {
    // set activedescendant to null if no options remain in list
    list.setAttribute("aria-activedescendant", option ? option.id : null);
  }
}
