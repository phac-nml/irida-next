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
  #hidden_classes = ["invisible", "@max-xl:hidden"];

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

    if (["", "exists", "not_exists"].includes(operator)) {
      value.classList.add(...this.#hidden_classes);
      let inputs = value.querySelectorAll("input");
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
}
