import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select"];

  file_selected(event) {
    // find the selected option from the event target select
    const selectedOption = event.target.options[event.target.selectedIndex];

    if (selectedOption.value) return;

    const updateSelect =
      event.target === this.selectTargets[0]
        ? this.selectTargets[1]
        : this.selectTargets[0];

    const index = [...updateSelect.options].findIndex(
      (options) => options.dataset.puid === selectedOption.dataset.puid,
    );

    if (index > -1) {
      updateSelect.options[index].selected = true;
    }
  }
}
