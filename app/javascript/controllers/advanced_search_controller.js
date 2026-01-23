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
    "valueTemplate",
    "enumValueTemplate",
    "enumListValueTemplate",
  ];
  static outlets = ["list-filter"];
  static values = {
    confirmCloseText: String,
    open: Boolean,
  };
  #hidden_classes = ["invisible", "@max-xl:hidden"];
  #enumOperators = ["=", "!=", "in", "not_in"];

  connect() {
    // Render the search if openValue is true on connect
    if (this.openValue) {
      this.renderSearch();
    }
  }

  renderSearch() {
    this.searchGroupsContainerTarget.innerHTML =
      this.searchGroupsTemplateTarget.innerHTML;
  }

  clear() {
    this.searchGroupsContainerTarget.innerHTML = "";
  }

  close(event) {
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
  }

  clearForm() {
    this.clear();
    this.addGroup();
  }

  handleFieldChange(event) {
    const fieldValue = event.target.value;
    const condition = event.target.parentElement.closest(
      "fieldset[data-advanced-search-target='conditionsContainer']",
    );
    const enumFields = JSON.parse(condition.dataset.enumFields || "{}");
    const operatorSelect = condition.querySelector(
      "select[name$='[operator]']",
    );
    const isEnumField = Object.prototype.hasOwnProperty.call(
      enumFields,
      fieldValue,
    );

    // Store original operators if not already stored
    if (!this._originalOperators) {
      this._originalOperators = Array.from(operatorSelect.options).map(
        (opt) => ({ value: opt.value, text: opt.text }),
      );
    }

    if (isEnumField) {
      // Filter operators for enum fields
      const currentValue = operatorSelect.value;
      operatorSelect.innerHTML = "";

      // Add blank option
      const blankOption = document.createElement("option");
      blankOption.value = "";
      blankOption.text = "";
      operatorSelect.add(blankOption);

      // Add only enum-compatible operators
      this._originalOperators.forEach((opt) => {
        if (opt.value === "" || this.#enumOperators.includes(opt.value)) {
          const option = document.createElement("option");
          option.value = opt.value;
          option.text = opt.text;
          operatorSelect.add(option);
        }
      });

      // Restore selection if still valid
      if (this.#enumOperators.includes(currentValue)) {
        operatorSelect.value = currentValue;
      }

      // Update value field to show enum select
      this.#updateValueForEnumField(condition, enumFields[fieldValue]);
    } else {
      // Restore all operators
      const currentValue = operatorSelect.value;
      operatorSelect.innerHTML = "";
      this._originalOperators.forEach((opt) => {
        const option = document.createElement("option");
        option.value = opt.value;
        option.text = opt.text;
        operatorSelect.add(option);
      });
      operatorSelect.value = currentValue;

      // Update value field to show text input
      this.#updateValueForTextField(condition);
    }
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

    // Check if this is an enum field
    const enumFields = JSON.parse(condition.dataset.enumFields || "{}");
    const fieldSelect = condition.querySelector("select[name$='[field]']");
    const fieldValue = fieldSelect?.value;
    const isEnumField =
      fieldValue &&
      Object.prototype.hasOwnProperty.call(enumFields, fieldValue);

    if (["", "exists", "not_exists"].includes(operator)) {
      value.classList.add(...this.#hidden_classes);
      const inputs = value.querySelectorAll("input");
      inputs.forEach((input) => {
        input.value = "";
      });
    } else if (["in", "not_in"].includes(operator)) {
      value.classList.remove(...this.#hidden_classes);
      if (isEnumField) {
        this.#updateValueForEnumField(condition, enumFields[fieldValue], true);
      } else {
        value.outerHTML = this.listValueTemplateTarget.innerHTML
          .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
          .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
      }
    } else {
      value.classList.remove(...this.#hidden_classes);
      if (isEnumField) {
        this.#updateValueForEnumField(condition, enumFields[fieldValue], false);
      } else {
        value.outerHTML = this.valueTemplateTarget.innerHTML
          .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
          .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
      }
    }
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

  #updateValueForEnumField(condition, enumOptions, isMultiple = false) {
    const value = condition.querySelector(".value");
    const group = condition.parentElement;
    const group_index = this.groupsContainerTargets.indexOf(group);
    const condition_index = [
      ...group.querySelectorAll(
        "fieldset[data-advanced-search-target='conditionsContainer']",
      ),
    ].indexOf(condition);

    // Get form field naming
    const formName = `q[groups_attributes][${group_index}][conditions_attributes][${condition_index}][value]${isMultiple ? "[]" : ""}`;
    const formId = `q_groups_attributes_${group_index}_conditions_attributes_${condition_index}_value`;

    // Build select options HTML
    let optionsHtml = '<option value=""></option>';
    enumOptions.forEach((opt) => {
      const optValue = Array.isArray(opt) ? opt[1] : opt;
      const optLabel = Array.isArray(opt) ? opt[0] : opt;
      optionsHtml += `<option value="${optValue}">${optLabel}</option>`;
    });

    // Create new value div with select
    const newValueHtml = `
      <div class="form-field w-5/12 @max-xl:w-full value" data-enum-field="true" data-enum-options='${JSON.stringify(enumOptions)}'>
        <label for="${formId}" data-required="true">Value</label>
        <select name="${formName}" id="${formId}" ${isMultiple ? "multiple" : ""} aria-label="Value">
          ${optionsHtml}
        </select>
      </div>
    `;

    value.outerHTML = newValueHtml;
  }

  #updateValueForTextField(condition) {
    const value = condition.querySelector(".value");
    const group = condition.parentElement;
    const group_index = this.groupsContainerTargets.indexOf(group);
    const condition_index = [
      ...group.querySelectorAll(
        "fieldset[data-advanced-search-target='conditionsContainer']",
      ),
    ].indexOf(condition);

    // Check current operator to determine if we need list or single value
    const operatorSelect = condition.querySelector(
      "select[name$='[operator]']",
    );
    const operator = operatorSelect?.value;

    if (["in", "not_in"].includes(operator)) {
      value.outerHTML = this.listValueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
    } else {
      value.outerHTML = this.valueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
    }
  }
}
