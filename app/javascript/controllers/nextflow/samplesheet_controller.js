import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select"];

  file_selected(event) {
    const updateSelect =
      event.target === this.selectTargets[0]
        ? this.selectTargets[1]
        : this.selectTargets[0];
    console.log(updateSelect);
    const index = [...event.target.options].findIndex((e) => e.selected);
    if (updateSelect.options.length > index) {
      updateSelect.options[index].selected = true;
    } else {
      updateSelect.value = "";
    }
  }
}
