import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";
import { announce } from "utilities/live_region";
import WordConnector from "utilities/word_connector";

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
  };

  static ARIA_SELECTED_TRUE = "true";
  static ARIA_SELECTED_FALSE = "false";
  static ARIA_REQUIRED_TRUE = "true";
  static TYPE_AHEAD_TIMEOUT = 500;

  #originalAvailableList;

  #lastClickedOption;
  #lastSelectedAnchor;
  #typeAheadState = new WeakMap();
  #activeOptionCache = new WeakMap();

  #ariaLiveTranslations;
  #boundSubmitClickCapture;

  #availableListName;
  #selectedListName;

  #wordConnector = null;

  connect() {
    this.#boundSubmitClickCapture = this.#onSubmitClickCapture.bind(this);

    this.#ensureAriaLiveReady();
    // Get a handle on the available and selected lists
    this.idempotentConnect();
  }

  idempotentConnect() {
    this.availableList = document.getElementById(this.availableListValue);
    this.selectedList = document.getElementById(this.selectedListValue);

    this.#availableListName =
      this.availableList?.getAttribute("data-title") || "";
    this.#selectedListName =
      this.selectedList?.getAttribute("data-title") || "";

    if (this.availableList && this.selectedList) {
      // Get a handle on the original available list
      this.#originalAvailableList = [
        ...this.availableList.querySelectorAll("li"),
        ...this.selectedList.querySelectorAll("li"),
      ];
      Object.freeze(this.#originalAvailableList);

      // sets the first element in each list to be tabbable (ie: tabIndex = 0)
      this.#initializeLists();
      this.#checkStates();

      if (this.hasSubmitBtnTarget) {
        this.submitBtnTarget.removeEventListener(
          "click",
          this.#boundSubmitClickCapture,
          true,
        );
        this.submitBtnTarget.addEventListener(
          "click",
          this.#boundSubmitClickCapture,
          true,
        );
      }
    }
  }

  disconnect() {
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.removeEventListener(
        "click",
        this.#boundSubmitClickCapture,
        true,
      );
    }
  }

  #ensureAriaLiveReady() {
    // check if aria-live exists as it's added after file selection in import metadata (can't be done in connect())
    if (
      !this.#ariaLiveTranslations &&
      this.hasAriaLiveUpdateTarget &&
      !this.#wordConnector
    ) {
      this.#ariaLiveTranslations = JSON.parse(
        this.ariaLiveUpdateTarget.getAttribute("data-translations"),
      );

      this.#wordConnector = new WordConnector({
        wordsConnector: this.#ariaLiveTranslations["words_connector"],
        twoWordsConnector: this.#ariaLiveTranslations["two_words_connector"],
        lastWordConnector: this.#ariaLiveTranslations["last_word_connector"],
      });
    }
  }

  #cleanupAvailableList() {
    const itemsToRemove = Array.from(
      this.availableList.querySelectorAll("li"),
    ).filter((li) => !this.#originalAvailableList.includes(li));
    const activeOption = this.#getActiveListElement(this.availableList);
    const removesActiveOption = itemsToRemove.includes(activeOption);

    itemsToRemove.forEach((li) => {
      this.#clearActiveOption(li);
      li.remove();
    });

    if (removesActiveOption) {
      this.#updateListAfterMutation(this.availableList);
    }
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

  #isDisabled(element) {
    return element?.getAttribute("aria-disabled") === "true";
  }

  #setDisabled(element, disabled) {
    if (!element) return;
    element.setAttribute("aria-disabled", disabled ? "true" : "false");
  }

  #setSubmitButtonDisableState(disableState) {
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = disableState;
    }
  }

  #setButtonDisableState(button, disableState) {
    this.#setDisabled(button, disableState);
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
      this.#reinitializeLists();
    } catch (error) {
      console.error("Error setting template:", error);
    }
  }

  #reinitializeLists() {
    this.#initializeLists();
    this.#checkButtonStates();
  }

  handleListFocus(event) {
    this.#ensureActiveListElement(event.target);
  }

  handleListBlur(event) {
    this.#clearActiveListElement(event.target);
  }

  handleKeyboardInput(event) {
    const list = event.target;
    if (!this.#isListbox(list)) return;

    const handler = this.#getKeyboardHandler(event);
    if (handler) {
      event.preventDefault();
      handler.call(this, event, list);
      this.#checkStates();
    } else if (this.#isPrintableCharacter(event)) {
      event.preventDefault();
      this.#handleTypeAhead(event, list);
      this.#checkStates();
    }
  }

  #getKeyboardHandler(event) {
    const handlers = {
      " ": this.handleSelection.bind(this),
      Enter: this.#addSelectionByListInput.bind(this),
      Delete: this.#removeSelectionByListInput.bind(this),
      ArrowUp: (event, list) =>
        this.#handleVerticalNavigation(event, list, "up", "single"),
      ArrowDown: (event, list) =>
        this.#handleVerticalNavigation(event, list, "down", "single"),
      Home: (event, list) =>
        this.#handleVerticalNavigation(event, list, "up", "fullList"),
      End: (event, list) =>
        this.#handleVerticalNavigation(event, list, "down", "fullList"),
    };
    if (event.key.toLowerCase() === "a" && (event.ctrlKey || event.metaKey)) {
      return (event, list) => this.#selectAll(event, list);
    }
    return handlers[event.key];
  }

  #isPrintableCharacter(event) {
    return (
      event.key.length === 1 &&
      !event.altKey &&
      !event.ctrlKey &&
      !event.metaKey
    );
  }

  handleSelection(event, list = event.target) {
    const option = this.#ensureActiveListElement(list);
    if (!option) return;

    if (event.shiftKey) {
      this.#selectRangeFromAnchorToOption(list, option);
    } else {
      this.#selectOrUnselectOption(option);
    }
  }

  #selectOrUnselectOption(option) {
    const selected = option.getAttribute("aria-selected");
    if (selected === this.constructor.ARIA_SELECTED_FALSE) {
      this.#addSelectedAttributes(option);
      this.#lastSelectedAnchor = option;
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

  #selectRangeFromAnchorToOption(list, option) {
    const listOptions = Array.from(list.querySelectorAll("li"));
    const anchor =
      this.#lastSelectedAnchor?.parentNode === list
        ? this.#lastSelectedAnchor
        : option;
    const anchorIndex = listOptions.indexOf(anchor);
    const optionIndex = listOptions.indexOf(option);

    this.#selectOptionRange(anchorIndex, optionIndex, listOptions);
    this.#lastSelectedAnchor = anchor;
  }

  #addSelectionByListInput(_event, list) {
    if (list != this.availableList) return;
    this.#performSelection(true, true, this.availableList, this.selectedList);
  }

  addSelectionByAddButton() {
    if (!this.#isDisabled(this.addButtonTarget)) {
      this.#performSelection(
        false,
        false,
        this.availableList,
        this.selectedList,
      );
    }
  }

  #removeSelectionByListInput(_event, list) {
    if (list != this.selectedList) return;
    this.#performSelection(true, true, this.selectedList, this.availableList);
  }

  removeSelectionByRemoveButton() {
    if (!this.#isDisabled(this.removeButtonTarget)) {
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

    const selectedOptionsText = [];
    if (selectedOptions.length === 0) return;

    for (let i = 0; i < selectedOptions.length; i++) {
      selectedOptionsText.push(selectedOptions[i].lastElementChild.textContent);
      this.#removeSelectedAttributes(selectedOptions[i]);
      targetList.appendChild(selectedOptions[i]);
    }

    this.#updateListAfterMutation(sourceList, focusTarget);
    this.#updateListAfterMutation(targetList, selectedOptions[0]);

    if (isKeyDown) {
      sourceList.focus();
    }

    const translationKey = selectedOptions.length > 1 ? "multiple" : "single";
    const listName =
      sourceList === this.selectedList
        ? this.#availableListName
        : this.#selectedListName;

    this.#updateAriaLive(
      `moved_list_${translationKey}`,
      listName,
      selectedOptionsText,
    );

    this.#checkStates();
  }

  #getFocusTargetAfterSelection(list) {
    const currentFocusedElement = this.#getActiveListElement(list);
    if (!currentFocusedElement) return null;

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
      return null;
    }
    return currentFocusedElement;
  }

  // handles going up and down list via keyboard (ArrowUp, ArrowDown, Home, End)
  #handleVerticalNavigation(event, currentList, direction, navigateSize) {
    const currentOption = this.#ensureActiveListElement(currentList);
    if (!currentOption) return;

    if (event.ctrlKey && event.shiftKey && navigateSize === "fullList") {
      const listOptions = Array.from(currentList.querySelectorAll("li"));
      const currentIndex = listOptions.indexOf(currentOption);
      const endpointIndex = direction === "up" ? 0 : listOptions.length - 1;
      this.#selectOptionRange(currentIndex, endpointIndex, listOptions);
      this.#lastSelectedAnchor = currentOption;
      return;
    }

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
      currentOption.getAttribute("aria-selected") ===
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
          ? currentOption.previousElementSibling
          : currentOption.nextElementSibling
        : direction === "up"
          ? currentList.firstElementChild
          : currentList.lastElementChild;
    this.#navigateListHorizontally(
      direction === "up" ? "up" : "down",
      targetOption,
      selectedOption,
      event,
      currentList,
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
  #navigateListHorizontally(
    direction,
    targetOption,
    selectedOption,
    event,
    currentList,
  ) {
    // return if no target option (eg: keyboard ArrowUp when already on the top option)
    if (!targetOption) return;
    // user is moving an option up/down list
    if (selectedOption) {
      this.#moveOptionHorizontally(selectedOption, targetOption, direction);
      this.#setActiveListElement(currentList, selectedOption);
    } else {
      //  user is selecting items by Shift+ArrowUp/Down
      if (event.shiftKey) {
        this.#selectOrUnselectOption(targetOption);
      }
      this.#setActiveListElement(currentList, targetOption);
    }

    this.#checkStates();
  }

  #moveOptionHorizontally(selectedOption, targetOption, direction) {
    const listName =
      selectedOption.parentElement === this.selectedList
        ? this.#selectedListName
        : this.#availableListName;
    targetOption.remove();
    selectedOption.insertAdjacentElement(
      direction === "up" ? "afterend" : "beforebegin",
      targetOption,
    );

    this.#updateAriaLive(
      direction === "up" ? "move_up" : "move_down",
      listName,
      selectedOption.lastElementChild.textContent,
    );
  }

  // handles up and down buttons
  moveSelection(event) {
    if (this.#isDisabled(event.target)) return;

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
      this.selectedList,
    );
  }

  // handles normal click and shift click events
  handleClick(event) {
    const option = event.target.closest('li[role="option"]');
    if (!option || !this.#isListbox(option.parentNode)) return;

    if (event.shiftKey) {
      this.#handleShiftClick(option);
    } else {
      this.#lastClickedOption = option;
      this.#selectOrUnselectOption(option);
    }
    this.#setActiveListElement(option.parentNode, option);
    option.parentNode.focus();
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
    this.#lastSelectedAnchor = this.#lastClickedOption;
  }

  #selectAll(event, listNode = event.target) {
    if (!event.ctrlKey && !event.metaKey) return;
    const allOptions = listNode.querySelectorAll("li");
    const unselectedOptions = listNode.querySelectorAll(
      `li[aria-selected="${this.constructor.ARIA_SELECTED_FALSE}"]`,
    );
    // if everything is selected, unselect
    // else select all
    if (unselectedOptions.length == 0) {
      this.#unselectListOptions(listNode);
    } else {
      for (let i = 0; i < allOptions.length; i++) {
        if (
          allOptions[i].getAttribute("aria-selected") ===
          this.constructor.ARIA_SELECTED_FALSE
        ) {
          this.#addSelectedAttributes(allOptions[i]);
        }
      }
      this.#lastSelectedAnchor = allOptions[0];
    }
  }

  #handleTypeAhead(event, list) {
    const state = this.#typeAheadState.get(list) ?? {
      search: "",
      timeout: null,
    };

    clearTimeout(state.timeout);
    state.search = `${state.search}${event.key}`.toLowerCase();
    state.timeout = setTimeout(() => {
      state.search = "";
    }, this.constructor.TYPE_AHEAD_TIMEOUT);
    this.#typeAheadState.set(list, state);

    this.#focusNextMatchingOption(list, state.search);
  }

  #focusNextMatchingOption(list, search) {
    const options = Array.from(list.querySelectorAll("li"));
    const currentOption = this.#getActiveListElement(list);
    const currentIndex = options.indexOf(currentOption);
    const orderedOptions = [
      ...options.slice(currentIndex + 1),
      ...options.slice(0, currentIndex + 1),
    ];
    const matchingOption = orderedOptions.find((option) =>
      option.lastElementChild.textContent
        .trim()
        .toLowerCase()
        .startsWith(search),
    );

    if (matchingOption) {
      this.#setActiveListElement(list, matchingOption);
    }
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
    option.firstElementChild.replaceWith(checkmark);
    option.setAttribute("aria-selected", this.constructor.ARIA_SELECTED_TRUE);
  }

  // remove checkmark from option
  #removeSelectedAttributes(option) {
    const hiddenCheckmark =
      this.hiddenCheckmarkTemplateTarget.content.cloneNode(true);
    option.firstElementChild.replaceWith(hiddenCheckmark);
    option.setAttribute("aria-selected", this.constructor.ARIA_SELECTED_FALSE);
  }

  // used for dynamic/changing listing values
  updateMetadataListing({ detail: { content } }) {
    const newMetadata = content["metadata"];
    const existingMetadata = { available: [], selected: [] };

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

    // add new metadata to the selected list
    const selectedMetadata = existingMetadata["selected"].concat(newMetadata);

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
    const id = `list_item_${crypto.randomUUID()}`;
    const template = this.itemTemplateTarget.content.cloneNode(true);
    template.querySelector("li").lastElementChild.textContent = element;
    template.querySelector("li").id = id;
    list.append(template);
  }

  #updateAriaLive(translationKey, list, items) {
    this.#ensureAriaLiveReady();
    const connectedItems = this.#wordConnector.connectWords(items);
    const updateString = this.#ariaLiveTranslations[translationKey]
      .replace(/LIST_PLACEHOLDER/g, list)
      .replace(/ITEMS_PLACEHOLDER/g, connectedItems);

    announce(updateString, { element: this.ariaLiveUpdateTarget });
  }

  #initializeLists() {
    this.#initializeList(this.availableList);
    this.#initializeList(this.selectedList);
  }

  #initializeList(list) {
    list.tabIndex = 0;
    if (!list.firstElementChild) {
      list.setAttribute("aria-activedescendant", "");
    }
  }

  #ensureActiveListElement(list) {
    const currentOption = this.#getActiveListElement(list);
    if (currentOption) {
      this.#setActiveListElement(list, currentOption);
      return currentOption;
    }

    const selectedOption = this.#getSelectedOptions(list)[0];
    const option = selectedOption ?? list.firstElementChild;
    this.#setActiveListElement(list, option);
    return option;
  }

  #getActiveListElement(list) {
    const cached = this.#activeOptionCache.get(list);
    if (cached?.parentNode === list) return cached;

    if (cached) {
      this.#clearActiveOption(cached);
    }
    this.#activeOptionCache.delete(list);
    return null;
  }

  #clearActiveOption(option) {
    option.removeAttribute("data-active-option");
  }

  #clearActiveListElement(list) {
    const currentOption = this.#getActiveListElement(list);
    if (currentOption) {
      this.#clearActiveOption(currentOption);
    }
  }

  #setActiveListElement(list, option) {
    const previousOption = this.#getActiveListElement(list);
    if (previousOption && previousOption !== option) {
      this.#clearActiveOption(previousOption);
    }

    if (!option) {
      list.setAttribute("aria-activedescendant", "");
      this.#activeOptionCache.delete(list);
      return;
    }

    list.setAttribute("aria-activedescendant", option.id);
    this.#activeOptionCache.set(list, option);
    option.setAttribute("data-active-option", "true");

    if (typeof option.scrollIntoView === "function") {
      option.scrollIntoView({ block: "nearest" });
    }
  }

  #checkStates() {
    this.#checkButtonStates();
    if (this.hasTemplateSelectorTarget) {
      this.#checkTemplateSelectorState();
      this.#cleanupAvailableList();
    }
  }

  #updateListAfterMutation(list, preferredOption = null) {
    if (document.activeElement !== list) {
      return;
    }

    if (!list.firstElementChild) {
      this.#setActiveListElement(list, null);
      return;
    }

    if (preferredOption?.parentNode === list) {
      this.#setActiveListElement(list, preferredOption);
    }
  }

  #isListbox(element) {
    return (
      element === this.availableList ||
      element === this.selectedList ||
      element?.getAttribute("role") === "listbox"
    );
  }

  // Capture-phase handler: aria-disabled does not natively prevent form
  // submission, so we intercept clicks before they reach the form.
  #onSubmitClickCapture(event) {
    if (!this.hasSubmitBtnTarget) return;
    if (!this.#isDisabled(this.submitBtnTarget)) return;
    event.preventDefault();
    event.stopPropagation();
  }
}
