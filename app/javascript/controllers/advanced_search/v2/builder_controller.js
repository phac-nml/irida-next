import { Controller } from "@hotwired/stimulus";

const LIST_OPERATORS = new Set(["in", "not_in", "text_in", "text_not_in"]);
const BETWEEN_OPERATORS = /between/;

const isListOperator = (operator) => LIST_OPERATORS.has(operator);

const createEnumLabel = (value, labels = {}) => {
  const text = labels[value];
  if (text) {
    return text;
  }

  return String(value)
    .replace(/[_-]/g, " ")
    .replace(/\b\w/g, (char) => char.toUpperCase());
};

const replaceChildrenWithFragment = (element, items) => {
  const fragment = document.createDocumentFragment();
  items.forEach((item) => fragment.appendChild(item));
  element.replaceChildren(fragment);
};

// Host-agnostic advanced search query builder.
//
// Owns all client-side node logic (add/remove groups & conditions,
// field/operator/value templating). Knows nothing about its host (dialog, drawer,
// page); a host adapter drives it through the public methods below via a Stimulus outlet:
//   render(), renderExisting(), clear(), clearForm(), isDirty()
export default class AdvancedSearchBuilderController extends Controller {
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
    "betweenValueTemplate",
  ];
  static outlets = ["list-input"];
  static values = {
    enumFields: Object,
    enumOperations: Object,
    initialState: Array,
    operations: Object,
  };

  #hiddenClasses = ["invisible", "@max-xl:hidden"];
  #groupSelector =
    "fieldset[data-advanced-search--v2--builder-target='groupsContainer']";
  #conditionSelector =
    "fieldset[data-advanced-search--v2--builder-target='conditionsContainer']";
  #groupIndexAttribute = "data-advanced-search--v2--builder-group-index";
  #conditionIndexAttribute =
    "data-advanced-search--v2--builder-condition-index";
  #legendTemplateAttribute =
    "data-advanced-search--v2--builder-legend-template";
  #nextGroupIndex = 0;
  #nextConditionIndexes = new WeakMap();

  // Seed the builder: render existing groups, or a single empty group when none exist.
  render() {
    if (this.searchGroupsTemplateTarget.innerHTML.trim() === "") {
      this.clear();
      this.addGroup();
    } else {
      this.renderExisting();
    }
  }

  // Render the server-rendered existing groups into the container (no seeding).
  renderExisting() {
    this.clear();
    this.searchGroupsContainerTarget.innerHTML =
      this.searchGroupsTemplateTarget.innerHTML;
    const groups = this.#groupElements();
    this.#nextGroupIndex = this.#nextIndex(groups, this.#groupIndexAttribute);
    groups.forEach((group) => {
      this.#nextConditionIndexes.set(
        group,
        this.#nextIndex(
          this.#conditionElements(group),
          this.#conditionIndexAttribute,
        ),
      );
    });
  }

  clear() {
    this.searchGroupsContainerTarget.innerHTML = "";
    this.#nextGroupIndex = 0;
    this.#nextConditionIndexes = new WeakMap();
  }

  clearForm() {
    this.clear();
    this.searchGroupsContainerTarget.innerHTML =
      this.emptySearchTemplateTarget.innerHTML;
  }

  isDirty() {
    const currentState = this.#serializeFormState(
      this.searchGroupsContainerTarget,
    );

    const originalState = this.#serializeQueryState(this.initialStateValue);

    return currentState !== originalState;
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
      this.#updateConditionLegends(group);
      const focusIndex = Math.min(removedIndex, remainingConditions.length - 1);
      this.#focusConditionInput(remainingConditions[focusIndex]);
    }
  }

  addGroup() {
    const groupIndex = this.#nextGroupIndex++;
    const groupNumber = this.#groupElements().length + 1;

    this.searchGroupsContainerTarget.insertAdjacentHTML(
      "beforeend",
      this.groupTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
        .replace(/GROUP_LEGEND_INDEX_PLACEHOLDER/g, groupNumber),
    );

    const group = this.#groupElements().at(-1);
    this.#nextConditionIndexes.set(group, 0);
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

    this.#groupElements().forEach((remainingGroup, index) => {
      this.#updateLegend(remainingGroup, index + 1);
    });
    this.#toggleRemoveGroupButtons();

    const remainingGroups = this.#groupElements();
    const focusGroup =
      remainingGroups[Math.min(removedIndex, remainingGroups.length - 1)];
    const focusCondition = this.#conditionElements(focusGroup)[0];
    this.#focusConditionInput(focusCondition);
  }

  handleOperatorChange(event) {
    const operator = event.target.value;
    const condition = event.target.closest(this.#conditionSelector);
    const group = condition?.closest(this.#groupSelector);

    if (!condition || !group) {
      return;
    }

    const value = this.#resetAndGetValueInput(condition);
    if (!value) {
      return;
    }
    const groupIndex = group.getAttribute(this.#groupIndexAttribute);
    const conditionIndex = condition.getAttribute(
      this.#conditionIndexAttribute,
    );

    const selectedField = this.#selectedConditionField(condition);
    if (Object.hasOwn(this.enumFieldsValue, selectedField)) {
      const templateTarget = isListOperator(operator)
        ? this.listSelectValueTemplateTarget
        : this.selectValueTemplateTarget;
      value.outerHTML = templateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, conditionIndex);

      const updatedValue = condition.querySelector(".value");
      updatedValue?.classList.remove(...this.#hiddenClasses);
      this.#updateValueFieldForEnum(
        updatedValue,
        condition,
        selectedField,
        operator,
      );
      return;
    }

    const templateTarget = this.#valueTemplateForOperator(operator);
    value.outerHTML = templateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, conditionIndex);

    if (operator === "" || operator.includes("exists")) {
      const updatedValue = condition.querySelector(".value");
      if (!updatedValue) {
        return;
      }

      updatedValue.classList.add(...this.#hiddenClasses);
      updatedValue.querySelectorAll("input, select").forEach((element) => {
        element.value = "";

        if (element.tagName === "SELECT") {
          element.selectedIndex = -1;
        }
      });
    }
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

    const value = this.#resetAndGetValueInput(condition);
    if (value) {
      this.#clearValueInputs(value);
      value.classList.add(...this.#hiddenClasses);
    }
  }

  #addConditionToGroup(group) {
    if (!group) {
      return;
    }

    const groupIndex = group.getAttribute(this.#groupIndexAttribute);
    const conditionIndex = this.#nextConditionIndexes.get(group);
    this.#nextConditionIndexes.set(group, conditionIndex + 1);
    const conditionNumber = this.#conditionElements(group).length + 1;
    const newCondition = this.conditionTemplateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, conditionIndex)
      .replace(/CONDITION_LEGEND_INDEX_PLACEHOLDER/g, conditionNumber);

    const actionsContainer = this.#groupActionsContainer(group);

    if (actionsContainer) {
      actionsContainer.insertAdjacentHTML("beforebegin", newCondition);
    } else {
      group.insertAdjacentHTML("beforeend", newCondition);
    }

    this.#focusConditionInput(this.#conditionElements(group).at(-1));
  }

  #groupActionsContainer(group) {
    return group
      .querySelector(
        "button[data-action='advanced-search--v2--builder#addCondition']",
      )
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

  // Keys identify controls for their lifetime; only legend numbers follow DOM order.
  #nextIndex(elements, attribute) {
    return elements.reduce(
      (nextIndex, element) =>
        Math.max(nextIndex, Number(element.getAttribute(attribute)) + 1),
      0,
    );
  }

  #updateOperatorDropdown(condition, selectedField) {
    const operator = condition.querySelector("[name$='[operator]']");
    /* v8 ignore next 3 -- defensive: handleFieldChange only calls this after confirming the operator field exists */
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
      if (
        selectedField.startsWith("metadata.") &&
        Object.hasOwn(this.operationsValue, "metadata")
      ) {
        this.#createOperatorOptions(
          this.enumOperationsValue["metadata"],
          operator,
        );
      } else {
        this.#createOperatorOptions(
          this.enumOperationsValue["standard"],
          operator,
        );
      }
    } else if (
      selectedField.startsWith("metadata.") &&
      Object.hasOwn(this.operationsValue, "metadata")
    ) {
      this.#createMetadataOperatorOptions(
        this.operationsValue["metadata"],
        operator,
      );
    } else {
      this.#createOperatorOptions(this.operationsValue["standard"], operator);
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

  #createOperatorOptions(options, parentNode) {
    const optionsFragment = document.createDocumentFragment();

    Object.entries(options).forEach(([label, value]) => {
      const option = document.createElement("option");
      option.value = value;
      option.text = label;
      optionsFragment.appendChild(option);
    });

    parentNode.appendChild(optionsFragment);
  }

  #updateConditionLegends(group) {
    this.#conditionElements(group).forEach((condition, conditionIndex) => {
      this.#updateLegend(condition, conditionIndex + 1);
    });
  }

  #updateLegend(container, index) {
    const legend = Array.from(container.children).find(
      (child) => child.tagName === "LEGEND",
    );

    const legendTemplate = container.getAttribute(
      this.#legendTemplateAttribute,
    );
    if (!legend || !legendTemplate) {
      return;
    }

    legend.textContent = legendTemplate.replace("__INDEX__", index);
  }

  #toggleRemoveGroupButtons() {
    const showRemoveButton = this.#groupElements().length > 1;

    this.#groupElements().forEach((group) => {
      const removeButton = group.querySelector(
        "button[data-action='advanced-search--v2--builder#removeGroup']",
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

  #valueTemplateForOperator(operator) {
    if (isListOperator(operator)) {
      return this.listValueTemplateTarget;
    }

    if (BETWEEN_OPERATORS.test(operator)) {
      return this.betweenValueTemplateTarget;
    }

    return this.valueTemplateTarget;
  }

  #updateValueFieldForEnum(valueContainer, condition, selectedField, operator) {
    if (!valueContainer || !condition || !selectedField) {
      return;
    }

    const enumConfig = this.enumFieldsValue[selectedField];
    if (!this.#enumHasValues(enumConfig)) {
      return;
    }

    const listOperator = isListOperator(operator);
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

    replaceChildrenWithFragment(
      select,
      values.map((value) => {
        const option = document.createElement("option");
        option.value = value;
        option.text = createEnumLabel(value, labels);
        return option;
      }),
    );

    select.value = "";
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

    return this.#serializeQueryState(groups);
  }

  #serializeQueryState(groups) {
    return JSON.stringify(
      groups.map((conditions) =>
        conditions.map((condition) => {
          const operator = String(condition.operator ?? "");
          let values = condition.values.map((value) => String(value ?? ""));

          if (BETWEEN_OPERATORS.test(operator)) {
            values = [values[0] ?? "", values[1] ?? ""];
          } else {
            values = values.filter((value) => value !== "");
          }
          if (isListOperator(operator)) {
            values.sort();
          }

          return { field: String(condition.field ?? ""), operator, values };
        }),
      ),
    );
  }

  #clearValueInputs(valueContainer) {
    valueContainer.querySelectorAll("input, select").forEach((element) => {
      element.value = "";

      if (element.tagName === "SELECT") {
        element.selectedIndex = -1;
      }
    });
  }

  #resetAndGetValueInput(condition) {
    /* v8 ignore next -- defensive: the change handlers always pass a resolved condition */
    if (!condition) return null;
    const values = condition.querySelectorAll(".value");
    if (values.length === 0) {
      return null;
      // handles removing second input for between operator
    } else if (values.length === 2) {
      values[1].remove();
    }

    return values[0];
  }
}
