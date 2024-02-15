import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select"];

  connect() {
    this.#updateSelectInput(1, this.selectTargets[0].options[0]);
  }

  file_selected(event) {
    const updateIndex = event.target === this.selectTargets[0] ? 1 : 0;
    const selectedOption = event.target.options[event.target.options.selectedIndex];
    this.#updateSelectInput(updateIndex, selectedOption);
  }

  #updateSelectInput(updateIndex, selectedOption) {
    const { associatedId } = selectedOption.dataset;

    if (associatedId) {
      // Since there is an associatedId, we need to update the opposite select with its pair.
      const option = [...this.selectTargets[updateIndex].options].find(o => o.value.endsWith(associatedId));
      this.selectTargets[updateIndex].value = option.value;
    } else {
      // Since no associated id, this is a single file and does not need a matching pair.
      this.selectTargets[updateIndex].value = "";
    }
  }
}
