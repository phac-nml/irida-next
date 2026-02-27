import { Controller } from "@hotwired/stimulus";
import { focusWhenVisible } from "utilities/focus";

export default class extends Controller {
  static targets = ["filter", "filterClearButton", "filterSearchButton"];

  static outlets = ["nextflow--deferred-samplesheet"];

  // when filtering samples, we will add the indexes of samples that fit the filter into the #currentSampleIndexes array.
  // we can then easily access each sample's data via its index and still paginate in pages of 5
  filter() {
    const filterValue = this.filterTarget.value;
    this.nextflowDeferredSamplesheetOutlet.applyFilter(filterValue);
    this.#updateFilterButtons(filterValue);
    focusWhenVisible(this.filterTarget);
  }

  clearFilter() {
    this.filterTarget.value = "";
    this.filter();
  }

  #updateFilterButtons(filterValue) {
    if (filterValue) {
      this.filterClearButtonTarget.classList.remove("hidden");
      this.filterSearchButtonTarget.classList.add("hidden");
    } else {
      this.filterClearButtonTarget.classList.add("hidden");
      this.filterSearchButtonTarget.classList.remove("hidden");
    }
  }
}
