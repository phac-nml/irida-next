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

/**
 * Advanced Search Controller
 *
 * Manages dynamic form building for advanced search queries with groups
 * and conditions. Supports enum fields with dynamic operator options.
 *
 * Features:
 * - Dynamic group and condition management
 * - Enum field support with operator-specific value inputs
 * - Screen reader announcements for accessibility
 * - Form dirty state tracking
 * - Validation error announcements
 *
 * @example
 * <div data-controller="advanced-search"
 *      data-advanced-search-confirm-close-text-value="Discard changes?">
 *   ...
 * </div>
 *
 * @see AdvancedSearchComponent for the server-side component
 */
export default class extends Controller {
  // ====================================================================
  // Stimulus Configuration
  // ====================================================================
  static SELECTORS = {
    operatorSelect: "select[name$='[operator]']",
    fieldSelect: "select[name$='[field]']",
    valueInput: "[name$='[value]']",
    groupInputs: "[id^='q_groups_attributes_']",
    removeGroupButton:
      "div > button[data-action='advanced-search#removeGroup']",
  };

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

  static values = {
    confirmCloseText: String,
    open: Boolean,
    validationErrorOne: String,
    validationErrorOther: String,
    conditionAdded: String,
    conditionRemoved: String,
    groupAdded: String,
    groupRemoved: String,
    searchCleared: String,
  };

  #hiddenClasses = ["invisible", "@max-xl:hidden"];
  #boundBeforeCache = null;

  // ====================================================================
  // Lifecycle
  // ====================================================================
  connect() {
    // Render the search if openValue is true on connect
    if (this.openValue) {
      this.renderSearch();
    }
  }

  disconnect() {
    if (this.#boundBeforeCache) {
      document.removeEventListener(
        "turbo:before-cache",
        this.#boundBeforeCache,
      );
    }
  }

  renderSearch() {
    this.searchGroupsContainerTarget.innerHTML =
      this.searchGroupsTemplateTarget.innerHTML;
    this.#toggleRemoveGroupButtons();
    this.#announceValidationErrors();

    this.#boundBeforeCache = this.#beforeCache.bind(this);
    document.addEventListener("turbo:before-cache", this.#boundBeforeCache);
  }

  /**
   * Reset state before Turbo caches the page.
   */
  #beforeCache() {
    if (this.hasValidationStatusTarget) {
      this.validationStatusTarget.textContent = "";
    }
  }

