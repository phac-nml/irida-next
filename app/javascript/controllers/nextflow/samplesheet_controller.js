import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "selectForward",
    "selectReverse",
    "table",
    "loading",
    "submit",
  ];

  connect() {
    this.element.addEventListener("turbo:submit-start", (event) => {
      this.submitTarget.disabled = true;
      if (this.hasTableTarget) {
        this.tableTarget.appendChild(
          this.loadingTarget.content.cloneNode(true),
        );
      }
    });

    this.element.addEventListener("turbo:submit-end", (event) => {
      this.submitTarget.disabled = false;
      if (this.hasTableTarget) {
        this.tableTarget.removeChild(this.tableTarget.lastElementChild);
      }
    });
  }

  file_selected(event) {
    // find the selected option from the event target select
    const { index, direction } = event.target.dataset;
    const { puid } = event.target.options[event.target.selectedIndex].dataset;
    const selectToUpdate =
      direction === "pe_forward"
        ? this.selectReverseTargets[index]
        : this.selectForwardTargets[index];

    this.#updateMatchingSelect(selectToUpdate, puid);
  }

  #updateMatchingSelect(updateSelect, puid) {
    const index = [...updateSelect.options].findIndex(
      (options) => options.dataset.puid === puid,
    );
    if (index > -1) {
      updateSelect.options[index].selected = true;
    }
  }
}
