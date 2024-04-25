import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["selectForward", "selectReverse", "loading", "submit"];

  connect() {
    let select;
    this.element.addEventListener("turbo:submit-start", (event) => {
      this.submitTarget.disabled = true;
      select = event.target.querySelector("select");
      select.disabled = true;
      event.target.closest(".table-column").querySelector(".table-col").replaceChildren(this.loadingTarget.content.cloneNode(true));
    });

    this.element.addEventListener("turbo:submit-end", (event) => {
      this.submitTarget.disabled = false;
      select.disabled = false;
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

  update_metadata_field(event) {
    console.log(event);
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
