import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select"];

  file_selected(event) {
    const updateSelectIndex = event.target === this.selectTargets[0] ? 1 : 0;
    const index = [...event.target.options].findIndex((e) => e.selected);
    if (this.selectTargets[updateSelectIndex].options.length > index) {
      this.selectTargets[updateSelectIndex].options[index].selected = true;
    } else {
      this.seletTarget[updateSelectIndex].value = "";
    }
  }
}