  // ====================================================================
  // Public Actions
  // ====================================================================
  clear() {
    this.searchGroupsContainerTarget.innerHTML = "";
    this.#announce(this.searchClearedValue);
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

    this.#announce(this.conditionRemovedValue);
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
    this.#announce(this.groupAddedValue);
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
    this.#announce(this.groupRemovedValue);
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
      this.constructor.SELECTORS.operatorSelect,
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

    this.#announce(this.conditionAddedValue);
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
      this.constructor.SELECTORS.operatorSelect,
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
    if (!valueContainer || !selectedField) {
      return;
    }

    const enumConfig = this.#enumConfig(condition, selectedField);
    if (!enumConfig) {
      return;
    }

    const isListOperator = ["in", "not_in"].includes(operator);
    const currentInput = this.#currentEnumInput(valueContainer, isListOperator);
    if (!currentInput) {
      return;
    }

    const inputName = this.#enumInputName(currentInput, isListOperator);
    if (!inputName) return;

    const attributeSource = this.#enumAttributeSource(
      currentInput,
      isListOperator,
    );
    const labelElement = valueContainer.querySelector("label");
    const attributes = this.#enumAttributes({
      valueContainer,
      attributeSource,
      ariaLabel: this.#valueAriaLabel(valueContainer),
      labelElement,
    });
    const className = this.#enumClassName(attributeSource, isListOperator);
    const fieldId =
      labelElement?.getAttribute("for") ||
      attributeSource?.id ||
      currentInput.id;

    const select = createEnumSelect({
      name: inputName,
      id: fieldId,
      className,
      multiple: isListOperator,
      labels: enumConfig.labels || {},
      values: enumConfig.values || [],
      attributes,
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
    try {
      const enumFields = parseJSONDataAttribute(condition, "enumFields") || {};
      return enumFields[selectedField] || null;
    } catch (error) {
      console.error("Failed to parse enum configuration:", error);
      return null;
    }
  }

  /**
   * Locate the current input element to replace with a select.
   * @param {HTMLElement} valueContainer
   * @param {boolean} isListOperator
   * @returns {HTMLElement|null}
   */
  #currentEnumInput(valueContainer, isListOperator) {
    if (isListOperator) {
      return (
        valueContainer.querySelector("select[name$='[value][]']") ||
        valueContainer.querySelector("div[data-controller='list-filter']")
      );
    }

    return (
      valueContainer.querySelector("select[name$='[value]']") ||
      valueContainer.querySelector("input[name$='[value]']")
    );
  }

  /**
   * Determine the element to inspect for attribute transfer when swapping enum inputs.
   * @param {HTMLElement} currentInput
   * @param {boolean} isListOperator
   * @returns {HTMLElement|null}
   */
  #enumAttributeSource(currentInput, isListOperator) {
    if (!currentInput) return null;
    if (currentInput.matches?.("select")) return currentInput;
    if (isListOperator) {
      return currentInput.querySelector("input[name$='[value][]']");
    }
    return currentInput;
  }

  /**
   * Determine the correct name attribute to apply to the generated select.
   * @param {HTMLElement} currentInput
   * @param {boolean} isListOperator
   * @returns {string|null}
   */
  #enumInputName(currentInput, isListOperator) {
    if (isListOperator) {
      if (currentInput.matches?.("select")) {
        return currentInput.name.replace(/\[\]$/, "");
      }

      const hiddenInput = currentInput.querySelector(
        "input[name$='[value][]']",
      );
      return hiddenInput ? hiddenInput.name.replace(/\[\]$/, "") : null;
    }

    if (currentInput.matches?.("select")) {
      return currentInput.name || null;
    }

    return currentInput.name || null;
  }

  /**
   * Determine the CSS classes to apply to the generated select element.
   * @param {HTMLElement|null} attributeSource
   * @param {boolean} isListOperator
   * @returns {string}
   */
  #enumClassName(attributeSource, isListOperator) {
    if (!attributeSource || !attributeSource.className) return "";

    if (isListOperator && !attributeSource.matches?.("select")) return "";

    return attributeSource.className
      .split(" ")
      .filter(
        (token) =>
          token.trim().length > 0 &&
          !["bg-transparent!", "border-none", "grow"].includes(token),
      )
      .join(" ");
  }

  /**
   * Collect accessibility-related attributes to transfer to the generated select.
   * @param {Object} options
   * @param {HTMLElement} options.valueContainer
   * @param {HTMLElement|null} options.attributeSource
   * @param {string|undefined} options.ariaLabel
   * @param {HTMLElement|null} options.labelElement
   * @returns {Record<string, string|boolean>}
   */
  #enumAttributes({
    valueContainer,
    attributeSource,
    ariaLabel,
    labelElement,
  }) {
    const attributes = {};

    const sourceDescribedBy =
      attributeSource?.getAttribute?.("aria-describedby");
    const errorId = this.#valueErrorId(valueContainer);
    if (sourceDescribedBy || errorId) {
      attributes["aria-describedby"] = sourceDescribedBy || errorId;
    }

    const sourceAriaInvalid = attributeSource?.getAttribute?.("aria-invalid");
    if (sourceAriaInvalid) {
      attributes["aria-invalid"] = sourceAriaInvalid;
    } else if (valueContainer.classList.contains("invalid")) {
      attributes["aria-invalid"] = "true";
    }

    const sourceAriaLabel = attributeSource?.getAttribute?.("aria-label");
    if (sourceAriaLabel) {
      attributes["aria-label"] = sourceAriaLabel;
    } else if (ariaLabel) {
      attributes["aria-label"] = ariaLabel;
    }

    if (
      attributeSource?.hasAttribute?.("required") ||
      this.#isRequiredField(labelElement)
    ) {
      attributes.required = true;
    }

    return attributes;
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
   * Determine whether the field is marked as required.
   * @param {HTMLElement|null} labelElement
   * @returns {boolean}
   */
  #isRequiredField(labelElement) {
    return labelElement?.dataset?.required === "true";
  }

  /**
   * Retrieve the id of the associated error element, if present.
   * @param {HTMLElement} valueContainer
   * @returns {string|undefined}
   */
  #valueErrorId(valueContainer) {
    return valueContainer.querySelector("[id$='_error']")?.id;
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
        this.constructor.SELECTORS.removeGroupButton,
      );
      if (!button) return;

      button.classList.toggle("hidden", !multipleGroups);
      button.setAttribute("aria-hidden", !multipleGroups);
      button.tabIndex = multipleGroups ? 0 : -1;
    });
  }

  /**
   * Helper to get the currently selected field for a condition.
   * @param {HTMLElement} condition
   * @returns {string}
   */
  #selectedField(condition) {
    const fieldSelect = condition.querySelector(
      this.constructor.SELECTORS.fieldSelect,
    );
    return fieldSelect?.value || "";
  }

  /**
   * Determine if the form contents differ from the original template.
   * @returns {boolean}
   */
  #dirty() {
    if (!this.#htmlContentMatches()) {
      return true;
    }
    return this.#inputValuesChanged();
  }

  /**
   * Check if the HTML content matches between container and template.
   * @returns {boolean}
   */
  #htmlContentMatches() {
    return (
      this.searchGroupsContainerTarget.innerHTML.trim() ===
      this.searchGroupsTemplateTarget.innerHTML.trim()
    );
  }

  /**
   * Check if any input values have changed from the original template.
   * @returns {boolean}
   */
  #inputValuesChanged() {
    const currentInputs = this.searchGroupsContainerTarget.querySelectorAll(
      this.constructor.SELECTORS.groupInputs,
    );
    const originalInputs =
      this.searchGroupsTemplateTarget.content.querySelectorAll(
        this.constructor.SELECTORS.groupInputs,
      );

    return Array.from(originalInputs).some(
      (original, index) =>
        currentInputs[index] && original.value !== currentInputs[index].value,
    );
  }

  /**
   * Announce a message to screen readers via the live region.
   * @param {string} message
   */
  #announce(message) {
    if (!this.hasValidationStatusTarget || !message) return;
    this.validationStatusTarget.textContent = message;
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
