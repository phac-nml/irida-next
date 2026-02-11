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
  #hidden_classes = ["invisible", "@max-xl:hidden"];

  connect() {
    // Render the search if openValue is true on connect
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
    } else {
      if (window.confirm(this.confirmCloseTextValue)) {
        this.clear();
      } else {
        event.stopImmediatePropagation();
        event.preventDefault();
      }
    }
  }

  addCondition(event) {
    const group = event.currentTarget.parentElement.closest(
      "fieldset[data-advanced-search-target='groupsContainer']",
    );
    this.#addConditionToGroup(group);
    this.clearSubmitError();
  }

  removeCondition(event) {
    const condition = event.currentTarget.parentElement;
    const group = condition.closest(
      "fieldset[data-advanced-search-target='groupsContainer']",
    );
    let conditions = group.querySelectorAll(
      "fieldset[data-advanced-search-target='conditionsContainer']",
    );

    condition.remove();
    conditions = group.querySelectorAll(
      "fieldset[data-advanced-search-target='conditionsContainer']",
    );
    //re-index the fieldset legend & all the form fields within the group
    conditions.forEach((condition, index) => {
      const legend = condition.querySelector("legend");
      const updatedLegend = legend.innerHTML.replace(
        /(Condition\s)\d+/,
        "$1" + (index + 1),
      );
      legend.innerHTML = updatedLegend;
      const inputFields = condition.querySelectorAll("[name]");
      inputFields.forEach((inputField) => {
        const updatedInputFieldName = inputField.name.replace(
          /(\[conditions_attributes\]\[)\d+?(\])/,
          "$1" + index + "$2",
        );
        inputField.name = updatedInputFieldName;
      });
    });
    if (conditions.length === 0) {
      this.#addConditionToGroup(group);
    } else {
      group.children[conditions.length].querySelector("select")?.focus();
      group.children[conditions.length]
        .querySelector("input:not([type='hidden'])")
        ?.focus();
    }
    this.clearSubmitError();
  }

  addGroup() {
    const group_index = this.groupsContainerTargets.length;
    this.searchGroupsContainerTarget.insertAdjacentHTML(
      "beforeend",
      this.groupTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
        .replace(/GROUP_LEGEND_INDEX_PLACEHOLDER/g, group_index + 1),
    );
    const newCondition = this.conditionTemplateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, 0)
      .replace(/CONDITION_LEGEND_INDEX_PLACEHOLDER/g, 1);
    const group = this.groupsContainerTargets[group_index];
    group.insertAdjacentHTML("afterbegin", newCondition);
    group.querySelector("select")?.focus();
    group.querySelector("input:not([type='hidden'])")?.focus();
    //show 'Remove group' buttons if there's more than one group
    if (this.groupsContainerTargets.length > 1) {
      this.groupsContainerTargets.forEach((group) => {
        group
          .querySelector(
            "div > button[data-action='advanced-search#removeGroup']",
          )
          .classList.remove("hidden");
      });
    }
    this.clearSubmitError();
  }

  removeGroup(event) {
    if (this.groupsContainerTargets.length > 1) {
      event.currentTarget.parentElement.parentElement.remove();
      //re-index the fieldset legend & all the form fields within all the groups
      this.groupsContainerTargets.forEach((group, index) => {
        const legend = Array.from(group.children).filter((child) =>
          child.matches("legend"),
        )[0];
        const updatedLegend = legend.innerHTML.replace(
          /(Group\s)\d+/,
          "$1" + (index + 1),
        );
        legend.innerHTML = updatedLegend;
        const inputFields = group.querySelectorAll("[name]");
        inputFields.forEach((inputField) => {
          const updatedInputFieldName = inputField.name.replace(
            /(\[groups_attributes\]\[)\d+?(\])/,
            "$1" + index + "$2",
          );
          inputField.name = updatedInputFieldName;
        });
      });
      this.groupsContainerTargets.at(-1).querySelector("select")?.focus();
      this.groupsContainerTargets
        .at(-1)
        .querySelector("input:not([type='hidden'])")
        ?.focus();
      //hide 'Remove group' button if there's one group left
      if (this.groupsContainerTargets.length === 1) {
        this.groupsContainerTarget
          .querySelector(
            "div > button[data-action='advanced-search#removeGroup']",
          )
          .classList.add("hidden");
      }
    }
    this.clearSubmitError();
  }

  clearForm() {
    this.clear();
    this.addGroup();
    this.clearSubmitError();
  }

  handleOperatorChange(event) {
    const operator = event.target.value;
    const condition = event.target.parentElement.closest(
      "fieldset[data-advanced-search-target='conditionsContainer']",
    );
    const value = condition.querySelector(".value");
    const group = condition.parentElement;
    const group_index = this.groupsContainerTargets.indexOf(group);
    const condition_index = [
      ...group.querySelectorAll(
        "fieldset[data-advanced-search-target='conditionsContainer']",
      ),
    ].indexOf(condition);

    if (["", "exists", "not_exists"].includes(operator)) {
      value.classList.add(...this.#hidden_classes);
      const inputs = value.querySelectorAll("input");
      inputs.forEach((input) => {
        input.value = "";
      });
    } else if (["in", "not_in"].includes(operator)) {
      value.classList.remove(...this.#hidden_classes);
      value.outerHTML = this.listValueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
    } else {
      value.classList.remove(...this.#hidden_classes);
      value.outerHTML = this.valueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
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
    const group_index = this.groupsContainerTargets.indexOf(group);
    const condition_index = group.querySelectorAll(
      "fieldset[data-advanced-search-target='conditionsContainer']",
    ).length;
    const newCondition = this.conditionTemplateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index)
      .replace(/CONDITION_LEGEND_INDEX_PLACEHOLDER/g, condition_index + 1);
    group.lastElementChild.insertAdjacentHTML("beforebegin", newCondition);
    group.children[condition_index + 1].querySelector("select")?.focus();
    group.children[condition_index + 1]
      .querySelector("input:not([type='hidden'])")
      ?.focus();
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
    const firstCondition = this.conditionsContainerTargets[0];

    if (!firstCondition) {
      return;
    }

    const fieldInput = firstCondition.querySelector(
      "input[role='combobox'], select[name$='[field]'], [name$='[field]']",
    );
    fieldInput?.focus();
  }

  #dirty() {
    let dirty = true;
    if (
      this.searchGroupsContainerTarget.innerHTML.trim() ===
      this.searchGroupsTemplateTarget.innerHTML.trim()
    ) {
      dirty = false;
      const currentInputs = this.searchGroupsContainerTarget.querySelectorAll(
        "[id^='q_groups_attributes_']",
      );
      const originalInputs =
        this.searchGroupsTemplateTarget.content.querySelectorAll(
          "[id^='q_groups_attributes_']",
        );
      originalInputs.forEach((item, index) => {
        if (item.value !== currentInputs[index].value) {
          dirty = true;
        }
      });
    }
    return dirty;
  }
}
