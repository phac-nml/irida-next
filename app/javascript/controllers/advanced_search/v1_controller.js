import { Controller } from "@hotwired/stimulus";

export default class AdvancedSearchController extends Controller {
  static targets = [
    "emptySearchTemplate",
    "conditionsContainer",
    "conditionTemplate",
    "groupsContainer",
    "groupTemplate",
    "listValueTemplate",
    "listSelectValueTemplate",
    "searchGroupsContainer",
    "searchGroupsTemplate",
    "selectValueTemplate",
    "valueTemplate",
  ];
  static outlets = ["list-input"];
  static values = {
    confirmCloseText: String,
    enumFields: Object,
    enumOperations: Object,
    operations: Object,
    hasErrors: Boolean,
    open: Boolean,
    status: Boolean,
  };

  #hiddenClasses = ["invisible", "@max-xl:hidden"];
  #groupSelector =
    "fieldset[data-advanced-search--v1-target='groupsContainer']";
  #conditionSelector =
    "fieldset[data-advanced-search--v1-target='conditionsContainer']";

  #standardOperators;
  #valueInputTypes;
  connect() {
    this.renderSearchIfOpen();
    this.boundOnMorph = this.onMorph.bind(this);

    document.addEventListener("turbo:morph", this.boundOnMorph);

    this.#mapOperatorsAndValueInputTypes();
  }

  disconnect() {
    document.removeEventListener("turbo:morph", this.boundOnMorph);
  }

  renderSearchIfOpen() {
    if (this.openValue) {
      this.renderSearch();
    }
  }

  renderSearch() {
    if (this.searchGroupsTemplateTarget.innerHTML.trim() === "") {
      this.searchGroupsContainerTarget.innerHTML = "";
      this.addGroup();
    } else {
      this.renderExistingSearch();
    }
  }

  renderExistingSearch() {
    this.searchGroupsContainerTarget.innerHTML =
      this.searchGroupsTemplateTarget.innerHTML;
  }

  onMorph() {
    this.renderSearchIfOpen();
  }

  clear() {
    this.searchGroupsContainerTarget.innerHTML = "";
  }

  close(event) {
    if (this.hasErrorsValue) {
      event.preventDefault();
      event.stopImmediatePropagation();
      this.#focusFirstInvalidField();
      return;
    }

    if (!this.statusValue) {
      this.renderSearch();
      return;
    }

    if (!(event instanceof KeyboardEvent) && event.type === "keydown") {
      event.preventDefault();
      event.stopImmediatePropagation();
    } else if (!this.#dirty()) {
      this.clear();
    } else if (window.confirm(this.confirmCloseTextValue)) {
      this.clear();
    } else {
      event.stopImmediatePropagation();
      event.preventDefault();
    }
  }

