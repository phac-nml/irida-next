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
    }
  }

  renderSearch() {
    this.searchGroupsContainerTarget.innerHTML =
      this.searchGroupsTemplateTarget.innerHTML;
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
      value.querySelectorAll("input").forEach((input) => {
        input.value = "";
      });
    } else if (["in", "not_in"].includes(operator)) {
      value.classList.remove(...this.#hiddenClasses);
      value.outerHTML = this.listValueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, conditionIndex);
    } else {
      value.classList.remove(...this.#hiddenClasses);
      value.outerHTML = this.valueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, groupIndex)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, conditionIndex);
    }

    this.clearSubmitError();
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

  #reindexAllGroups() {
    this.#groupElements().forEach((group, groupIndex) => {
      this.#reindexGroup(group, groupIndex);
    });
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
      const values = condition.querySelectorAll("[name$='[value][]']");

      return Array.from(values).some((input) => input.value.trim() !== "");
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
          ).map((input) => input.value);
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
}
