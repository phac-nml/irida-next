import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "conditionsContainer",
    "conditionTemplate",
    "groupsContainer",
    "groupTemplate",
    "listValueTemplate",
    "searchGroupsContainer",
    "searchGroupsTemplate",
    "submitError",
    "valueTemplate",
  ];
  static outlets = ["list-filter"];
  static values = {
    confirmCloseText: String,
    open: Boolean,
    status: Boolean,
  };

  #hiddenClasses = ["invisible", "@max-xl:hidden"];
  #groupSelector = "fieldset[data-advanced-search-target='groupsContainer']";
  #conditionSelector =
    "fieldset[data-advanced-search-target='conditionsContainer']";

  connect() {
    if (this.openValue) {
      this.renderSearch();
      return;
    }

    this.#cacheSelectedFields();
  }

  renderSearch() {
    this.searchGroupsContainerTarget.innerHTML =
      this.searchGroupsTemplateTarget.innerHTML;
    this.#cacheSelectedFields();
    this.clearSubmitError();
  }

  clear() {
    this.searchGroupsContainerTarget.innerHTML = "";
    this.clearSubmitError();
  }

  submit(event) {
    if (this.#hasAtLeastOneCompleteCondition()) {
      this.clearSubmitError();
      return;
    }

    event.preventDefault();
    event.stopImmediatePropagation();
    this.#showSubmitError();
    this.#focusFirstConditionField();
  }

  close(event) {
    if (!this.statusValue) {
      this.clear();
      return;
    }

    if (!(event instanceof KeyboardEvent) && event.type === "keydown") {
      event.preventDefault();
      event.stopImmediatePropagation();
    } else if (!this.#dirty()) {
      this.renderSearch();
    } else if (window.confirm(this.confirmCloseTextValue)) {
      this.renderSearch();
    } else {
      event.stopImmediatePropagation();
      event.preventDefault();
    }
  }

  addCondition(event) {
    const group = event.currentTarget.closest(this.#groupSelector);
    this.#addConditionToGroup(group);
    this.clearSubmitError();
  }

  removeCondition(event) {
    const condition = event.currentTarget.closest(this.#conditionSelector);
    const group = condition?.closest(this.#groupSelector);

    if (!condition || !group) {
      return;
    }

    const conditions = this.#conditionElements(group);
    const removedIndex = conditions.indexOf(condition);
    condition.remove();

    const remainingConditions = this.#conditionElements(group);

    if (remainingConditions.length === 0) {
      this.#addConditionToGroup(group);
    } else {
      this.#reindexGroup(group, this.#groupElements().indexOf(group));
      const focusIndex = Math.min(removedIndex, remainingConditions.length - 1);
      this.#focusConditionInput(remainingConditions[focusIndex]);
    }

    this.clearSubmitError();
  }

  addGroup() {
    const groupIndex = this.#groupElements().length;

    this.searchGroupsContainerTarget.insertAdjacentHTML(
      "beforeend",
      this.groupTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
        .replace(/GROUP_LEGEND_INDEX_PLACEHOLDER/g, groupIndex + 1),
    );

    const group = this.#groupElements().at(-1);
    this.#addConditionToGroup(group);
    this.#toggleRemoveGroupButtons();
    this.clearSubmitError();
  }

  removeGroup(event) {
    if (this.#groupElements().length <= 1) {
      this.clearSubmitError();
      return;
    }

    const group = event.currentTarget.closest(this.#groupSelector);

    if (!group) {
      this.clearSubmitError();
      return;
    }

    const groups = this.#groupElements();
    const removedIndex = groups.indexOf(group);
    group.remove();

    this.#reindexAllGroups();
    this.#toggleRemoveGroupButtons();

    const remainingGroups = this.#groupElements();
    const focusGroup =
      remainingGroups[Math.min(removedIndex, remainingGroups.length - 1)];
    const focusCondition = this.#conditionElements(focusGroup)[0];
    this.#focusConditionInput(focusCondition);

    this.clearSubmitError();
  }

  clearForm() {
    this.clear();
    this.addGroup();
    this.clearSubmitError();
  }

  handleOperatorChange(event) {
    const operator = event.target.value;
    const condition = event.target.closest(this.#conditionSelector);
    const group = condition?.closest(this.#groupSelector);

    if (!condition || !group) {
      this.clearSubmitError();
      return;
    }

    const value = condition.querySelector(".value");
    const groupIndex = this.#groupElements().indexOf(group);
    const conditionIndex = this.#conditionElements(group).indexOf(condition);

    if (!value || groupIndex < 0 || conditionIndex < 0) {
      this.clearSubmitError();
      return;
    }

    if (["", "exists", "not_exists"].includes(operator)) {
      value.classList.add(...this.#hiddenClasses);
      this.#clearValueInputs(value);
      return;
    } else if (["in", "not_in"].includes(operator)) {
      const selectedField = this.#selectedConditionField(condition);
      value.outerHTML = this.listValueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, conditionIndex);

      const updatedCondition = this.#conditionElements(group)[conditionIndex];
      const updatedValue = updatedCondition?.querySelector(".value");
      updatedValue?.classList.remove(...this.#hiddenClasses);
      this.#updateValueFieldForEnum(
        updatedValue,
        updatedCondition,
        selectedField,
        operator,
      );
    } else {
      const selectedField = this.#selectedConditionField(condition);
      value.outerHTML = this.valueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, conditionIndex);

      const updatedCondition = this.#conditionElements(group)[conditionIndex];
      const updatedValue = updatedCondition?.querySelector(".value");
      updatedValue?.classList.remove(...this.#hiddenClasses);
      this.#updateValueFieldForEnum(
        updatedValue,
        updatedCondition,
        selectedField,
        operator,
      );
    }

    this.clearSubmitError();
  }

  handleFieldChange(event) {
    const condition = event.target.closest(this.#conditionSelector);
    if (!condition) {
      this.clearSubmitError();
      return;
    }

    const operator = condition.querySelector("[name$='[operator]']");
    if (!operator) {
      this.clearSubmitError();
      return;
    }

    const selectedField =
      event.target.matches("[name$='[field]']") && event.target.value
        ? event.target.value
        : this.#selectedConditionField(condition);

    const previousField = condition.dataset.advancedSearchSelectedField || "";
    if (previousField === selectedField) {
      this.clearSubmitError();
      return;
    }

    condition.dataset.advancedSearchSelectedField = selectedField;
    this.#updateOperatorDropdown(condition, selectedField);

    const value = condition.querySelector(".value");
    if (value) {
      this.#clearValueInputs(value);
      value.classList.add(...this.#hiddenClasses);
    }
  }

  clearSubmitError() {
    if (!this.hasSubmitErrorTarget) {
      return;
    }

    this.submitErrorTarget.classList.add("hidden");
  }

  #addConditionToGroup(group) {
    if (!group) {
      return;
    }

    const groupIndex = this.#groupElements().indexOf(group);
    const conditionIndex = this.#conditionElements(group).length;
    const newCondition = this.conditionTemplateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, conditionIndex)
      .replace(/CONDITION_LEGEND_INDEX_PLACEHOLDER/g, conditionIndex + 1);

    const actionsContainer = this.#groupActionsContainer(group);

    if (actionsContainer) {
      actionsContainer.insertAdjacentHTML("beforebegin", newCondition);
    } else {
      group.insertAdjacentHTML("beforeend", newCondition);
    }

    this.#reindexGroup(group, groupIndex);
    this.#focusConditionInput(this.#conditionElements(group).at(-1));
  }

  #groupActionsContainer(group) {
    return group
      .querySelector("button[data-action='advanced-search#addCondition']")
      ?.closest("div");
  }

  #groupElements() {
    return Array.from(
      this.searchGroupsContainerTarget.querySelectorAll(this.#groupSelector),
    );
  }

  #conditionElements(group) {
    return Array.from(group.querySelectorAll(this.#conditionSelector));
  }

  #cacheSelectedFields() {
    this.conditionsContainerTargets.forEach((condition) => {
      condition.dataset.advancedSearchSelectedField =
        this.#selectedConditionField(condition);
    });
  }

  #reindexAllGroups() {
    this.#groupElements().forEach((group, groupIndex) => {
      this.#reindexGroup(group, groupIndex);
    });
  }

  #updateOperatorDropdown(condition, selectedField) {
    const operator = condition.querySelector("[name$='[operator]']");
    if (!operator) {
      return;
    }

    const enumFields = this.#parseConditionJSON(condition, "enumFields") || {};
    const enumOperations =
      this.#parseConditionJSON(condition, "enumOperations") || {};
    const standardOperations =
      this.#parseConditionJSON(condition, "standardOperations") || {};

    const enumConfig = enumFields[selectedField];
    const operations =
      selectedField && this.#enumHasValues(enumConfig)
        ? enumOperations
        : standardOperations;

    operator.innerHTML = "";

    const blankOption = document.createElement("option");
    blankOption.value = "";
    blankOption.text = "";
    operator.appendChild(blankOption);

    Object.entries(operations).forEach(([label, value]) => {
      const option = document.createElement("option");
      option.value = value;
      option.text = label;
      operator.appendChild(option);
    });

    operator.value = "";
  }

  #reindexGroup(group, groupIndex) {
    if (!group || groupIndex < 0) {
      return;
    }

    group.dataset.advancedSearchGroupIndex = String(groupIndex);
    this.#updateLegend(group, groupIndex + 1);

    this.#conditionElements(group).forEach((condition, conditionIndex) => {
      this.#reindexCondition(condition, groupIndex, conditionIndex);
    });
  }

  #reindexCondition(condition, groupIndex, conditionIndex) {
    condition.dataset.advancedSearchGroupIndex = String(groupIndex);
    condition.dataset.advancedSearchConditionIndex = String(conditionIndex);
    this.#updateLegend(condition, conditionIndex + 1);

    ["name", "id", "for", "aria-describedby"].forEach((attribute) => {
      condition.querySelectorAll(`[${attribute}]`).forEach((element) => {
        const currentValue = element.getAttribute(attribute);

        if (!currentValue) {
          return;
        }

        const updatedValue = this.#replaceConditionIndex(
          this.#replaceGroupIndex(currentValue, groupIndex),
          conditionIndex,
        );

        if (updatedValue !== currentValue) {
          element.setAttribute(attribute, updatedValue);
        }
      });
    });
  }

  #replaceGroupIndex(value, groupIndex) {
    return value
      .replace(/(\[groups_attributes\]\[)\d+(\])/g, `$1${groupIndex}$2`)
      .replace(/(_groups_attributes_)\d+(_)/g, `$1${groupIndex}$2`);
  }

  #replaceConditionIndex(value, conditionIndex) {
    return value
      .replace(/(\[conditions_attributes\]\[)\d+(\])/g, `$1${conditionIndex}$2`)
      .replace(/(_conditions_attributes_)\d+(_)/g, `$1${conditionIndex}$2`);
  }

  #updateLegend(container, index) {
    const legend = Array.from(container.children).find(
      (child) => child.tagName === "LEGEND",
    );
    const legendTemplate = container.dataset.advancedSearchLegendTemplate;

    if (!legend || !legendTemplate) {
      return;
    }

    legend.textContent = legendTemplate.replace("__INDEX__", index);
  }

  #toggleRemoveGroupButtons() {
    const showRemoveButton = this.#groupElements().length > 1;

    this.#groupElements().forEach((group) => {
      const removeButton = group.querySelector(
        "button[data-action='advanced-search#removeGroup']",
      );

      if (!removeButton) {
        return;
      }

      removeButton.classList.toggle("hidden", !showRemoveButton);
    });
  }

  #focusConditionInput(condition) {
    if (!condition) {
      return;
    }

    const fieldInput = condition.querySelector(
      "input[role='combobox'], select[name$='[field]'], [name$='[field]']",
    );

    if (fieldInput) {
      fieldInput.focus();
      return;
    }

    condition.querySelector("input:not([type='hidden'])")?.focus();
  }

  #hasAtLeastOneCompleteCondition() {
    return this.conditionsContainerTargets.some((condition) =>
      this.#isConditionComplete(condition),
    );
  }

  #isConditionComplete(condition) {
    const field = condition.querySelector("[name$='[field]']")?.value?.trim();
    const operator = condition
      .querySelector("[name$='[operator]']")
      ?.value?.trim();

    if (!field || !operator) {
      return false;
    }

    if (["exists", "not_exists"].includes(operator)) {
      return true;
    }

    if (["in", "not_in"].includes(operator)) {
      return this.#listValueValues(condition).some(
        (value) => value.trim() !== "",
      );
    }

    const value = condition.querySelector("[name$='[value]']")?.value?.trim();

    return Boolean(value);
  }

  #showSubmitError() {
    if (!this.hasSubmitErrorTarget) {
      return;
    }

    this.submitErrorTarget.classList.remove("hidden");
  }

  #focusFirstConditionField() {
    this.#focusConditionInput(this.conditionsContainerTargets[0]);
  }

  #dirty() {
    const currentState = this.#serializeFormState(
      this.searchGroupsContainerTarget,
    );

    const originalContainer = document.createElement("div");
    originalContainer.innerHTML = this.searchGroupsTemplateTarget.innerHTML;
    const originalState = this.#serializeFormState(originalContainer);

    return currentState !== originalState;
  }

  #serializeFormState(rootElement) {
    const groups = Array.from(
      rootElement.querySelectorAll(this.#groupSelector),
    ).map((group) => {
      return Array.from(group.querySelectorAll(this.#conditionSelector)).map(
        (condition) => {
          const listValues = Array.from(
            condition.querySelectorAll("[name$='[value][]']"),
          );
          const singleValue =
            condition.querySelector("[name$='[value]']")?.value;
          const expandedListValues =
            this.#listValueValuesFromElements(listValues);

          return {
            field: condition.querySelector("[name$='[field]']")?.value,
            operator: condition.querySelector("[name$='[operator]']")?.value,
            values:
              expandedListValues.length > 0
                ? expandedListValues
                : [singleValue],
          };
        },
      );
    });

    return JSON.stringify(groups);
  }

  #selectedConditionField(condition) {
    return condition?.querySelector("[name$='[field]']")?.value?.trim() || "";
  }

  #parseConditionJSON(condition, key) {
    const payload = condition?.dataset?.[key];
    if (!payload) {
      return null;
    }

    try {
      return JSON.parse(payload);
    } catch (_error) {
      return null;
    }
  }

  #enumHasValues(enumConfig) {
    if (!enumConfig) {
      return false;
    }

    const values = Array.isArray(enumConfig.values) ? enumConfig.values : [];
    const labels =
      enumConfig.labels && typeof enumConfig.labels === "object"
        ? Object.keys(enumConfig.labels)
        : [];

    return values.length > 0 || labels.length > 0;
  }

  #updateValueFieldForEnum(valueContainer, condition, selectedField, operator) {
    if (!valueContainer || !condition || !selectedField) {
      return;
    }

    const enumFields = this.#parseConditionJSON(condition, "enumFields") || {};
    const enumConfig = enumFields[selectedField];
    if (!this.#enumHasValues(enumConfig)) {
      return;
    }

    const listOperator = ["in", "not_in"].includes(operator);
    const currentInput = listOperator
      ? valueContainer.querySelector("div[data-controller='list-filter']")
      : valueContainer.querySelector("[name$='[value]']");
    if (!currentInput) {
      return;
    }

    const sourceInput = listOperator
      ? currentInput.querySelector("input[name$='[value][]']")
      : currentInput;
    const inputName = sourceInput?.name;
    if (!inputName) {
      return;
    }

    const select = document.createElement("select");
    select.name = listOperator ? inputName : inputName;
    select.id = sourceInput.id;
    select.setAttribute(
      "aria-label",
      sourceInput.getAttribute("aria-label") ||
        valueContainer.querySelector("label")?.textContent?.trim() ||
        "",
    );

    const describedBy = sourceInput.getAttribute("aria-describedby");
    if (describedBy) {
      select.setAttribute("aria-describedby", describedBy);
    }

    const ariaInvalid = sourceInput.getAttribute("aria-invalid");
    if (ariaInvalid) {
      select.setAttribute("aria-invalid", ariaInvalid);
    }

    if (listOperator) {
      select.multiple = true;
    } else {
      const blankOption = document.createElement("option");
      blankOption.value = "";
      blankOption.text = "";
      select.appendChild(blankOption);
    }

    const values = Array.isArray(enumConfig.values) ? enumConfig.values : [];
    const labels =
      enumConfig.labels && typeof enumConfig.labels === "object"
        ? enumConfig.labels
        : {};

    values.forEach((value) => {
      const option = document.createElement("option");
      option.value = value;
      option.text =
        labels[value] ||
        value
          .replace(/[_-]/g, " ")
          .replace(/\b\w/g, (char) => char.toUpperCase());
      select.appendChild(option);
    });

    currentInput.replaceWith(select);
  }

  #clearValueInputs(valueContainer) {
    valueContainer.querySelectorAll("input, select").forEach((element) => {
      element.value = "";

      if (element.tagName === "SELECT") {
        element.selectedIndex = -1;
      }
    });
  }

  #listValueValues(condition) {
    return this.#listValueValuesFromElements(
      condition.querySelectorAll("[name$='[value][]']"),
    );
  }

  #listValueValuesFromElements(elements) {
    return Array.from(elements).flatMap((input) => {
      if (input.tagName === "SELECT" && input.multiple) {
        return Array.from(input.selectedOptions).map((option) => option.value);
      }

      return [input.value];
    });
  }
}
