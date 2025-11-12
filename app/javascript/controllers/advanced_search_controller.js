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
  #hidden_classes = ["invisible", "@max-xl:hidden"];

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
    let group = event.currentTarget.parentElement.closest(
      "fieldset[data-advanced-search-target='groupsContainer']",
    );
    this.#addConditionToGroup(group);
  }

  removeCondition(event) {
    let condition = event.currentTarget.parentElement;
    let group = condition.closest(
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
      let legend = condition.querySelector("legend");
      let updatedLegend = legend.innerHTML.replace(
        /(Condition\s)\d+/,
        "$1" + (index + 1),
      );
      legend.innerHTML = updatedLegend;
      let inputFields = condition.querySelectorAll("[name]");
      inputFields.forEach((inputField) => {
        let updatedInputFieldName = inputField.name.replace(
          /(\[conditions_attributes\]\[)\d+?(\])/,
          "$1" + index + "$2",
        );
        inputField.name = updatedInputFieldName;
      });
    });
    if (conditions.length === 0) {
      this.#addConditionToGroup(group);
    } else {
      group.children[conditions.length].querySelector("select").focus();
    }
  }

  addGroup() {
    let group_index = this.groupsContainerTargets.length;
    this.searchGroupsContainerTarget.insertAdjacentHTML(
      "beforeend",
      this.groupTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
        .replace(/GROUP_LEGEND_INDEX_PLACEHOLDER/g, group_index + 1),
    );
    let newCondition = this.conditionTemplateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, 0)
      .replace(/CONDITION_LEGEND_INDEX_PLACEHOLDER/g, 1);
    let group = this.groupsContainerTargets[group_index];
    group.insertAdjacentHTML("afterbegin", newCondition);
    group.querySelector("select").focus();
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
        let legend = Array.from(group.children).filter((child) =>
          child.matches("legend"),
        )[0];
        let updatedLegend = legend.innerHTML.replace(
          /(Group\s)\d+/,
          "$1" + (index + 1),
        );
        legend.innerHTML = updatedLegend;
        let inputFields = group.querySelectorAll("[name]");
        inputFields.forEach((inputField) => {
          let updatedInputFieldName = inputField.name.replace(
            /(\[groups_attributes\]\[)\d+?(\])/,
            "$1" + index + "$2",
          );
          inputField.name = updatedInputFieldName;
        });
      });
      this.groupsContainerTargets.at(-1).querySelector("select").focus();
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
    let condition = event.target.parentElement.closest(
      "fieldset[data-advanced-search-target='conditionsContainer']",
    );
    let operatorSelect = condition.querySelector("select[name$='[operator]']");
    let operator = operatorSelect ? operatorSelect.value : "";
    let selectedField = event.target.value;

    // Update operator dropdown based on field type
    this.#updateOperatorDropdown(condition, selectedField);

    // If there's an operator selected, trigger the value field update
    if (operator && !["", "exists", "not_exists"].includes(operator)) {
      let value = condition.querySelector(".value");

      if (value && selectedField) {
        this.#updateValueFieldForEnum(value, condition, selectedField, operator);
      }
    }
  }

  handleOperatorChange(event) {
    let operator = event.target.value;
    let condition = event.target.parentElement.closest(
      "fieldset[data-advanced-search-target='conditionsContainer']",
    );
    let value = condition.querySelector(".value");
    let group = condition.parentElement;
    let group_index = this.groupsContainerTargets.indexOf(group);
    let condition_index = [
      ...group.querySelectorAll(
        "fieldset[data-advanced-search-target='conditionsContainer']",
      ),
    ].indexOf(condition);

    // Get the selected field value
    let fieldSelect = condition.querySelector("select[name$='[field]']");
    let selectedField = fieldSelect ? fieldSelect.value : "";

    if (["", "exists", "not_exists"].includes(operator)) {
      value.classList.add(...this.#hidden_classes);
      let inputs = value.querySelectorAll("input");
      inputs.forEach((input) => {
        input.value = "";
      });
    } else if (["in", "not_in"].includes(operator)) {
      value.classList.remove(...this.#hidden_classes);
      let newHTML = this.listValueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
      value.outerHTML = newHTML;

      // After replacing, update the new value element with field information
      let newValue = group.querySelectorAll(
        "fieldset[data-advanced-search-target='conditionsContainer']"
      )[condition_index].querySelector(".value");
      this.#updateValueFieldForEnum(newValue, condition, selectedField, operator);
    } else {
      value.classList.remove(...this.#hidden_classes);
      let newHTML = this.valueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
      value.outerHTML = newHTML;

      // After replacing, update the new value element with field information
      let newValue = group.querySelectorAll(
        "fieldset[data-advanced-search-target='conditionsContainer']"
      )[condition_index].querySelector(".value");
      this.#updateValueFieldForEnum(newValue, condition, selectedField, operator);
    }
  }

  #updateValueFieldForEnum(valueContainer, condition, selectedField, operator) {
    // Get enum fields configuration from data attribute
    let enumFieldsJSON = condition.dataset.enumFields;

    if (!enumFieldsJSON || !selectedField) {
      return;
    }

    try {
      let enumFields = JSON.parse(enumFieldsJSON);
      let enumConfig = enumFields[selectedField];

      if (!enumConfig) {
        return; // Not an enum field
      }

      // Get the input/select element to replace
      let isListOperator = ["in", "not_in"].includes(operator);
      let currentInput = isListOperator
        ? valueContainer.querySelector("div[data-controller='list-filter']")
        : valueContainer.querySelector("input[name$='[value]']");

      if (!currentInput) {
        return;
      }

      // Get the correct name attribute from existing input
      let inputName;
      if (isListOperator) {
        // For list operators, find the hidden input inside the list-filter div
        let hiddenInput = currentInput.querySelector("input[name$='[value][]']");
        inputName = hiddenInput ? hiddenInput.name.replace('[]', '') : null;
      } else {
        inputName = currentInput.name;
      }

      if (!inputName) {
        return;
      }

      // Create a select element with enum options
      let select = document.createElement("select");
      select.name = inputName;
      select.id = currentInput.id || inputName.replace(/\[/g, '_').replace(/\]/g, '');
      select.className = currentInput.className || "";

      // Get aria-label from the label element
      let label = valueContainer.querySelector("label");
      if (label) {
        select.setAttribute("aria-label", label.textContent.trim());
      }

      if (isListOperator) {
        select.setAttribute("multiple", "multiple");
        select.name = inputName + "[]"; // Add brackets for multiple values
      }

      // Add blank option for single select
      if (!isListOperator) {
        let blankOption = document.createElement("option");
        blankOption.value = "";
        blankOption.text = "";
        select.appendChild(blankOption);
      }

      // Add enum options with translations
      enumConfig.values.forEach((value) => {
        let option = document.createElement("option");
        option.value = value;
        // Use translated labels if available, otherwise fallback to value
        option.text = enumConfig.labels && enumConfig.labels[value]
          ? enumConfig.labels[value]
          : value.replace(/_/g, " ").replace(/\b\w/g, (c) => c.toUpperCase());
        select.appendChild(option);
      });

      // Replace the input with the select
      currentInput.replaceWith(select);
    } catch (e) {
      console.error("Error parsing enum fields:", e);
    }
  }

  #updateOperatorDropdown(condition, selectedField) {
    // Get enum and operation configurations from data attributes
    let enumFieldsJSON = condition.dataset.enumFields;
    let enumOperationsJSON = condition.dataset.enumOperations;
    let standardOperationsJSON = condition.dataset.standardOperations;

    if (!enumFieldsJSON || !enumOperationsJSON || !standardOperationsJSON || !selectedField) {
      return;
    }

    try {
      let enumFields = JSON.parse(enumFieldsJSON);
      let enumOperations = JSON.parse(enumOperationsJSON);
      let standardOperations = JSON.parse(standardOperationsJSON);

      // Determine if this is an enum field
      let isEnumField = enumFields.hasOwnProperty(selectedField);

      // Choose the appropriate operations list
      let operations = isEnumField ? enumOperations : standardOperations;

      // Find the operator select element
      let operatorSelect = condition.querySelector("select[name$='[operator]']");
      if (!operatorSelect) {
        return;
      }

      // Store current value
      let currentValue = operatorSelect.value;

      // Clear existing options
      operatorSelect.innerHTML = "";

      // Add blank option
      let blankOption = document.createElement("option");
      blankOption.value = "";
      blankOption.text = "";
      operatorSelect.appendChild(blankOption);

      // Add new options
      Object.entries(operations).forEach(([label, value]) => {
        let option = document.createElement("option");
        option.value = value;
        option.text = label;
        operatorSelect.appendChild(option);
      });

      // Restore previous value if it's still valid (check if value exists in operations values)
      let validValues = Object.values(operations);
      if (currentValue && validValues.includes(currentValue)) {
        operatorSelect.value = currentValue;
      }
    } catch (e) {
      console.error("Error updating operator dropdown:", e);
    }
  }

  #addConditionToGroup(group) {
    let group_index = this.groupsContainerTargets.indexOf(group);
    let condition_index = group.querySelectorAll(
      "fieldset[data-advanced-search-target='conditionsContainer']",
    ).length;
    let newCondition = this.conditionTemplateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index)
      .replace(/CONDITION_LEGEND_INDEX_PLACEHOLDER/g, condition_index + 1);
    group.lastElementChild.insertAdjacentHTML("beforebegin", newCondition);
    group.children[condition_index + 1].querySelector("select").focus();
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

  #announceValidationErrors() {
    if (!this.hasValidationStatusTarget) return;

    const errorElements = this.element.querySelectorAll(
      '[aria-invalid="true"], .invalid',
    );
    if (errorElements.length > 0) {
      const errorCount = errorElements.length;
      const errorMessage =
        errorCount === 1
          ? this.validationErrorOneValue
          : this.validationErrorOtherValue.replace("%{count}", String(errorCount));
      this.validationStatusTarget.textContent = errorMessage;
    }
  }
}
