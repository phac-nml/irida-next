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
import { announce } from "utilities/live_region";

/**
 * Advanced Search Controller
 *
 * Manages dynamic form building for advanced search queries with groups
 * and conditions. Supports enum fields with dynamic operator options.
 *
 * Features:
 * - Dynamic group and condition management
 * - Enum field support with operator-specific value inputs
 * - Form dirty state tracking
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
    fieldSelect: "select[name$='[field]'], input[name$='[field]']",
    valueInput: "[name$='[value]']",
    groupInputs: "[id^='q_groups_attributes_']",
    removeGroupButton:
      "div > button[data-action='advanced-search#removeGroup']",
  };

  static HIDDEN_CLASSES = ["invisible", "@max-xl:hidden"];

  static targets = [
    "conditionsContainer",
    "conditionTemplate",
    "groupsContainer",
    "groupTemplate",
    "listValueTemplate",
    "searchGroupsContainer",
    "searchGroupsTemplate",
    "statusAnnouncement",
    "validationStatus",
    "valueTemplate",
  ];

  static values = {
    confirmCloseText: String,
    open: Boolean,
    groupAddedMessage: { type: String, default: "Search group added" },
    groupRemovedMessage: { type: String, default: "Search group removed" },
    conditionAddedMessage: { type: String, default: "Condition added" },
    conditionRemovedMessage: { type: String, default: "Condition removed" },
    formClearedMessage: { type: String, default: "Search form cleared" },
  };

  // ====================================================================
  // Lifecycle
  // ====================================================================

  /**
   * Initialize the controller on connection.
   * Renders the search form from the template if the dialog is open.
   */
  connect() {
    // Render the search if openValue is true on connect
    if (this.openValue) {
      this.renderSearch();
    }

    this.boundAutoCompleteChange = this.#handleAutoCompleteChange.bind(this);
    this.element.addEventListener(
      "select-with-auto-complete:change",
      this.boundAutoCompleteChange,
    );
  }

  disconnect() {
    this.element.removeEventListener(
      "select-with-auto-complete:change",
      this.boundAutoCompleteChange,
    );
  }

  /**
   * Render the search groups from the template into the container.
   * Updates remove group button visibility based on group count.
   */
  renderSearch() {
    this.searchGroupsContainerTarget.innerHTML =
      this.searchGroupsTemplateTarget.innerHTML;
    this.#toggleRemoveGroupButtons();
  }

  // ====================================================================
  // Public Actions
  // ====================================================================

  /**
   * Clear all search groups from the container.
   */
  clear() {
    this.searchGroupsContainerTarget.innerHTML = "";
  }

  /**
   * Clear the form and reset to a single empty group with one condition.
   * Announces the action to screen readers.
   */
  clearForm() {
    this.clear();
    this.addGroup();
    this.#announce(this.formClearedMessageValue);
  }

  /**
   * Close the advanced search dialog, confirming if the form is dirty.
   * Prevents non-keyboard events from triggering keydown handlers.
   * If the form has unsaved changes, prompts the user before closing.
   *
   * @param {Event} event - The closing event (typically keydown or click)
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
   * Add a new condition to the group containing the trigger element.
   * Focuses the newly added condition's field select.
   * Announces the action to screen readers.
   *
   * @param {Event} event - Event triggered by the add condition button
   */
  addCondition(event) {
    const group = findGroup(event.currentTarget);
    if (!group) return;

    this.#addConditionToGroup(group);
    this.#announce(this.conditionAddedMessageValue);
  }

  /**
   * Remove a condition from its group and reindex remaining conditions.
   * If the group becomes empty, adds a new condition to maintain at least one.
   * Focuses the last condition's select after removal.
   * Announces the action to screen readers.
   *
   * @param {Event} event - Event triggered by the remove condition button
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

    this.#announce(this.conditionRemovedMessageValue);
  }

  /**
   * Append a new search group to the dialog.
   * Each new group starts with one condition and focuses the field select.
   * Updates remove group button visibility after addition.
   * Announces the action to screen readers.
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
    this.#announce(this.groupAddedMessageValue);
  }

  /**
   * Remove a search group if more than one group exists.
   * Prevents removal of the last group to maintain at least one group.
   * Reindexes remaining groups and focuses the last group's select.
   * Announces the action to screen readers.
   *
   * @param {Event} event - Event triggered by the remove group button
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
    this.#announce(this.groupRemovedMessageValue);
  }

  /**
   * Handle field selection changes.
   * Updates the operator dropdown based on field type (enum vs standard).
   * If an operator is already selected, updates the value input accordingly.
   * Only processes changes when the field value actually changes.
   *
   * @param {Event} event - Change event from the field select element
   */
  handleFieldChange(event) {
    if (!event?.target) return;

    const fieldElement =
      event.target.closest?.(this.constructor.SELECTORS.fieldSelect) ||
      event.target;

    if (!fieldElement) return;

    const condition = findCondition(fieldElement);
    if (!condition) return;

    const selectedField =
      event.detail?.value ??
      (fieldElement instanceof HTMLInputElement ||
      fieldElement instanceof HTMLSelectElement
        ? fieldElement.value
        : "");

    // Get the hidden field for auto-complete, or the select for regular dropdown
    const hiddenField = condition.querySelector("input[name$='[field]']");
    const previousField =
      hiddenField?.dataset?.previousValue ||
      fieldElement?.dataset?.previousValue;

    // Skip if the field value hasn't actually changed
    if (previousField === selectedField) {
      return;
    }

    // Check if this is an initial field commit (from empty/undefined to a value)
    // vs an actual field change (from one value to another)
    const isInitialCommit = previousField === undefined && selectedField !== "";

    // Store the new value for change detection
    if (hiddenField) {
      hiddenField.dataset.previousValue = selectedField;
    } else if (fieldElement instanceof HTMLSelectElement) {
      fieldElement.dataset.previousValue = selectedField;
    }

    this.#updateOperatorDropdown(condition, selectedField);

    // Only clear value container if this is an actual field change,
    // not an initial commit of the first field selection
    const valueContainer = condition.querySelector(".value");
    if (valueContainer && !isInitialCommit) {
      this.#clearValueInputs(valueContainer);
      valueContainer.classList.add(...this.constructor.HIDDEN_CLASSES);
    }
  }

  /**
   * Handle operator selection changes.
   * Swaps value input templates for list operators (in, not_in) vs single value operators.
   * Hides value inputs for operators that don't require values (exists, not_exists).
   * Updates enum field inputs if applicable.
   *
   * @param {Event} event - Change event from the operator select element
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
      valueContainer.classList.add(...this.constructor.HIDDEN_CLASSES);
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
   * Renders the condition template with proper indexing and focuses the field select.
   *
   * @param {HTMLElement} group - The group element to add the condition to
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
   * Used when switching between single-value and list-value input types.
   * Removes hidden classes from the new value container before returning it.
   *
   * @param {HTMLElement} condition - The condition fieldset element
   * @param {HTMLElement} templateTarget - The Stimulus target containing the template
   * @param {Object} context - Index information for template placeholder replacement
   * @param {number} context.groupIndex - The group's index
   * @param {number} context.conditionIndex - The condition's index within the group
   * @returns {HTMLElement|null} The new value container element, or null if not found
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

    updatedValue?.classList.remove(...this.constructor.HIDDEN_CLASSES);
    return updatedValue;
  }

  /**
   * Update the operator select dropdown with options appropriate for the selected field.
   * Uses enum-specific operations for enum fields, standard operations otherwise.
   * Preserves the current operator value if it's valid for the new field type.
   *
   * @param {HTMLElement} condition - The condition fieldset element
   * @param {string} selectedField - The field identifier that was selected
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

    // Only use enum operations if the field is an enum AND has selectable values
    const enumConfig = enumFields[selectedField];
    const isEnumWithValues =
      isEnumField(enumFields, selectedField) && this.#enumHasValues(enumConfig);
    const operations = isEnumWithValues ? enumOperations : standardOperations;

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

    operatorSelect.value = "";
  }

  /**
   * Convert a value input to an enum select element when the field is an enum type.
   * Preserves accessibility attributes, classes, and form field identifiers.
   * Supports both single-select and multi-select based on the operator.
   * If the enum has no values, leaves the text input in place for freeform entry.
   *
   * @param {HTMLElement} valueContainer - Container element holding the value input
   * @param {HTMLElement} condition - The condition fieldset element
   * @param {string} selectedField - The field identifier that is an enum type
   * @param {string} operator - The selected operator (determines single vs multi-select)
   */
  #updateValueFieldForEnum(valueContainer, condition, selectedField, operator) {
    if (!valueContainer || !selectedField) {
      return;
    }

    const enumConfig = this.#enumConfig(condition, selectedField);
    if (!enumConfig) {
      return;
    }

    // If the enum has no values, leave the text input for freeform entry
    const hasValues = this.#enumHasValues(enumConfig);
    if (!hasValues) {
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
   * Retrieve enum field configuration from the condition's data attributes.
   *
   * @param {HTMLElement} condition - The condition fieldset element
   * @param {string} selectedField - The field identifier to look up
   * @returns {Object|null} Enum configuration object with labels and values, or null if not found
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
   * Check if an enum configuration has any selectable values.
   * Returns true if either values array or labels object contains entries.
   *
   * @param {Object} enumConfig - Enum configuration object with values and labels
   * @returns {boolean} True if the enum has at least one selectable value
   */
  #enumHasValues(enumConfig) {
    try {
      if (!enumConfig) return false;

      const values = enumConfig.values || [];
      const labels = enumConfig.labels || {};

      const normalizedValues = Array.isArray(values)
        ? values
        : values && typeof values === "object"
          ? Object.keys(values)
          : [];

      if (normalizedValues.length > 0) {
        return true;
      }

      return Object.keys(labels).length > 0;
    } catch (error) {
      console.error("Failed to check enum values:", error);
      return false;
    }
  }

  /**
   * Locate the current input element that needs to be replaced with an enum select.
   * For list operators, checks for list-filter controller or multi-select.
   * For single-value operators, checks for select or text input.
   *
   * @param {HTMLElement} valueContainer - Container element holding the value input
   * @param {boolean} isListOperator - Whether the operator requires multiple values
   * @returns {HTMLElement|null} The input element to replace, or null if not found
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
   * Determine which element to use as the source for attribute transfer when creating enum selects.
   * Prioritizes the input element itself, or nested inputs for list operators with controllers.
   *
   * @param {HTMLElement} currentInput - The input element being replaced
   * @param {boolean} isListOperator - Whether the operator requires multiple values
   * @returns {HTMLElement|null} The element to extract attributes from, or null if invalid
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
   * Extract or derive the correct name attribute for the generated enum select.
   * For list operators, removes the trailing array brackets if present.
   * Preserves the original name pattern for Rails nested attributes.
   *
   * @param {HTMLElement} currentInput - The input element being replaced
   * @param {boolean} isListOperator - Whether the operator requires multiple values
   * @returns {string|null} The name attribute to use, or null if unable to determine
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
   * Extract CSS classes from the source element to apply to the generated enum select.
   * Filters out classes that shouldn't be transferred (e.g., transparency, border overrides).
   * For list operators with controllers, returns empty string if source isn't a select.
   *
   * @param {HTMLElement|null} attributeSource - Element to extract classes from
   * @param {boolean} isListOperator - Whether the operator requires multiple values
   * @returns {string} Space-separated CSS class names, or empty string if none applicable
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
   * Collect accessibility and form-related attributes to transfer to the generated enum select.
   * Preserves ARIA attributes, error associations, validation states, and required flags.
   *
   * @param {Object} options - Configuration object
   * @param {HTMLElement} options.valueContainer - Container element for context
   * @param {HTMLElement|null} options.attributeSource - Source element for existing attributes
   * @param {string|undefined} options.ariaLabel - Label text for aria-label attribute
   * @param {HTMLElement|null} options.labelElement - Label element to check for required state
   * @returns {Record<string, string|boolean>} Object of attribute name-value pairs
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
   * Extract text content from the label element to use as aria-label.
   *
   * @param {HTMLElement} valueContainer - Container element that may contain a label
   * @returns {string|undefined} The trimmed label text, or undefined if no label found
   */
  #valueAriaLabel(valueContainer) {
    const label = valueContainer.querySelector("label");
    return label ? label.textContent.trim() : undefined;
  }

  /**
   * Check if a field is marked as required via data attribute on the label.
   *
   * @param {HTMLElement|null} labelElement - The label element to check
   * @returns {boolean} True if the field is required, false otherwise
   */
  #isRequiredField(labelElement) {
    return labelElement?.dataset?.required === "true";
  }

  /**
   * Find the associated error element's ID for aria-describedby attribute.
   * Looks for elements with IDs ending in '_error'.
   *
   * @param {HTMLElement} valueContainer - Container element to search within
   * @returns {string|undefined} The error element's ID, or undefined if not found
   */
  #valueErrorId(valueContainer) {
    return valueContainer.querySelector("[id$='_error']")?.id;
  }

  /**
   * Clear all value inputs within the container.
   * Resets text inputs to empty string and select elements to no selection.
   *
   * @param {HTMLElement} valueContainer - Container element holding value inputs
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
   * Toggle remove group button visibility and accessibility based on group count.
   * Hides buttons when only one group exists to prevent removing the last group.
   * Updates aria-hidden and tabIndex attributes accordingly.
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
   * Get the currently selected field value from a condition's field select.
   *
   * @param {HTMLElement} condition - The condition fieldset element
   * @returns {string} The selected field identifier, or empty string if none selected
   */
  #selectedField(condition) {
    const fieldSelect = condition.querySelector(
      this.constructor.SELECTORS.fieldSelect,
    );
    return fieldSelect?.value || "";
  }

  #handleAutoCompleteChange(event) {
    this.handleFieldChange(event);
  }

  /**
   * Check if the form has been modified from its original state.
   * Compares both HTML structure and input values to detect changes.
   *
   * @returns {boolean} True if the form has unsaved changes, false otherwise
   */
  #dirty() {
    if (!this.#htmlContentMatches()) {
      return true;
    }
    return this.#inputValuesChanged();
  }

  /**
   * Compare the rendered HTML content with the original template.
   * Used to detect structural changes (added/removed groups or conditions).
   *
   * @returns {boolean} True if HTML content matches the template, false otherwise
   */
  #htmlContentMatches() {
    return (
      this.searchGroupsContainerTarget.innerHTML.trim() ===
      this.searchGroupsTemplateTarget.innerHTML.trim()
    );
  }

  /**
   * Compare current input values with the original template values.
   * Checks group input elements for any value changes.
   *
   * @returns {boolean} True if any input values differ from the template, false otherwise
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

  // ====================================================================
  // Private: Accessibility
  // ====================================================================

  /**
   * Announce a message to screen readers via an aria-live region.
   * Uses the statusAnnouncement target if available, otherwise falls back
   * to a global live region.
   *
   * @param {string} message - The message to announce
   * @private
   */
  #announce(message) {
    announce(message, {
      element: this.hasStatusAnnouncementTarget
        ? this.statusAnnouncementTarget
        : null,
    });
  }
}
