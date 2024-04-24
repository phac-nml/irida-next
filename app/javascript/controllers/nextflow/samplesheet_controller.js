import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["select"];

  file_selected(event) {
    console.log(event.target);
  }

  // connect() {
  //   if (this.hasSelectTarget) {
  //     // Find the first select selectedIndex
  //     const selectedOption =
  //       this.selectTargets[0].options[this.selectTargets[0].selectedIndex];
  //     if (selectedOption) {
  //       this.#updateMatchingSelect(
  //         this.selectTargets[1],
  //         selectedOption.dataset.puid,
  //       );
  //     }
  //   }
  // }

  // file_selected(event) {
  //   // find the selected option from the event target select
  //   const selectedOption = event.target.options[event.target.selectedIndex];

  //   const updateSelect =
  //     event.target === this.selectTargets[0]
  //       ? this.selectTargets[1]
  //       : this.selectTargets[0];

  //   this.#updateMatchingSelect(updateSelect, selectedOption.dataset.puid);
  // }

  // #updateMatchingSelect(updateSelect, puid) {
  //   const index = [...updateSelect.options].findIndex(
  //     (options) => options.dataset.puid === puid,
  //   );

  //   if (index > -1) {
  //     updateSelect.options[index].selected = true;
  //   }
  // }
}
