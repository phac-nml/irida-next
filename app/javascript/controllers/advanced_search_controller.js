import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "conditionsContainer",
    "conditionTemplate",
    "groupsContainer",
    "groupTemplate",
    "valueTemplate",
    "listValueTemplate",
  ];
  static outlets = ["list-filter"];

  connect() {}

  idempotentConnect() {
    this.listFilterOutlets.forEach((outlet) => {
      outlet.idempotentConnect();
    });
  }

  addCondition(event) {
    let group = event.currentTarget.parentElement.closest(
      "div[data-advanced-search-target='groupsContainer']",
    );
    this.#addConditionToGroup(group);
  }

  removeCondition(event) {
    let condition = event.currentTarget.parentElement;
    let group = condition.closest(
      "div[data-advanced-search-target='groupsContainer']",
    );
    let conditions = group.querySelectorAll(
      "div[data-advanced-search-target='conditionsContainer']",
    );

    condition.remove();
    conditions = group.querySelectorAll(
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
    if (conditions.length === 0) {
      this.#addConditionToGroup(group);
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
    this.groupsContainerTargets.forEach((group, group_index) => {
      if (group_index > 0) {
        group.remove();
      } else {
        let conditions = group.querySelectorAll(
          "div[data-advanced-search-target='conditionsContainer']",
        );
        conditions.forEach((condition) => {
          condition.remove();
        });
        this.#addConditionToGroup(group);
      }
    });
  }

  handleOperatorChange(event) {
    let operator = event.target.value;
    let condition = event.target.parentElement.closest(
      "div[data-advanced-search-target='conditionsContainer']",
    );
    let value = condition.querySelector(".value");
    let group = condition.parentElement;
    let group_index = this.groupsContainerTargets.indexOf(group);
    let condition_index = [
      ...group.querySelectorAll(
        "div[data-advanced-search-target='conditionsContainer']",
      ),
    ].indexOf(condition);

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

  #addConditionToGroup(group) {
    let group_index = this.groupsContainerTargets.indexOf(group);
    let condition_index = group.querySelectorAll(
      "div[data-advanced-search-target='conditionsContainer']",
    ).length;
    let newCondition = this.conditionTemplateTarget.innerHTML
      .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
      .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
    group.lastElementChild.insertAdjacentHTML("beforebegin", newCondition);
  }
}
