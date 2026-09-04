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
    "ariaLiveUpdate",
  ];

  static values = {
    selectedList: String,
    availableList: String,
    fieldName: String,
  };

  #originalValues = [];
  #availableListName = "";
  #selectedListName = "";
  #ariaLiveTranslations;
  #wordConnector = null;

  connect() {
    this.idempotentConnect();
  }

  idempotentConnect() {
    this.availableList = document.getElementById(this.availableListValue);
    this.selectedList = document.getElementById(this.selectedListValue);

    if (!this.availableList || !this.selectedList) return;

    this.#availableListName =
      this.availableList.getAttribute("data-title") || "";
    this.#selectedListName = this.selectedList.getAttribute("data-title") || "";
    this.#originalValues = this.#collectAllValues();

    this.#checkStates();
  }

  handleSelectionChange() {
    this.#checkStates();
  }

  constructParams() {
    if (!this.hasFieldTarget) return;

    this.fieldTarget.replaceChildren(
      ...this.#listValues(this.selectedList).map((value) =>
        createHiddenInput(this.fieldNameValue, value),
      ),
    );
  }

  setTemplate(event) {
    const selector = event?.target;
    const selectedOption = selector?.options?.[selector.selectedIndex];

    if (!selector || !selectedOption) return;

    this.#renderValues(this.availableList, this.#originalValues);
    this.#renderValues(this.selectedList, []);

    if (selector.value === "none") {
      this.#checkStates();
      return;
    }

    const fields = JSON.parse(selectedOption.dataset.fields || "[]");

    fields.forEach((field) => {
      const existingItem = this.#listItemByValue(this.availableList, field);
      if (existingItem) {
        this.selectedList.append(existingItem);
      } else {
        const item = this.#buildListItem(field, this.selectedList.id);
        if (item) this.selectedList.append(item);
      }
    });

    this.#checkStates();
  }

  addSelectionByAddButton() {
    if (
      !this.hasAddButtonTarget ||
      this.#buttonDisabled(this.addButtonTarget)
    ) {
      return;
    }

    this.#moveCheckedOptions(this.availableList, this.selectedList);
  }

  removeSelectionByRemoveButton() {
    if (
      !this.hasRemoveButtonTarget ||
      this.#buttonDisabled(this.removeButtonTarget)
    ) {
      return;
    }

    this.#moveCheckedOptions(this.selectedList, this.availableList);
  }

  moveSelection(event) {
    if (!this.hasUpButtonTarget || !this.hasDownButtonTarget) return;

    const isMoveUp = event.target === this.upButtonTarget;
    const activeButton = isMoveUp ? this.upButtonTarget : this.downButtonTarget;
    if (this.#buttonDisabled(activeButton)) return;

    const checkedItems = this.#checkedListItems(this.selectedList);
    if (checkedItems.length !== 1) return;

    const selectedItem = checkedItems[0];
    const targetItem = isMoveUp
      ? selectedItem.previousElementSibling
      : selectedItem.nextElementSibling;

    if (!targetItem) return;

    if (isMoveUp) {
      targetItem.before(selectedItem);
    } else {
      targetItem.after(selectedItem);
    }

    const values = this.#listValues(this.selectedList);
    const movedValue = selectedItem.querySelector(
      'input[type="checkbox"]',
    )?.value;

    this.#updateAriaLive(
      isMoveUp ? "move_up" : "move_down",
      this.#selectedListName,
      movedValue,
      values.indexOf(movedValue) + 1,
    );

    this.#checkStates();

    // Keep focus on the reorder control while it stays actionable; otherwise move
    // focus to the reordered item so keyboard users are not stranded on a
    // now-unavailable button.
    if (this.#buttonDisabled(activeButton)) {
      this.#focusListItem(selectedItem);
    }
  }

  updateMetadataListing({ detail: { content } }) {
    const metadata = content?.metadata;
    if (!Array.isArray(metadata)) return;

    const availableValues = this.#listValues(this.availableList);
    const selectedValues = this.#listValues(this.selectedList);

    const existingAvailable = availableValues.filter((value) =>
      metadata.includes(value),
    );
    const existingSelected = selectedValues.filter((value) =>
      metadata.includes(value),
    );
    const newValues = metadata.filter(
      (value) =>
        !existingAvailable.includes(value) && !existingSelected.includes(value),
    );

    this.#renderValues(this.availableList, existingAvailable);
    this.#renderValues(this.selectedList, [...existingSelected, ...newValues]);

    this.#originalValues = this.#collectAllValues();
    this.#checkStates();
  }

  #moveCheckedOptions(sourceList, targetList) {
    const selectedItems = this.#checkedListItems(sourceList);
    if (selectedItems.length === 0) return;

    const [firstMovedItem] = selectedItems;
    const movedValues = [];
    selectedItems.forEach((item) => {
      const checkbox = item.querySelector('input[type="checkbox"]');
      // Defensive no-op: checked items are derived from their checkbox, so the
      // enclosing <li> always contains one.
      /* v8 ignore next */
      if (!checkbox) return;

      movedValues.push(checkbox.value);
      checkbox.checked = false;
      targetList.append(item);
    });

    const targetListName =
      targetList === this.selectedList
        ? this.#selectedListName
        : this.#availableListName;

    this.#updateAriaLive(
      movedValues.length > 1 ? "moved_list_multiple" : "moved_list_single",
      targetListName,
      movedValues,
    );

    this.#checkStates();

    // Move focus to the transferred item in its destination list so keyboard and
    // screen reader users are not stranded on the now-disabled trigger button.
    this.#focusListItem(firstMovedItem);
  }

  #checkStates() {
    if (!this.availableList || !this.selectedList) return;

    const availableCheckedCount = this.#checkedListItems(
      this.availableList,
    ).length;
    const selectedCheckedItems = this.#checkedListItems(this.selectedList);
    const selectedValues = this.#listValues(this.selectedList);

    if (this.hasAddButtonTarget) {
      this.#setButtonState(this.addButtonTarget, availableCheckedCount === 0);
    }

    if (this.hasRemoveButtonTarget) {
      this.#setButtonState(
        this.removeButtonTarget,
        selectedCheckedItems.length === 0,
      );
    }

    if (this.hasUpButtonTarget && this.hasDownButtonTarget) {
      const canReorder = selectedCheckedItems.length === 1;
      const selectedValue = selectedCheckedItems[0]?.querySelector(
        'input[type="checkbox"]',
      )?.value;
      const selectedIndex = selectedValues.indexOf(selectedValue);

      this.#setButtonState(
        this.upButtonTarget,
        !canReorder || selectedIndex <= 0,
      );
      this.#setButtonState(
        this.downButtonTarget,
        !canReorder || selectedIndex === selectedValues.length - 1,
      );
    }

    if (this.hasSubmitBtnTarget) {
      const isRequired = this.selectedList.dataset.required === "true";
      this.submitBtnTarget.disabled = isRequired && selectedValues.length === 0;
    }

    if (this.hasTemplateSelectorTarget) {
      this.#syncTemplateSelector();
    }
  }

  #syncTemplateSelector() {
    const selectedValues = JSON.stringify(this.#listValues(this.selectedList));

    if (selectedValues === "[]") {
      this.templateSelectorTarget.value = "none";
      return;
    }

    const matchingTemplate = Array.from(
      this.templateSelectorTarget.options,
    ).find((option) => {
      if (!option.dataset.fields) return false;
      return (
        JSON.stringify(JSON.parse(option.dataset.fields)) === selectedValues
      );
    });

    this.templateSelectorTarget.value = matchingTemplate?.value ?? "none";
  }

  #setButtonState(button, isDisabled) {
    // Use aria-disabled (not the native disabled attribute) so the control stays
    // focusable and discoverable; activation is prevented in the action handlers.
    button.setAttribute("aria-disabled", isDisabled ? "true" : "false");
  }

  #buttonDisabled(button) {
    return !button || button.getAttribute("aria-disabled") === "true";
  }

  #focusListItem(item) {
    item?.querySelector('input[type="checkbox"]')?.focus();
  }

  #collectAllValues() {
    const values = [];

    [this.availableList, this.selectedList].forEach((list) => {
      this.#listValues(list).forEach((value) => {
        if (!values.includes(value)) {
          values.push(value);
        }
      });
    });

    return values;
  }

  #listValues(list) {
    return Array.from(list.querySelectorAll('input[type="checkbox"]')).map(
      (checkbox) => checkbox.value,
    );
  }

  #checkedListItems(list) {
    return Array.from(
      list.querySelectorAll('input[type="checkbox"]:checked'),
    ).map((checkbox) => checkbox.closest("li"));
  }

  #listItemByValue(list, value) {
    return this.#checkedOrUncheckedCheckboxForValue(list, value)?.closest("li");
  }

  #checkedOrUncheckedCheckboxForValue(list, value) {
    return Array.from(list.querySelectorAll('input[type="checkbox"]')).find(
      (checkbox) => checkbox.value === value,
    );
  }

  #renderValues(list, values) {
    list.replaceChildren(
      ...values
        .map((value) => this.#buildListItem(value, list.id))
        .filter(Boolean),
    );
  }

  #buildListItem(value, listId) {
    if (!this.hasItemTemplateTarget) return null;

    const item = this.itemTemplateTarget.content
      .querySelector("li")
      ?.cloneNode(true);
    const label = item?.querySelector("label");
    const checkbox = item?.querySelector('input[type="checkbox"]');
    const text = label?.querySelector("span");

    if (!item || !label || !checkbox || !text) return null;

    const checkboxId = this.#buildCheckboxId(listId);

    label.setAttribute("for", checkboxId);
    checkbox.id = checkboxId;
    checkbox.value = value;
    checkbox.checked = false;
    text.textContent = value;

    return item;
  }

  #buildCheckboxId(listId) {
    const uniqueId =
      typeof crypto !== "undefined" && typeof crypto.randomUUID === "function"
        ? crypto.randomUUID()
        : Math.random().toString(16).slice(2);

    return `${listId}-item-${uniqueId}`;
  }

  #ensureAriaLiveReady() {
    if (!this.#ariaLiveTranslations && this.hasAriaLiveUpdateTarget) {
      this.#ariaLiveTranslations = JSON.parse(
        this.ariaLiveUpdateTarget.getAttribute("data-translations"),
      );

      this.#wordConnector = new WordConnector({
        wordsConnector: this.#ariaLiveTranslations.words_connector,
        twoWordsConnector: this.#ariaLiveTranslations.two_words_connector,
        lastWordConnector: this.#ariaLiveTranslations.last_word_connector,
      });
    }

    return Boolean(
      this.#ariaLiveTranslations &&
      this.#wordConnector &&
      this.hasAriaLiveUpdateTarget,
    );
  }

  #updateAriaLive(translationKey, list, items, position = null) {
    if (!this.#ensureAriaLiveReady()) return;

    const connectedItems = this.#wordConnector.connectWords(items);

    let updateString;
    if (["move_up", "move_down"].includes(translationKey)) {
      updateString = this.#ariaLiveTranslations[translationKey]
        .replace(/LIST_PLACEHOLDER/g, list)
        .replace(/ITEM_PLACEHOLDER/g, connectedItems)
        .replace(/POSITION_PLACEHOLDER/g, position);
    } else {
      updateString = this.#ariaLiveTranslations[translationKey]
        .replace(/LIST_PLACEHOLDER/g, list)
        .replace(/ITEMS_PLACEHOLDER/g, connectedItems);
    }

    announce(updateString, { element: this.ariaLiveUpdateTarget });
  }
}
