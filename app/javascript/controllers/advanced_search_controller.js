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
  ];
  static outlets = ["list-filter"];
  static values = {
    confirmCloseText: String,
  };

  connect() {
    this.idempotentConnect();
  }

  idempotentConnect() {
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
    }
    else if (!this.#dirty()) {
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

  addGroup() {
    let group_index = this.groupsContainerTargets.length;
    this.searchGroupsContainerTarget.insertAdjacentHTML(
      "beforeend",
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
    this.clear();
    this.addGroup();
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

    if (["", "exists", "not_exists"].includes(operator)) {
      value.classList.add("invisible");
      let inputs = value.querySelectorAll("input");
      inputs.forEach((input) => {
        input.value = "";
      });
    } else if (["in", "not_in"].includes(operator)) {
      value.classList.remove("invisible");
      value.outerHTML = this.listValueTemplateTarget.innerHTML
        .replace(/GROUP_INDEX_PLACEHOLDER/g, group_index)
        .replace(/CONDITION_INDEX_PLACEHOLDER/g, condition_index);
    } else {
      value.classList.remove("invisible");
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

  #dirty() {
    let dirty = true;
    if (this.searchGroupsContainerTarget.innerHTML.trim() === this.searchGroupsTemplateTarget.innerHTML.trim()) {
      dirty = false;
      const currentInputs = this.searchGroupsContainerTarget.querySelectorAll("[id^='q_groups_attributes_']");
      const originalInputs = this.searchGroupsTemplateTarget.content.querySelectorAll("[id^='q_groups_attributes_']");
      originalInputs.forEach((item, index) => {
        if (item.value !== currentInputs[index].value) {
          dirty = true;
        }
      });
    }
    return dirty;
  }
}
