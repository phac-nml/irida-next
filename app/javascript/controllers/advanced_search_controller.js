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
    let groupContainer = event.currentTarget.parentElement.closest(
      "div[data-advanced-search-target='groupsContainer']",
    );
    let group_index = this.groupsContainerTargets.indexOf(groupContainer);
    let condition_index = groupContainer.querySelectorAll(
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
    event.currentTarget.parentElement.remove();
    //re-index all the form fields within the group
    let conditionContainers = groupContainer.querySelectorAll(
      "div[data-advanced-search-target='conditionsContainer']",
    );
    conditionContainers.forEach((conditionContainer, index) => {
      let inputFields = conditionContainer.querySelectorAll("[name]");
      inputFields.forEach((inputField) => {
        let updatedInputFieldName = inputField.name.replace(
          /(\[conditions_attributes\]\[)\d+?(\])/,
          "$1" + index + "$2",
        );
        inputField.name = updatedInputFieldName;
      });
    });
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
    let groupContainer = this.groupsContainerTargets[group_index];
    groupContainer.insertAdjacentHTML("afterbegin", newCondition);
  }

  removeGroup(event) {
    if (this.groupsContainerTarget.childElementCount > 1) {
      event.currentTarget.parentElement.parentElement.remove();
    }
    //re-index all the form fields within all the groups
    this.groupsContainerTargets.forEach((groupContainer, index) => {
      let inputFields = groupContainer.querySelectorAll("[name]");
      inputFields.forEach((inputField) => {
        let updatedInputFieldName = inputField.name.replace(
          /(\[groups_attributes\]\[)\d+?(\])/,
          "$1" + index + "$2",
        );
        inputField.name = updatedInputFieldName;
      });
    });
  }
}
