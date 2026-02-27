import { Controller } from "@hotwired/stimulus";
import { formDataToJsonParams } from "utilities/form";

export default class extends Controller {
  static outlets = [
    "nextflow--deferred-samplesheet",
    "nextflow--samplesheet--templates",
  ];

  #metadataParameterUpdatedState = [
    "ring-2",
    "ring-primary-500",
    "dark:ring-primary-600",
  ];

  #samplesheetReady = false;
  #queuedMetadataChanges = {};

  connect() {
    this.#updateMetadataColumnHeaderNames();
  }

  #updateMetadataColumnHeaderNames() {
    // Update the values for the fields under 'The column header names of the metadata columns'
    const metadataSamplesheetColumns = this.element.querySelectorAll(
      ".metadata_field-header",
    );

    metadataSamplesheetColumns.forEach((metadataSamplesheetColumn) => {
      const columnName = metadataSamplesheetColumn.getAttribute(
        "data-metadata-header",
      );
      const metadataField = metadataSamplesheetColumn.value;

      const metadataParameter = this.element.querySelector(
        `input[data-metadata-header-name="${columnName}"]`,
      );

      if (metadataParameter && metadataParameter.value !== metadataField) {
        metadataParameter.value = metadataField;
      }
    });
  }

  handleMetadataSelection(event) {
    const metadataSamplesheetColumn = event.target.getAttribute(
      "data-metadata-header",
    );
    const metadataField = event.target.value;
    const metadataParameter = document.querySelector(
      `input[data-metadata-header-name="${metadataSamplesheetColumn}"]`,
    );

    // updates parameter below samplesheet if it exists
    if (metadataParameter) {
      metadataParameter.value = metadataField;
      metadataParameter.classList.add(...this.#metadataParameterUpdatedState);

      setTimeout(() => {
        metadataParameter.classList.remove(
          ...this.#metadataParameterUpdatedState,
        );
      }, 1000);
    }

    // for large sample batches, users will be able to select metadata headers prior to the samplesheet loading in
    // we will add those changes to the #queuedMetadataChanges object, and that will be submitted once
    // the samplesheet is ready
    if (this.#samplesheetReady) {
      this.#submitMetadataChange({
        [metadataSamplesheetColumn]: metadataField,
      });
    } else {
      this.#queuedMetadataChanges[metadataSamplesheetColumn] = metadataField;
    }
  }

  #submitMetadataChange(metadataParams) {
    const metadataFormContent =
      this.nextflowSamplesheetTemplatesOutlet.cloneTemplate(
        "metadataHeaderForm",
      );

    const filledMetadataForm = this.#appendInputsToMetadataForm(
      metadataFormContent,
      metadataParams,
    );
    // we need to find the most outer container, which is out of scope of this controller, to not create nested forms
    const nextflowContainer = document.getElementById("nextflow-container");
    nextflowContainer.appendChild(filledMetadataForm);
    nextflowContainer.lastElementChild.addEventListener(
      "turbo:before-fetch-request",
      (event) => {
        event.detail.fetchOptions.body = JSON.stringify(
          formDataToJsonParams(
            new FormData(nextflowContainer.lastElementChild),
          ),
        );
        event.detail.fetchOptions.headers["Content-Type"] = "application/json";

        event.detail.resume();
      },
      {
        once: true,
      },
    );
    nextflowContainer.lastElementChild.requestSubmit();
    nextflowContainer.lastElementChild.remove();
  }

  #appendInputsToMetadataForm(metadataFormContent, metadataParams) {
    // add turbo_stream, which metadata column and the selected metadata field inputs
    const formInputValues = [
      {
        name: "format",
        value: "turbo_stream",
      },
      {
        name: "metadata_fields",
        value: JSON.stringify(metadataParams),
      },
      {
        name: "sample_ids",
        value: this.nextflowDeferredSamplesheetOutlet.retrieveSampleIds(),
      },
    ];

    const form = metadataFormContent.querySelector("form");
    formInputValues.forEach((inputValue) => {
      form.appendChild(this.#createMetadataFormInput(inputValue));
    });

    return metadataFormContent;
  }

  #createMetadataFormInput(inputValue) {
    const input = document.createElement("input");
    input.setAttribute("name", inputValue["name"]);
    input.setAttribute("value", inputValue["value"]);
    input.setAttribute("type", "hidden");
    return input;
  }

  samplesheetReady() {
    this.#samplesheetReady = true;
    const metadataChanges = { ...this.#queuedMetadataChanges };
    if (Object.keys(metadataChanges).length > 0) {
      this.#submitMetadataChange(metadataChanges);
      this.#queuedMetadataChanges = {};
    }
  }
}
