import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "conditionsContainer", //many
    "conditionTemplate",
    "groupsContainer",
    "groupTemplate",
  ];

  connect() {
    this.addGroup();
    this.addCondition();
  }

  idempotentConnect() {}

  submit() {
    this.element.requestSubmit();
  }

  addCondition(event) {
    console.log("add condition");
    // console.log(this.conditionTemplateTargets.length);
    if (event) {
      console.log(event.currentTarget.parentElement);
      console.log(
        event.currentTarget.parentElement.parentElement.closest("template"),
      );
      event.currentTarget.parentElement.previousElementSibling.insertAdjacentHTML(
        "beforeend",
        this.conditionTemplateTarget.innerHTML,
      );
    } else {
      this.conditionsContainerTarget.insertAdjacentHTML(
        "beforeend",
        this.conditionTemplateTarget.innerHTML,
      );
    }
  }

  removeCondition(event) {
    event.currentTarget.parentElement.remove();
  }

  addGroup() {
    this.groupsContainerTarget.insertAdjacentHTML(
      "beforeend",
      this.groupTemplateTarget.innerHTML,
    );
  }
}