  #mapOperatorsAndValueInputTypes() {
    this.#mapStandardOperators();
    // this.#mapMetadataOperators(); TODO
    this.#determineValueInputs();
  }

  #mapStandardOperators() {
    // each operator is mapped as follow:
    // { '=' => {
    //   'option' => { I18n.t('components.advanced_search_component.v1.operations.standard.equals') => '=' },
    //   'input_type' => 'text'
    // }
    // operatorOptions mapping isolates the 'option' values to create the operator dropdown options
    this.#standardOperators = Object.fromEntries(
      Object.entries(this.operationsValue["standard"]).flatMap(
        ([_key, value]) => Object.entries(value.option),
      ),
    );
  }

  #determineValueInputs() {
    this.#valueInputTypes = Object.fromEntries(
      Object.entries(this.operationsValue["standard"]).map(([key, value]) => [
        key,
        value.input_type,
      ]),
    );
  }

  addCondition(event) {
    const group = event.currentTarget.closest(this.#groupSelector);
    this.#addConditionToGroup(group);
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
  }

  removeGroup(event) {
    if (this.#groupElements().length <= 1) {
      return;
    }

    const group = event.currentTarget.closest(this.#groupSelector);

    if (!group) {
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
  }

  clearForm() {
    this.clear();
    this.searchGroupsContainerTarget.innerHTML =
      this.emptySearchTemplateTarget.innerHTML;
  }

  handleOperatorChange(event) {
    const operator = event.target.value;
    const condition = event.target.closest(this.#conditionSelector);
    const group = condition?.closest(this.#groupSelector);

    if (!condition || !group) {
      return;
    }

    const value = condition.querySelector(".value");
    const groupIndex = this.#groupElements().indexOf(group);
    const conditionIndex = this.#conditionElements(group).indexOf(condition);
    if (!value || groupIndex < 0 || conditionIndex < 0) {
      return;
    }

    const valueInputType = this.#valueInputTypes[operator];

    // existence values where valueInputType === null
    if (!valueInputType) {
      value.classList.add(...this.#hiddenClasses);
      value.querySelectorAll("input").forEach((input) => {
        input.value = "";
      });
      return;
    }

    const selectedField = this.#selectedConditionField(condition);
    const enumFieldSelected = Object.hasOwn(
      this.enumFieldsValue,
      selectedField,
    );

    let templateTarget;
    if (enumFieldSelected) {
      if (valueInputType === "list") {
        templateTarget = this.listSelectValueTemplateTarget;
      } else {
        templateTarget = this.selectValueTemplateTarget;
      }
    } else {
      if (valueInputType === "list") {
        templateTarget = this.listValueTemplateTarget;
      } else {
        templateTarget = this.valueTemplateTarget;
      }
    }

    value.outerHTML = templateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, conditionIndex);

    if (!enumFieldSelected) return;

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

  handleFieldChange(event) {
    const condition = event.target.closest(this.#conditionSelector);
    if (!condition) {
      return;
    }

    const operator = condition.querySelector("[name$='[operator]']");
    if (!operator) {
      return;
    }

    const selectedField =
      event.target.matches("[name$='[field]']") && event.target.value
        ? event.target.value
        : this.#selectedConditionField(condition);

    const previousField = condition.dataset.advancedSearchSelectedField || "";
    if (previousField === selectedField) {
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
      .querySelector("button[data-action='advanced-search--v1#addCondition']")
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
    const enumConfig = this.enumFieldsValue[selectedField];

    const parentContainer = operator.closest(".form-field");
    if (selectedField) {
      parentContainer.classList.remove(...this.#hiddenClasses);
    } else {
      parentContainer.classList.add(...this.#hiddenClasses);
      return;
    }

    operator.innerHTML = "";

    const blankOption = document.createElement("option");
    blankOption.value = "";
    blankOption.text = "";
    operator.appendChild(blankOption);

    if (this.#enumHasValues(enumConfig)) {
      this.#createOperatorOptions(this.enumOperationsValue, operator);
    } else if (
      selectedField.startsWith("metadata.") &&
      Object.hasOwn(this.operationsValue, "metadata")
    ) {
      this.#createMetadataOperatorOptions(
        this.operationsValue["metadata"],
        operator,
      );
    } else {
      this.#createOperatorOptions(this.#standardOperators, operator);
    }

    operator.value = "";
  }

  #createMetadataOperatorOptions(options, operator) {
    Object.entries(options).forEach(([optgroup, values]) => {
      const optGroup = document.createElement("optgroup");
      optGroup.label = optgroup;
      operator.appendChild(optGroup);

      this.#createOperatorOptions(values, optGroup);
    });
  }

  #createOperatorOptions(operators, parentNode) {
    Object.entries(operators).forEach(([label, value]) => {
      const option = document.createElement("option");
      option.value = value;
      option.text = label;
      parentNode.appendChild(option);
    });
  }

  #reindexGroup(group, groupIndex) {
    if (!group || groupIndex < 0) {
      return;
    }

    group.dataset["advancedSearch--V1GroupIndex"] = String(groupIndex);
    this.#updateLegend(group, groupIndex + 1);

    this.#conditionElements(group).forEach((condition, conditionIndex) => {
      this.#reindexCondition(condition, groupIndex, conditionIndex);
    });
  }

  #reindexCondition(condition, groupIndex, conditionIndex) {
    condition.dataset["advancedSearch--V1GroupIndex"] = String(groupIndex);
    condition.dataset["advancedSearch--V1ConditionIndex"] =
      String(conditionIndex);
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

    const legendTemplate = container.dataset["advancedSearch-V1LegendTemplate"];
    if (!legend || !legendTemplate) {
      return;
    }

    legend.textContent = legendTemplate.replace("__INDEX__", index);
  }

  #toggleRemoveGroupButtons() {
    const showRemoveButton = this.#groupElements().length > 1;

    this.#groupElements().forEach((group) => {
      const removeButton = group.querySelector(
        "button[data-action='advanced-search--v1#removeGroup']",
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

  #focusFirstInvalidField() {
    const invalidField = Array.from(
      this.element.querySelectorAll("[aria-invalid='true']"),
    ).find((field) => !field.disabled && field.offsetParent !== null);

    invalidField?.focus();
  }

  #selectedConditionField(condition) {
    return condition?.querySelector("[name$='[field]']")?.value?.trim() || "";
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

    const enumConfig = this.enumFieldsValue[selectedField];
    if (!this.#enumHasValues(enumConfig)) {
      return;
    }

    const listOperator = ["in", "not_in"].includes(operator);
    const select = listOperator
      ? valueContainer.querySelector("select[name$='[value][]']")
      : valueContainer.querySelector("select[name$='[value]']");
    if (!select) {
      return;
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
          ).flatMap((input) => {
            if (input.tagName === "SELECT" && input.multiple) {
              return Array.from(input.selectedOptions).map((o) => o.value);
            }
            return [input.value];
          });
          const singleValue =
            condition.querySelector("[name$='[value]']")?.value;

          return {
            field: condition.querySelector("[name$='[field]']")?.value,
            operator: condition.querySelector("[name$='[operator]']")?.value,
            values: listValues.length > 0 ? listValues : [singleValue],
          };
        },
      );
    });

    return JSON.stringify(groups);
  }

  #clearValueInputs(valueContainer) {
    valueContainer.querySelectorAll("input, select").forEach((element) => {
      element.value = "";

      if (element.tagName === "SELECT") {
        element.selectedIndex = -1;
      }
    });
  }
}
