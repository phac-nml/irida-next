import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
  static outlets = ["selection"];

  appendSelectionCount() {
    const form = this.element.closest("form");

    form.appendChild(
      createHiddenInput(
        "sample_count",
        this.selectionOutlet.getOrCreateStoredItems().length,
      ),
    );
  }
}
