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
    "maxItemsMessage",
  ];

  static values = {
    selectedList: String,
    availableList: String,
    fieldName: String,
  };

  static ARIA_SELECTED_TRUE = "true";
  static ARIA_SELECTED_FALSE = "false";
  static ARIA_DISABLED_TRUE = "true";
  static ARIA_DISABLED_FALSE = "false";
  static ARIA_REQUIRED_TRUE = "true";

  #originalAvailableList;
  #idCache = new Map();

  #lastClickedOption;
  #shiftSelectionOption;

  #ariaLiveTranslations;

  #savedOptionsState;

  connect() {
    // this.DnDListener = this.#updateAriaByDnD.bind(this);
    this.boundEndShiftSelect = this.#endShiftSelect.bind(this);

    // Get a handle on the available and selected lists
    this.idempotentConnect();
  }

  idempotentConnect() {
    this.availableList = document.getElementById(this.availableListValue);
    this.selectedList = document.getElementById(this.selectedListValue);

    // check if aria-live exists as it's added after file selection in import metadata (can't be done in connect())
    if (!this.#ariaLiveTranslations && this.hasAriaLiveUpdateTarget) {
      this.#ariaLiveTranslations = JSON.parse(
        this.ariaLiveUpdateTarget.getAttribute("data-translations"),
      );
    }

    if (this.availableList && this.selectedList) {
      // Temporarily disabled drag and drop functionality
      // this.selectedList.addEventListener("drop", this.DnDListener);
      // this.availableList.addEventListener("drop", this.DnDListener);

      // Enforce max items limit on initial load - BEFORE setting originalAvailableList
      this.#enforceMaxItemsLimit();

      // Get a handle on the original available list
      this.#originalAvailableList = [
        ...this.availableList.querySelectorAll("li"),
        ...this.selectedList.querySelectorAll("li"),
      ];
      Object.freeze(this.#originalAvailableList);

      // sets the first element in each list to be tabbable (ie: tabIndex = 0)
      this.#initializeLists();
      this.#checkStates();
    }
  }

  #enforceMaxItemsLimit() {
    // Make sure we have the lists
    if (!this.selectedList || !this.availableList) {
      return;
    }

    const maxItems = this.selectedList.getAttribute(
      "data-viral--sortable-lists--list-max-items-value",
    );

    if (!maxItems) {
      return;
    }

    const selectedItems = Array.from(this.selectedList.querySelectorAll("li"));
    const maxItemsInt = parseInt(maxItems);

    if (selectedItems.length > maxItemsInt) {
      // Move excess items to available list
      const excessItems = selectedItems.slice(maxItemsInt);

      excessItems.forEach((item) => {
        // Remove any selection attributes before moving
        if (
          item.getAttribute("aria-selected") ===
          this.constructor.ARIA_SELECTED_TRUE
        ) {
          this.#removeSelectedAttributes(item);
        }
        this.availableList.appendChild(item);
      });

      // Update counters after moving items
      this.#updateCounters();
    }
  }

  // Temporarily disabled - drag and drop functionality removed
  // #updateAriaByDnD() {
  //   let ariaLiveParams;
  //   // get the current list options to compare with the lists' previous states
  //   let currentAvailableOptions = this.#extractOptionsIntoArray(
  //     document.getElementById(this.availableListValue),
  //   );
  //   let currentSelectedOptions = this.#extractOptionsIntoArray(
  //     document.getElementById(this.selectedListValue),
  //   );

  //   // if length is equal, means only ordering could have changed
  //   if (
  //     currentSelectedOptions.length ===
  //     this.#savedOptionsState["selected"].length
  //   ) {
  //     ariaLiveParams = this.#verifyDnDOrderChange(
  //       currentSelectedOptions,
  //       currentAvailableOptions,
  //     );

  //     // lengths are not equal, therefore an option was added/removed
  //   } else {
  //     ariaLiveParams = this.#verifyDnDAddOrRemoveChange(
  //       currentSelectedOptions,
  //       currentAvailableOptions,
  //     );
  //   }

  //   if (ariaLiveParams) {
  //     // update aria-live text
  //     const ariaLiveText = this.#generateAriaLiveText(ariaLiveParams);
  //     this.#updateAriaLive(ariaLiveText);

  //     // option was moved between lists; remove selected attributes (checkmark)
  //     if (ariaLiveParams.hasOwnProperty("movedOption")) {
  //       const movedOption = ariaLiveParams.movedOption;
  //       const movedOptionElement = this.#getOptionNode(movedOption);

  //       if (movedOptionElement.getAttribute("aria-selected") === "true") {
  //         this.#removeSelectedAttributes(movedOptionElement);
  //       }
  //     }
  //   }
  //   this.#checkStates();
  // }

  // Temporarily disabled - drag and drop functionality removed
  // #verifyDnDOrderChange(currentSelectedOptions, currentAvailableOptions) {
  //   let params;
  //   // stringify options arrays and verify any differences. If a difference exists, ordering has been changed
  //   if (
  //     // check selected list
  //     JSON.stringify(currentSelectedOptions) !==
  //     JSON.stringify(this.#savedOptionsState["selected"])
  //   ) {
  //     params = {
  //       action: "list_order_changed",
  //       listName: this.selectedListValue,
  //       options: currentSelectedOptions,
  //     };
  //   } else if (
  //     // check available list
  //     JSON.stringify(currentAvailableOptions) !==
  //     JSON.stringify(this.#savedOptionsState["available"])
  //   ) {
  //     params = {
  //       action: "list_order_changed",
  //       listName: this.availableListValue,
  //       options: currentAvailableOptions,
  //     };
  //   }
  //   return params;
  // }

  // Temporarily disabled - drag and drop functionality removed
  // #verifyDnDAddOrRemoveChange(currentSelectedOptions, currentAvailableOptions) {
  //   let movedOption;
  //   let params;
  //   if (
  //     // option was added to selected list
  //     currentSelectedOptions.length > this.#savedOptionsState["selected"].length
  //   ) {
  //     movedOption = this.#verifyOptionsDifference(
  //       currentSelectedOptions,
  //       this.#savedOptionsState["selected"],
  //     );
  //     params = {
  //       action: "added",
  //       movedOption: movedOption,
  //     };
  //   } else if (
  //     // option was added (removed) to available list
  //     currentAvailableOptions.length >
  //     this.#savedOptionsState["available"].length
  //   ) {
  //     movedOption = this.#verifyOptionsDifference(
  //       currentAvailableOptions,
  //       this.#savedOptionsState["available"],
  //     );
  //     params = {
  //       action: "removed",
  //       movedOption: movedOption,
  //     };
  //   }
  //   // fix tabindexing after option moved via drag and drop
  //   this.#updateListAttributes(this.#getOptionNode(params.movedOption));
  //   return params;
  // }

  // Temporarily disabled - drag and drop functionality removed
  // #generateAriaLiveText(params) {
  //   const action = params["action"];
  //   let ariaLiveString = this.#ariaLiveTranslations[action];
  //   if (action === "list_order_changed") {
  //     return ariaLiveString
  //       .replace(/LIST_PLACEHOLDER/g, params["listName"])
  //       .concat(params["options"].join(", "));
  //   } else {
  //     return ariaLiveString.concat(params["movedOption"]);
  //   }
  // }

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

    // check if up/down button should be disabled based on selected option position
    const verifySelectedOptionPosition = (direction) => {
      // if selected list contains 1 selected option
      if (selectedListSelectedOptions.length === 1) {
        let comparison;
        // if up, enable up button if the selected option is not the first option
        if (direction === "up") {
          comparison =
            selectedListSelectedOptions[0] !==
            this.selectedList.firstElementChild;
          // if down, enable down button if the selected option is not the last option
        } else {
          comparison =
            selectedListSelectedOptions[
              selectedListSelectedOptions.length - 1
            ] !== this.selectedList.lastElementChild;
        }
        if (comparison) {
          return false;
        }
      }
      return true;
    };

    // Check if selected list would exceed max items
    const wouldExceedMaxItems = () => {
      const maxItems = this.selectedList.getAttribute(
        "data-viral--sortable-lists--list-max-items-value",
      );
      if (!maxItems) {
        return false;
      }
      const currentCount = this.selectedList.querySelectorAll("li").length;
      const selectedCount = availableListSelectedOptions.length;
      return currentCount + selectedCount > parseInt(maxItems);
    };

    // disable add button if no options selected in available list or if max items would be exceeded
    const shouldDisableAdd =
      availableListSelectedOptions.length == 0 || wouldExceedMaxItems();
    this.#setButtonDisableState(this.addButtonTarget, shouldDisableAdd);

    // Show/hide max items message
    if (this.hasMaxItemsMessageTarget) {
      if (availableListSelectedOptions.length > 0 && wouldExceedMaxItems()) {
        this.maxItemsMessageTarget.classList.remove("hidden");
      } else {
        this.maxItemsMessageTarget.classList.add("hidden");
      }
    }

    // disable remove button if no options selected in selected list
    this.#setButtonDisableState(
      this.removeButtonTarget,
      selectedListSelectedOptions.length == 0,
    );

    // disable up/down buttons unless exactly 1 option selected in selected list
    this.#setButtonDisableState(
      this.upButtonTarget,
      verifySelectedOptionPosition("up"),
    );

    this.#setButtonDisableState(
      this.downButtonTarget,
      verifySelectedOptionPosition("down"),
    );

    // disable submit if no options in selected list
    this.#setSubmitButtonDisableState(
      this.selectedList.getAttribute("aria-required") ===
        this.constructor.ARIA_REQUIRED_TRUE &&
        this.selectedList.querySelectorAll("li").length === 0,
    );
  }

  #checkTemplateSelectorState() {
    const selectedItems = Array.from(this.selectedList.querySelectorAll("li"));

    if (selectedItems.length === 0) {
      this.templateSelectorTarget.value = "none";
      return;
    }

    const selectedListValues = JSON.stringify(
      selectedItems.map((li) => li.lastElementChild.textContent),
    );

    const matchingTemplate = Array.from(
      this.templateSelectorTarget.options,
    ).find((option) => {
      if (!option.dataset.fields) return false;
      return (
        JSON.stringify(JSON.parse(option.dataset.fields)) === selectedListValues
      );
    });

    this.templateSelectorTarget.value = matchingTemplate?.value ?? "none";
  }

  #setSubmitButtonDisableState(disableState) {
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = disableState;
    }
  }

  #setButtonDisableState(button, disableState) {
    if (disableState) {
      button.setAttribute("aria-disabled", this.constructor.ARIA_DISABLED_TRUE);
    } else {
      button.setAttribute(
        "aria-disabled",
        this.constructor.ARIA_DISABLED_FALSE,
      );
    }
  }

  #getSelectedOptions(list) {
    return list.querySelectorAll(
      `li[aria-selected="${this.constructor.ARIA_SELECTED_TRUE}"]`,
    );
  }

  constructParams() {
    this.fieldTarget.replaceChildren(
      ...Array.from(this.selectedList.querySelectorAll("li")).map((li) =>
        createHiddenInput(this.fieldNameValue, li.lastElementChild.textContent),
      ),
    );
  }

  disconnect() {
    // Temporarily disabled drag and drop functionality
    // this.selectedList.removeEventListener("drop", this.DnDListener);
    // this.availableList.removeEventListener("drop", this.DnDListener);
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
        this.#reinitializeLists();
        return;
      }

      // Sort items into selected/available lists based on template fields
      // but maintain the order of the items in the template fields
      const fields = JSON.parse(selectedOption.dataset.fields);
      const items = Array.from(this.availableList.querySelectorAll("li"));
      const textFields = Array.from(items).map(
        (item) => item.lastElementChild.textContent,
      );

      // Check max items limit before processing
      const maxItems = this.selectedList.getAttribute(
        "data-viral--sortable-lists--list-max-items-value",
      );
      const fieldsToAdd = maxItems
        ? Math.min(fields.length, parseInt(maxItems))
        : fields.length;

      // Only add items up to the max limit
      for (let i = 0; i < fieldsToAdd; i++) {
        const element = fields[i];
        const index = textFields.indexOf(element);
        if (index !== -1) {
          this.selectedList.append(items[index]);
          items.splice(index, 1);
          textFields.splice(index, 1);
        } else {
          this.#createListItem(element, this.selectedList);
        }
      }
      this.availableList.append(...items);

      // Enforce max items BEFORE reinitializing
      this.#enforceMaxItemsLimit();
      this.#reinitializeLists();
    } catch (error) {
      console.error("Error setting template:", error);
    }
  }

  #reinitializeLists() {
    this.#removeTabIndexFromList(this.availableList);
    this.#removeTabIndexFromList(this.selectedList);
    this.#initializeLists();
    this.#checkButtonStates();
    this.#updateCounters();
    this.#saveListStates();
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
      Enter: this.#addSelectionByListInput.bind(this),
      Delete: this.#removeSelectionByListInput.bind(this),
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
    this.#checkStates();
  }

  #selectOrUnselectOption(option) {
    if (
      option.querySelector(
        `span[id="${this.#validateId(option.lastElementChild.textContent)}_unselected"`,
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

  #addSelectionByListInput(event) {
    if (event.target.parentNode != this.availableList) return;
    if (!this.#canAddToSelectedList()) return;
    this.#performSelection(true, true, this.availableList, this.selectedList);
  }

  addSelectionByAddButton() {
    if (
      this.addButtonTarget.getAttribute("aria-disabled") ===
      this.constructor.ARIA_DISABLED_FALSE
    ) {
      this.#performSelection(
        false,
        false,
        this.availableList,
        this.selectedList,
      );
    }
  }

  #canAddToSelectedList() {
    const maxItems = this.selectedList.getAttribute(
      "data-viral--sortable-lists--list-max-items-value",
    );
    if (!maxItems) {
      return true;
    }
    const currentCount = this.selectedList.querySelectorAll("li").length;
    const selectedCount = this.#getSelectedOptions(this.availableList).length;
    return currentCount + selectedCount <= parseInt(maxItems);
  }

  #removeSelectionByListInput(event) {
    if (event.target.parentNode != this.selectedList) return;
    this.#performSelection(true, true, this.selectedList, this.availableList);
  }

  removeSelectionByRemoveButton() {
    if (
      this.removeButtonTarget.getAttribute("aria-disabled") ===
      this.constructor.ARIA_DISABLED_FALSE
    ) {
      this.#performSelection(
        false,
        false,
        this.selectedList,
        this.availableList,
      );
    }
  }

  // isKeyDown: is action performed by keyboard
  // isFromList: is the action performed within the list (ie: from list or from add/remove buttons)
  #performSelection(isKeyDown, isFromList, sourceList, targetList) {
    let focusTarget = null;

    // if action is keydown and performed within the list, find list item to focus
    if (isKeyDown && isFromList) {
      focusTarget = this.#getFocusTargetAfterSelection(sourceList);
    }
    const selectedOptions = this.#getSelectedOptions(sourceList);

    // Enforce max items limit when adding to selected list
    let optionsToMove = Array.from(selectedOptions);
    if (targetList === this.selectedList) {
      const maxItems = this.selectedList.getAttribute(
        "data-viral--sortable-lists--list-max-items-value",
      );
      if (maxItems) {
        const currentCount = this.selectedList.querySelectorAll("li").length;
        const maxAllowed = parseInt(maxItems) - currentCount;

        if (maxAllowed <= 0) {
          // Already at max, don't move any items
          this.#checkStates();
          return;
        }
        // Only move up to max allowed
        optionsToMove = optionsToMove.slice(0, maxAllowed);
      }
    }

    let selectedOptionsText = [];
    if (optionsToMove.length > 0) {
      for (let i = 0; i < optionsToMove.length; i++) {
        selectedOptionsText.push(optionsToMove[i].lastElementChild.textContent);
        this.#removeSelectedAttributes(optionsToMove[i]);
        targetList.appendChild(optionsToMove[i]);
      }

      // if action is keydown but not from within the list (ie: keydown on add/remove btn), focus first list element
      // if it exists, or focus the list
      if (focusTarget) {
        focusTarget.focus();
      } else if (isKeyDown && !isFromList) {
        sourceList.firstElementChild
          ? sourceList.firstElementChild.focus()
          : sourceList.focus();
      }
      this.#updateListAttributes(optionsToMove[0]);
    }

    // If we couldn't move all selected items, unselect the ones that couldn't be moved
    if (optionsToMove.length < selectedOptions.length) {
      const remainingOptions = Array.from(selectedOptions).slice(
        optionsToMove.length,
      );
      remainingOptions.forEach((option) => {
        this.#removeSelectedAttributes(option);
      });
    }

    let ariaLiveUpdateString =
      sourceList === this.selectedList
        ? this.#ariaLiveTranslations["removed"]
        : this.#ariaLiveTranslations["added"];

    this.#updateAriaLive(
      ariaLiveUpdateString.concat(selectedOptionsText.join(", ")),
    );

    // Enforce max items after any move operation
    this.#enforceMaxItemsLimit();
    this.#checkStates();
  }

  #getFocusTargetAfterSelection(list) {
    const currentFocusedElement = document.activeElement;

    // if current focus element is a selected element, find next unselected
    // else if current focus element not selected, just return as we will keep the current focus
    if (
      currentFocusedElement.getAttribute("aria-selected") ===
      this.constructor.ARIA_SELECTED_TRUE
    ) {
      let nextUnselected = currentFocusedElement.nextElementSibling;

      // check list 'downwards' if there's an unselected option
      while (nextUnselected) {
        if (
          nextUnselected.getAttribute("aria-selected") ===
          this.constructor.ARIA_SELECTED_FALSE
        ) {
          return nextUnselected;
        } else {
          nextUnselected = nextUnselected.nextElementSibling;
          if (!nextUnselected) break;
        }
      }

      // if after going downwards, no unselected options were found, check 'upwards'
      nextUnselected = currentFocusedElement.previousElementSibling;
      while (nextUnselected) {
        if (
          nextUnselected.getAttribute("aria-selected") ===
          this.constructor.ARIA_SELECTED_FALSE
        ) {
          return nextUnselected;
        } else {
          nextUnselected = nextUnselected.previousElementSibling;
          if (!nextUnselected) break;
        }
      }
      // if no unselected options found, change focus to list
      return list;
    }
  }

  // handles going up and down list via keyboard (ArrowUp, ArrowDown, Home, End)
  #handleVerticalNavigation(event, direction, navigateSize) {
    const currentList = event.target.parentNode;
    const selectedOptionNodeList = this.#getSelectedOptions(currentList);

    // check if user is moving an option up and down list, or just navigating
    let selectedOption;
    if (
      // check the following:
      // 1. In Selected List (ordering is irrelevant in Available list)
      // 2. only 1 option selected
      // 3. user is using ArrowUp/Down (not Home/End)
      // 4. Alt key is being used
      // 5. user is on the selected option and not a different option
      currentList === this.selectedList &&
      selectedOptionNodeList.length === 1 &&
      (event.key === "ArrowUp" || event.key === "ArrowDown") &&
      event.altKey &&
      event.target.getAttribute("aria-selected") ===
        this.constructor.ARIA_SELECTED_TRUE
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
          ? currentList.firstElementChild
          : currentList.lastElementChild;
    this.#navigateListHorizontally(
      direction === "up" ? "up" : "down",
      targetOption,
      selectedOption,
      event,
    );
  }

  // navigateListHorizontally handles all the following use cases:
  // 1. User is navigating via keyboard with ArrowUp/Down and Home/End
  // 2. User is selecting options with Shift+ArrowUp/Down
  // 3. User is moving a selected option up/down list via keyboard input
  // 4. User is moving a selected option up/down list via Up/Down buttons

  // params:
  // direction: up/down
  // targetOption: the option user is navigating towards (ie: if going up 1 stop from option 2, target option is option 1)
  // selectedOption: option that user is moving up/down list, is null if user is just navigating
  #navigateListHorizontally(direction, targetOption, selectedOption, event) {
    // return if no target option (eg: keyboard ArrowUp when already on the top option)
    if (!targetOption) return;
    // user is moving an option up/down list
    if (selectedOption) {
      this.#moveOptionHorizontally(selectedOption, targetOption, direction);
    } else {
      const currentList = event.target.parentNode;
      //  user is selecting items by Shift+ArrowUp/Down
      if (event.shiftKey) {
        this.#selectMultipleOptions(event.target, currentList, direction);
      }
      this.#removeTabIndexFromList(currentList);
      this.#setActiveListElement(currentList, targetOption);
      targetOption.focus();
    }

    this.#checkStates();
  }

  #moveOptionHorizontally(selectedOption, targetOption, direction) {
    targetOption.remove();
    selectedOption.insertAdjacentElement(
      direction === "up" ? "afterend" : "beforebegin",
      targetOption,
    );

    const ariaLiveText = this.#ariaLiveTranslations[
      direction === "up" ? "move_up" : "move_down"
    ].replace(
      /OPTION_PLACEHOLDER/g,
      selectedOption.lastElementChild.textContent,
    );
    this.#updateAriaLive(ariaLiveText);
  }

  #selectMultipleOptions(target, list, direction) {
    // get list, unselect all the options in preparation to re-select options
    this.#unselectListOptions(list);
    // set the list into 'select' mode, where we set which option is the shift selection is based around
    // and add a listener to the list for when the user releases shift and we can stop the shift-select
    if (!list.hasAttribute("shift-select")) {
      this.#shiftSelectionOption = target;
      this.#setListForShiftKeyboardSelection(list);
    }
    // get index of target option, and add/remove an index point based on direction
    // as the event.target is 'behind' by an index
    // eg: we're on option 2 (index 1), and push Shift+ArrowDown, event.target index will return 2 (where we want
    // index 3), so we add 1 based on ArrowDown
    const listOptions = Array.from(list.querySelectorAll("li"));
    let navigatedSelectionIndex = listOptions.indexOf(target);
    direction === "up" ? navigatedSelectionIndex-- : navigatedSelectionIndex++;

    // index of selection where shift select is centered around
    const startingSelectionIndex = listOptions.indexOf(
      this.#shiftSelectionOption,
    );

    // Check if selecting range in available list would exceed max
    if (list === this.availableList) {
      const maxItems = this.selectedList.getAttribute(
        "data-viral--sortable-lists--list-max-items-value",
      );
      if (maxItems) {
        const currentCount = this.selectedList.querySelectorAll("li").length;
        const lowerIndex = Math.min(
          startingSelectionIndex,
          navigatedSelectionIndex,
        );
        const higherIndex = Math.max(
          startingSelectionIndex,
          navigatedSelectionIndex,
        );
        const rangeSize = higherIndex - lowerIndex + 1;
        const maxAllowed = parseInt(maxItems) - currentCount;

        if (rangeSize > maxAllowed) {
          // Only select up to max allowed
          for (let i = lowerIndex; i < lowerIndex + maxAllowed; i++) {
            this.#addSelectedAttributes(listOptions[i]);
          }
          return;
        }
      }
    }

    // make selections based on indexes
    this.#selectOptionRange(
      startingSelectionIndex,
      navigatedSelectionIndex,
      listOptions,
    );
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
    if (
      event.target.getAttribute("aria-disabled") ===
      this.constructor.ARIA_DISABLED_TRUE
    )
      return;

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

    this.#navigateListHorizontally(
      direction,
      targetOption,
      selectedOption,
      event,
    );
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
    this.#checkStates();
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

      // Check if selecting range in available list would exceed max
      if (option.parentNode === this.availableList) {
        const maxItems = this.selectedList.getAttribute(
          "data-viral--sortable-lists--list-max-items-value",
        );
        if (maxItems) {
          const currentCount = this.selectedList.querySelectorAll("li").length;
          const lowerIndex = Math.min(lastClickedIndex, currentClickedIndex);
          const higherIndex = Math.max(lastClickedIndex, currentClickedIndex);
          const rangeSize = higherIndex - lowerIndex + 1;
          const maxAllowed = parseInt(maxItems) - currentCount;

          if (rangeSize > maxAllowed) {
            // Only select up to max allowed
            for (let i = lowerIndex; i < lowerIndex + maxAllowed; i++) {
              this.#addSelectedAttributes(listOptions[i]);
            }
            return;
          }
        }
      }

      this.#selectOptionRange(
        currentClickedIndex,
        lastClickedIndex,
        listOptions,
      );
    } else {
      // Check if selecting from top would exceed max
      if (option.parentNode === this.availableList) {
        const maxItems = this.selectedList.getAttribute(
          "data-viral--sortable-lists--list-max-items-value",
        );
        if (maxItems) {
          const currentCount = this.selectedList.querySelectorAll("li").length;
          const maxAllowed = parseInt(maxItems) - currentCount;

          let selectedCount = 0;
          for (
            let i = 0;
            i < listOptions.length && selectedCount < maxAllowed;
            i++
          ) {
            this.#addSelectedAttributes(listOptions[i]);
            selectedCount++;
            if (listOptions[i] === option) {
              break;
            }
          }
          this.#lastClickedOption = listOptions[0];
          return;
        }
      }

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
      `li[aria-selected="${this.constructor.ARIA_SELECTED_FALSE}"]`,
    );
    // if everything is selected, unselect
    // else select all
    if (unselectedOptions.length == 0) {
      this.#unselectListOptions(listNode);
    } else {
      // If selecting all in available list, check if it would exceed max
      if (listNode === this.availableList) {
        const maxItems = this.selectedList.getAttribute(
          "data-viral--sortable-lists--list-max-items-value",
        );
        if (maxItems) {
          const currentCount = this.selectedList.querySelectorAll("li").length;
          const availableCount = allOptions.length;
          const maxAllowed = parseInt(maxItems) - currentCount;

          // Only select up to the max allowed
          let selectedCount = 0;
          for (
            let i = 0;
            i < allOptions.length && selectedCount < maxAllowed;
            i++
          ) {
            if (
              allOptions[i].getAttribute("aria-selected") ===
              this.constructor.ARIA_SELECTED_FALSE
            ) {
              this.#addSelectedAttributes(allOptions[i]);
              selectedCount++;
            }
          }
          this.#checkStates();
          return;
        }
      }

      for (let i = 0; i < allOptions.length; i++) {
        if (
          allOptions[i].getAttribute("aria-selected") ===
          this.constructor.ARIA_SELECTED_FALSE
        ) {
          this.#addSelectedAttributes(allOptions[i]);
        }
      }
    }
    this.#checkStates();
  }

  #unselectListOptions(list) {
    const listOptions = list.querySelectorAll("li");
    for (let i = 0; i < listOptions.length; i++) {
      if (
        listOptions[i].getAttribute("aria-selected") ===
        this.constructor.ARIA_SELECTED_TRUE
      ) {
        this.#removeSelectedAttributes(listOptions[i]);
      }
    }
  }

  // add checkmark to option
  #addSelectedAttributes(option) {
    const checkmark = this.checkmarkTemplateTarget.content.cloneNode(true);
    const optionText = option.lastElementChild.textContent;
    checkmark.querySelector("span").id =
      `${this.#validateId(optionText)}_selected`;
    option
      .querySelector(`span[id="${this.#validateId(optionText)}_unselected"`)
      .replaceWith(checkmark);
    option.setAttribute("aria-selected", this.constructor.ARIA_SELECTED_TRUE);
  }

  // remove checkmark from option
  #removeSelectedAttributes(option) {
    const hiddenCheckmark =
      this.hiddenCheckmarkTemplateTarget.content.cloneNode(true);
    const optionText = option.lastElementChild.textContent;
    hiddenCheckmark.querySelector("span").id =
      `${this.#validateId(optionText)}_unselected`;

    option
      .querySelector(`span[id="${this.#validateId(optionText)}_selected"`)
      .replaceWith(hiddenCheckmark);

    option.setAttribute("aria-selected", this.constructor.ARIA_SELECTED_FALSE);
  }

  // used for dynamic/changing listing values
  updateMetadataListing({ detail: { content } }) {
    let newMetadata = content["metadata"];
    let existingMetadata = { available: [], selected: [] };

    // check which values already exist in lists; prevents moving metadata between lists that have already been moved
    // by user
    this.availableList.querySelectorAll("li").forEach((availableMetadata) => {
      const text = availableMetadata.lastElementChild.textContent;
      if (newMetadata.includes(text)) {
        existingMetadata["available"].push(text);
        newMetadata.splice(newMetadata.indexOf(text), 1);
      }
    });

    this.selectedList.querySelectorAll("li").forEach((selectedMetadata) => {
      const text = selectedMetadata.lastElementChild.textContent;
      if (newMetadata.includes(text)) {
        existingMetadata["selected"].push(text);
        newMetadata.splice(newMetadata.indexOf(text), 1);
      }
    });

    // reset lists
    this.availableList.innerHTML = "";
    this.selectedList.innerHTML = "";

    // Check max items limit
    const maxItems = this.selectedList.getAttribute(
      "data-viral--sortable-lists--list-max-items-value",
    );
    let selectedMetadata = existingMetadata["selected"].concat(newMetadata);

    // Enforce max items limit - move excess to available list
    let overflowMetadata = [];
    if (maxItems && selectedMetadata.length > parseInt(maxItems)) {
      overflowMetadata = selectedMetadata.splice(parseInt(maxItems));
    }

    // repopulate lists with existing and new metadata
    existingMetadata["available"]
      .concat(overflowMetadata)
      .forEach((metadata) => {
        this.#createListItem(metadata, this.availableList);
      });

    selectedMetadata.forEach((metadata) => {
      this.#createListItem(metadata, this.selectedList);
    });

    // Enforce max items BEFORE reconnecting
    this.#enforceMaxItemsLimit();
    this.idempotentConnect();
  }

  #createListItem(element, list) {
    let template = this.itemTemplateTarget.content.cloneNode(true);
    template.querySelector("li").firstElementChild.id =
      `${this.#validateId(element)}_unselected`;
    template.querySelector("li").lastElementChild.textContent = element;
    template.querySelector("li").id = this.#validateId(element);
    list.append(template);
  }

  // replace whitespace with hyphen
  #validateId(id) {
    if (!this.#idCache.has(id)) {
      this.#idCache.set(id, id.replace(/\s+/g, "-"));
    }
    return this.#idCache.get(id);
  }

  // updates and retains the options lists to compare for aria-live updating
  #saveListStates() {
    this.#savedOptionsState = {};

    this.#savedOptionsState["available"] = this.#extractOptionsIntoArray(
      this.availableList,
    );
    this.#savedOptionsState["selected"] = this.#extractOptionsIntoArray(
      this.selectedList,
    );
  }

  // turns <ul> DOM element and returns an array of its list
  // eg: receives <ul><li>OPTION1</li><li>OPTION2</li></ul> and returns ['OPTION1', 'OPTION2']
  #extractOptionsIntoArray(list) {
    return Array.from(
      list.querySelectorAll("li"),
      (option) => option.lastElementChild.textContent,
    );
  }

  // finds the difference between two lists. This is specifically used for the drag and drop listener, so only one
  // option difference at most will be found
  // eg: receives [1, 2, 3] and [1, 2, 3, 4] and returns 4
  // Temporarily disabled - drag and drop functionality removed
  // #verifyOptionsDifference(listOne, listTwo) {
  //   let difference = listOne.filter((x) => !listTwo.includes(x));
  //   return difference[0];
  // }

  // Temporarily disabled - drag and drop functionality removed
  // receives OPTION_NAME and returns <li id="OPTION_NAME">OPTION_NAME</li>
  // #getOptionNode(option) {
  //   return document.getElementById(this.#validateId(option));
  // }

  #updateAriaLive(updateString) {
    this.ariaLiveUpdateTarget.innerText = "";
    this.ariaLiveUpdateTarget.innerText = updateString;
  }

  #initializeLists() {
    const availableListFirstOption = this.availableList.firstElementChild;
    const selectedListFirstOption = this.selectedList.firstElementChild;
    if (availableListFirstOption) {
      this.#setActiveListElement(this.availableList, availableListFirstOption);
    }
    if (selectedListFirstOption) {
      this.#setActiveListElement(this.selectedList, selectedListFirstOption);
    }
  }

  #setActiveListElement(list, option) {
    option.tabIndex = 0;
    option.setAttribute("data-tabbable", "true");
    list.setAttribute("aria-activedescendant", option.id);
  }

  #checkStates() {
    this.#saveListStates();
    this.#checkButtonStates();
    this.#updateCounters();
    if (this.hasTemplateSelectorTarget) {
      this.#checkTemplateSelectorState();
      this.#cleanupAvailableList();
    }
  }

  #updateCounters() {
    // Update counter for selected list
    this.#updateListCounter(this.selectedList);
    // Update counter for available list
    this.#updateListCounter(this.availableList);
  }

  #updateListCounter(list) {
    const counterElement = list.parentElement?.querySelector(
      '[data-viral--sortable-lists--list-target="currentCount"]',
    );
    if (counterElement) {
      const currentCount = list.querySelectorAll("li").length;
      counterElement.textContent = currentCount;
    }
  }

  // Handles 2 things:
  // 1. ensures that each list contains only 1 option that is tabbable. important for refreshing after
  // options have been moved between lists
  // 2. Updates active option
  #updateListAttributes(currentOption) {
    const targetList = currentOption.parentNode;
    this.#removeTabIndexFromList(targetList);

    if (targetList === this.selectedList) {
      this.#verifyListHasTabIndex(this.availableList);
    } else {
      this.#verifyListHasTabIndex(this.selectedList);
    }
    this.#setActiveListElement(targetList, currentOption);
  }

  #verifyListHasTabIndex(list) {
    const firstChild = list.firstElementChild;
    // if no options within list, remove aria-activedescendant from list
    if (!firstChild) {
      list.removeAttribute("aria-activedescendant");
      // else if list doesn't contain a tabbable option (eg: previous tabbable option moved to other list), set first
      // option to tabbable/active
    } else if (!list.querySelector('[data-tabbable="true"]')) {
      this.#setActiveListElement(list, firstChild);
    }
  }

  // remove tabindex from options within list
  #removeTabIndexFromList(list) {
    const tababbleOptions = list.querySelectorAll('[data-tabbable="true"]');

    if (tababbleOptions) {
      for (let i = 0; i < tababbleOptions.length; i++) {
        tababbleOptions[i].tabIndex = "-1";
        tababbleOptions[i].removeAttribute("data-tabbable");
      }
    }
  }
}
