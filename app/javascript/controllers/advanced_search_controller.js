import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "conditionsContainer",
    "conditionTemplate",
    "groupsContainer",
    "groupTemplate",
  ];

  connect() {}

  idempotentConnect() {}

  addCondition(event) {
    let group = event.currentTarget.parentElement.closest(
      "div[data-advanced-search-target='groupsContainer']",
    );
    let group_index = this.groupsContainerTargets.indexOf(group);
    let condition_index = group.querySelectorAll(
      "div[data-advanced-search-target='conditionsContainer']",
    ).length;
    let newCondition = this.conditionTemplateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
    event.currentTarget.parentElement.insertAdjacentHTML(
      "beforebegin",
      newCondition,
    );
  }

  removeCondition(event) {
    let groupContainer = event.currentTarget.parentElement.closest(
      "div[data-advanced-search-target='groupsContainer']",
    );
    let conditions = groupContainer.querySelectorAll(
      "div[data-advanced-search-target='conditionsContainer']",
    );
    if (conditions.length > 1) {
      event.currentTarget.parentElement.remove();
      conditions = groupContainer.querySelectorAll(
        "div[data-advanced-search-target='conditionsContainer']",
      );
      //re-index all the form fields within the group
      conditions.forEach((condition, index) => {
        let inputFields = condition.querySelectorAll("[name]");
        inputFields.forEach((inputField) => {
          let updatedInputFieldName = inputField.name.replace(
            /(\[conditions_attributes\]\[)\d+?(\])/,
            "$1" + index + "$2",
          );
          inputField.name = updatedInputFieldName;
        });
      });
    }
  }

  addGroup(event) {
    let group_index = this.groupsContainerTargets.length;
    event.currentTarget.parentElement.insertAdjacentHTML(
      "beforebegin",
      this.groupTemplateTarget.innerHTML,
    );
    let newCondition = this.conditionTemplateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, 0);
    let group = this.groupsContainerTargets[group_index];
    group.insertAdjacentHTML("afterbegin", newCondition);
  }

  removeGroup(event) {
    if (this.groupsContainerTargets.length > 1) {
      event.currentTarget.parentElement.parentElement.remove();
    }
    //re-index all the form fields within all the groups
    this.groupsContainerTargets.forEach((group, index) => {
      let inputFields = group.querySelectorAll("[name]");
      inputFields.forEach((inputField) => {
        let updatedInputFieldName = inputField.name.replace(
          /(\[groups_attributes\]\[)\d+?(\])/,
          "$1" + index + "$2",
        );
        inputField.name = updatedInputFieldName;
      });
    });
  }

  clearForm() {
    this.groupsContainerTargets.forEach((group, group_index) => {
      if (group_index > 0) {
        group.remove();
      } else {
        let conditions = group.querySelectorAll(
          "div[data-advanced-search-target='conditionsContainer']",
        );
        conditions.forEach((condition, condition_index) => {
          if (condition_index > 0) {
            condition.remove();
          } else {
            let input = condition.querySelector("input");
            input.value = "";
            let selects = condition.querySelectorAll("select");
            selects.forEach((select) => {
              select.value = "";
            });
          }
        });
      }
    });
  }
}
