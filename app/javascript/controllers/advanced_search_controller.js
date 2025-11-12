import { Controller } from "@hotwired/stimulus";
import {
  replacePlaceholders,
  findGroup,
  findCondition,
  getConditions,
  getGroupIndex,
  getConditionIndex,
  reindexConditions,
  reindexGroups,
  parseJSONDataAttribute,
  isEnumField,
  createEnumSelect,
} from "utilities/advanced_search";

export default class extends Controller {
  // ====================================================================
  // Stimulus Configuration
  // ====================================================================
  static targets = [
    "conditionsContainer",
    "conditionTemplate",
    "groupsContainer",
    "groupTemplate",
    "listValueTemplate",
    "searchGroupsContainer",
    "searchGroupsTemplate",
    "validationStatus",
    "valueTemplate",
  ];

  static outlets = ["list-filter"];

  static values = {
    confirmCloseText: String,
    open: Boolean,
    validationErrorOne: String,
    validationErrorOther: String,
  };

  #hiddenClasses = ["invisible", "@max-xl:hidden"];

  // ====================================================================
  // Lifecycle
  // ====================================================================
  connect() {
    // Render the search if openValue is true on connect
    if (this.openValue) {
      this.renderSearch();
    }
    this.#announceValidationErrors();
  }

  renderSearch() {
    this.searchGroupsContainerTarget.innerHTML =
      this.searchGroupsTemplateTarget.innerHTML;
    this.#toggleRemoveGroupButtons();
  }

  // ====================================================================
  // Public Actions
  // ====================================================================
  clear() {
    this.searchGroupsContainerTarget.innerHTML = "";
  }

  clearForm() {
    this.clear();
    this.addGroup();
  }

  /**
   * Close the advanced search dialog, confirming if the form is dirty.
   * @param {Event} event
   */
  close(event) {
    if (!(event instanceof KeyboardEvent) && event.type === "keydown") {
      event.preventDefault();
      event.stopImmediatePropagation();
      return;
    }

    if (!this.#dirty()) {
      this.clear();
      return;
    }

    if (window.confirm(this.confirmCloseTextValue)) {
      this.clear();
    } else {
      event.stopImmediatePropagation();
      event.preventDefault();
    }
  }

  /**
   * Add a new condition to the target group.
   * @param {Event} event
   */
  addCondition(event) {
    const group = findGroup(event.currentTarget);
    if (!group) return;

    this.#addConditionToGroup(group);
  }

  /**
   * Remove the condition fieldset and reindex remaining conditions.
   * @param {Event} event
   */
  removeCondition(event) {
    const condition = findCondition(event.currentTarget);
    if (!condition) return;

    const group = findGroup(condition);
    if (!group) return;

    condition.remove();
    const conditions = reindexConditions(group);

    if (conditions.length === 0) {
      this.#addConditionToGroup(group);
    } else {
      conditions.at(-1)?.querySelector("select")?.focus();
    }
  }

  /**
   * Append a new group to the search builder dialog.
   */
  addGroup() {
    const groupIndex = this.groupsContainerTargets.length;
    const groupHTML = replacePlaceholders(this.groupTemplateTarget.innerHTML, {
      GROUP_INDEX_PLACEHOLDER: groupIndex,
      GROUP_LEGEND_INDEX_PLACEHOLDER: groupIndex + 1,
    });

    this.searchGroupsContainerTarget.insertAdjacentHTML("beforeend", groupHTML);

    const group = this.groupsContainerTargets[groupIndex];
    if (!group) return;

    const conditionHTML = replacePlaceholders(
      this.conditionTemplateTarget.innerHTML,
      {
        GROUP_INDEX_PLACEHOLDER: groupIndex,
        CONDITION_INDEX_PLACEHOLDER: 0,
        CONDITION_LEGEND_INDEX_PLACEHOLDER: 1,
      },
    );

    group.insertAdjacentHTML("afterbegin", conditionHTML);
    group.querySelector("select")?.focus();

    this.#toggleRemoveGroupButtons();
  }

  /**
   * Remove a group if multiple groups exist.
   * @param {Event} event
   */
  removeGroup(event) {
    if (this.groupsContainerTargets.length <= 1) return;

    const group = findGroup(event.currentTarget);
    if (!group) return;

    group.remove();
    const groups = this.groupsContainerTargets;

    reindexGroups(groups);
    groups.at(-1)?.querySelector("select")?.focus();

    this.#toggleRemoveGroupButtons();
  }

