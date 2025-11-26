import { Controller } from "@hotwired/stimulus";
import { createHiddenInput } from "utilities/form";

// Handles sending metadata to samplesheet after metadata selection
export default class extends Controller {
  static values = {
    namespaceId: { type: String },
    fields: { type: Array },
    workflowName: { type: String },
    workflowVersion: { type: String },
  };

  static targets = ["samplesheetParamsForm"];
  static outlets = ["nextflow--samplesheet--render", "selection"];

  connect() {
    console.log(this.namespaceIdValue);
    console.log(this.fieldsValue);
    console.log(this.workflowNameValue);
    console.log(this.workflowVersionValue);
  }

  submitSamplesheetParams(schema) {
    console.log(schema);
    const fragment = document.createDocumentFragment();
    for (const id of this.selectionOutlet.getOrCreateStoredItems()) {
      fragment.appendChild(createHiddenInput("sample_ids[]", id));
    }

    for (const field of this.fieldsValue) {
      fragment.appendChild(createHiddenInput("fields[]", field));
    }
    fragment.appendChild(
      createHiddenInput("namespace_id", this.namespaceIdValue),
    );

    fragment.appendChild(
      createHiddenInput("workflow_name", this.workflowNameValue),
    );

    fragment.appendChild(
      createHiddenInput("workflow_version", this.workflowVersionValue),
    );

    fragment.appendChild(createHiddenInput("schema", JSON.stringify(schema)));

    this.samplesheetParamsFormTarget.appendChild(fragment);
    this.samplesheetParamsFormTarget.submit();
  }
}
