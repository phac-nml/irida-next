import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

export default class extends Controller {
  static outlets = ["selection"];

  appendSelectionLength(event) {
    const form = document.getElementById("launch-workflow-form");
    form.appendChild(
      createHiddenInput(
        "sample_count",
        this.selectionOutlet.getOrCreateStoredItems().length,
      ),
    );
  }
}
