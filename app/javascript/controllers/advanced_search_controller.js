import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "conditionsContainer",
    "conditionTemplate",
    "groupsContainer",
    "groupTemplate",
  ];

  connect() {
    this.addGroup();
  }

  idempotentConnect() {}

  submit() {
    this.element.requestSubmit();
  }

  addCondition(event) {
    event.currentTarget.parentElement.previousElementSibling.insertAdjacentHTML(
      "beforeend",
      this.conditionTemplateTarget.innerHTML,
    );
  }

  removeCondition(event) {
    event.currentTarget.parentElement.remove();
  }

  addGroup() {
    this.groupsContainerTarget.insertAdjacentHTML(
      "beforeend",
      this.groupTemplateTarget.innerHTML,
    );
    this.#addConditionToGroup(this.groupsContainerTarget.childElementCount - 1);
  }

  removeGroup(event) {
    if (this.groupsContainerTarget.childElementCount > 1) {
      event.currentTarget.parentElement.parentElement.remove();
    }
  }

  #addConditionToGroup(groupIndex) {
    this.conditionsContainerTargets[groupIndex].insertAdjacentHTML(
      "beforeend",
      this.conditionTemplateTarget.innerHTML,
    );
  }
}