  /**
   * Update operator and value inputs when the field select changes.
   * @param {Event} event
   */
  handleFieldChange(event) {
    const condition = findCondition(event.currentTarget);
    if (!condition) return;

    const selectedField = event.currentTarget.value;
    this.#updateOperatorDropdown(condition, selectedField);

    const operatorSelect = condition.querySelector(
      "select[name$='[operator]']",
    );
    const operator = operatorSelect?.value || "";

    if (operator && !["", "exists", "not_exists"].includes(operator)) {
      const valueContainer = condition.querySelector(".value");
      if (valueContainer && selectedField) {
        this.#updateValueFieldForEnum(
          valueContainer,
          condition,
          selectedField,
          operator,
        );
      }
    }
  }

  /**
   * Adjust value inputs when the operator changes.
   * @param {Event} event
   */
  handleOperatorChange(event) {
    const condition = findCondition(event.currentTarget);
    if (!condition) return;

    const operator = event.target.value;
    const valueContainer = condition.querySelector(".value");
    if (!valueContainer) return;

    const group = findGroup(condition);
    if (!group) return;

    const groupIndex = getGroupIndex(group, this.groupsContainerTargets);
    const conditionIndex = getConditionIndex(condition);
    const selectedField = this.#selectedField(condition);

    if (["", "exists", "not_exists"].includes(operator)) {
      this.#clearValueInputs(valueContainer);
      valueContainer.classList.add(...this.#hiddenClasses);
      return;
    }

    let updatedValue = valueContainer;
    if (["in", "not_in"].includes(operator)) {
      updatedValue = this.#swapValueTemplate(
        condition,
        this.listValueTemplateTarget,
        {
          groupIndex,
          conditionIndex,
        },
      );
    } else {
      updatedValue = this.#swapValueTemplate(
        condition,
        this.valueTemplateTarget,
        {
          groupIndex,
          conditionIndex,
        },
      );
    }

    if (!updatedValue) return;

    this.#updateValueFieldForEnum(
      updatedValue,
      condition,
      selectedField,
      operator,
    );
  }

  // ====================================================================
  // Private Helpers
  // ====================================================================

  /**
   * Insert a new condition into the provided group.
   * @param {HTMLElement} group
   */
  #addConditionToGroup(group) {
    const groupIndex = getGroupIndex(group, this.groupsContainerTargets);
    const conditionIndex = getConditions(group).length;

    const conditionHTML = replacePlaceholders(
      this.conditionTemplateTarget.innerHTML,
      {
        GROUP_INDEX_PLACEHOLDER: groupIndex,
        CONDITION_INDEX_PLACEHOLDER: conditionIndex,
        CONDITION_LEGEND_INDEX_PLACEHOLDER: conditionIndex + 1,
      },
    );

    group.lastElementChild.insertAdjacentHTML("beforebegin", conditionHTML);

    const conditions = getConditions(group);
    conditions[conditionIndex]?.querySelector("select")?.focus();
  }

  /**
   * Swap the markup inside a condition's value container with a rendered template.
   * @param {HTMLElement} condition
   * @param {HTMLElement} templateTarget
   * @param {{groupIndex: number, conditionIndex: number}} context
   * @returns {HTMLElement|null}
   */
  #swapValueTemplate(
    condition,
    templateTarget,
    { groupIndex, conditionIndex },
  ) {
    const valueContainer = condition.querySelector(".value");
    if (!valueContainer) return null;

    const group = findGroup(condition);
    if (!group) return null;

    const template = replacePlaceholders(templateTarget.innerHTML, {
      GROUP_INDEX_PLACEHOLDER: groupIndex,
      CONDITION_INDEX_PLACEHOLDER: conditionIndex,
    });

    valueContainer.outerHTML = template;

    const updatedCondition = getConditions(group)[conditionIndex];
    const updatedValue = updatedCondition?.querySelector(".value") || null;

    updatedValue?.classList.remove(...this.#hiddenClasses);
    return updatedValue;
  }

  /**
   * Update the operator select with the appropriate options for the field.
   * @param {HTMLElement} condition
   * @param {string} selectedField
   */
  #updateOperatorDropdown(condition, selectedField) {
    if (!selectedField) return;

    const enumFields = parseJSONDataAttribute(condition, "enumFields") || {};
    const enumOperations =
      parseJSONDataAttribute(condition, "enumOperations") || {};
    const standardOperations =
      parseJSONDataAttribute(condition, "standardOperations") || {};

    const operatorSelect = condition.querySelector(
      "select[name$='[operator]']",
    );
    if (!operatorSelect) return;

    const operations = isEnumField(enumFields, selectedField)
      ? enumOperations
      : standardOperations;

    const currentValue = operatorSelect.value;
    operatorSelect.innerHTML = "";

    const blankOption = document.createElement("option");
    blankOption.value = "";
    blankOption.text = "";
    operatorSelect.appendChild(blankOption);

    Object.entries(operations).forEach(([label, value]) => {
      const option = document.createElement("option");
      option.value = value;
      option.text = label;
      operatorSelect.appendChild(option);
    });

    if (currentValue && Object.values(operations).includes(currentValue)) {
      operatorSelect.value = currentValue;
    }
  }

  /**
   * Convert enum field configuration into a select element when necessary.
   * @param {HTMLElement} valueContainer
   * @param {HTMLElement} condition
   * @param {string} selectedField
   * @param {string} operator
   */
  #updateValueFieldForEnum(valueContainer, condition, selectedField, operator) {
    if (!valueContainer || !selectedField) return;

    const enumConfig = this.#enumConfig(condition, selectedField);
    if (!enumConfig) return;

    const isListOperator = ["in", "not_in"].includes(operator);
    const currentInput = this.#currentEnumInput(valueContainer, isListOperator);
    if (!currentInput) return;

    const inputName = this.#enumInputName(currentInput, isListOperator);
    if (!inputName) return;

    const select = createEnumSelect({
      name: inputName,
      id: currentInput.id,
      className: currentInput.className || "",
      ariaLabel: this.#valueAriaLabel(valueContainer),
      multiple: isListOperator,
      labels: enumConfig.labels || {},
      values: enumConfig.values || [],
    });

    currentInput.replaceWith(select);
  }

  /**
   * Retrieve enum configuration for the selected field.
   * @param {HTMLElement} condition
   * @param {string} selectedField
   * @returns {Object|null}
   */
  #enumConfig(condition, selectedField) {
    const enumFields = parseJSONDataAttribute(condition, "enumFields") || {};
    return enumFields[selectedField] || null;
  }

  /**
   * Locate the current input element to replace with a select.
   * @param {HTMLElement} valueContainer
   * @param {boolean} isListOperator
   * @returns {HTMLElement|null}
   */
  #currentEnumInput(valueContainer, isListOperator) {
    if (isListOperator) {
      return valueContainer.querySelector("div[data-controller='list-filter']");
    }
    return valueContainer.querySelector("input[name$='[value]']");
  }

  /**
   * Determine the correct name attribute to apply to the generated select.
   * @param {HTMLElement} currentInput
   * @param {boolean} isListOperator
   * @returns {string|null}
   */
  #enumInputName(currentInput, isListOperator) {
    if (isListOperator) {
      const hiddenInput = currentInput.querySelector(
        "input[name$='[value][]']",
      );
      return hiddenInput ? hiddenInput.name.replace(/\[\]$/, "") : null;
    }

    return currentInput.name || null;
  }

  /**
   * Extract an accessible label for the generated select element.
   * @param {HTMLElement} valueContainer
   * @returns {string|undefined}
   */
  #valueAriaLabel(valueContainer) {
    const label = valueContainer.querySelector("label");
    return label ? label.textContent.trim() : undefined;
  }

  /**
   * Reset value inputs when operators without value requirements are selected.
   * @param {HTMLElement} valueContainer
   */
  #clearValueInputs(valueContainer) {
    valueContainer.querySelectorAll("input, select").forEach((element) => {
      element.value = "";
      if (element.tagName === "SELECT") {
        element.selectedIndex = -1;
      }
    });
  }

  /**
   * Toggle remove group button visibility based on group count.
   */
  #toggleRemoveGroupButtons() {
    const multipleGroups = this.groupsContainerTargets.length > 1;

    this.groupsContainerTargets.forEach((group) => {
      const button = group.querySelector(
        "div > button[data-action='advanced-search#removeGroup']",
      );
      if (!button) return;

      button.classList.toggle("hidden", !multipleGroups);
    });
  }

  /**
   * Helper to get the currently selected field for a condition.
   * @param {HTMLElement} condition
   * @returns {string}
   */
  #selectedField(condition) {
    const fieldSelect = condition.querySelector("select[name$='[field]']");
    return fieldSelect?.value || "";
  }

  /**
   * Determine if the form contents differ from the original template.
   * @returns {boolean}
   */
  #dirty() {
    if (
      this.searchGroupsContainerTarget.innerHTML.trim() ===
      this.searchGroupsTemplateTarget.innerHTML.trim()
    ) {
      const currentInputs = this.searchGroupsContainerTarget.querySelectorAll(
        "[id^='q_groups_attributes_']",
      );
      const originalInputs =
        this.searchGroupsTemplateTarget.content.querySelectorAll(
          "[id^='q_groups_attributes_']",
        );

      for (let index = 0; index < originalInputs.length; index += 1) {
        if (originalInputs[index].value !== currentInputs[index].value) {
          return true;
        }
      }

      return false;
    }

    return true;
  }

  /**
   * Announce validation errors in the dialog via the live region.
   */
  #announceValidationErrors() {
    if (!this.hasValidationStatusTarget) return;

    const errorElements = this.element.querySelectorAll(
      '[aria-invalid="true"], .invalid',
    );

    if (errorElements.length === 0) return;

    const message =
      errorElements.length === 1
        ? this.validationErrorOneValue
        : this.validationErrorOtherValue.replace(
            "%{count}",
            String(errorElements.length),
          );

    this.validationStatusTarget.textContent = message;
  }
}
