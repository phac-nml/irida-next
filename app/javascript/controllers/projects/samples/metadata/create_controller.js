import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "metadataToAdd",
    "fieldsContainer",
    "fieldTemplate",
    "form",
    "formFieldError",
    "formFieldErrorMessage",
  ];

  static values = {
    keyMissing: { type: String },
    valueMissing: { type: String },
    formError: { type: String },
  };

  #errors = [];
  #fieldCounter = 0;

  connect() {
    this.addField();
  }

  // Add new field and replace the PLACEHOLDER with a counter for unique identifier
  addField() {
    const fieldId = this.#fieldCounter++;
    let newField = this.fieldTemplateTarget.innerHTML.replace(
      /PLACEHOLDER/g,
      fieldId,
    );
    this.fieldsContainerTarget.insertAdjacentHTML("beforeend", newField);

    // Focus on the key input field of the newly added field
    const newKeyInput = document.getElementById(`key_${fieldId}`);
    if (newKeyInput) {
      newKeyInput.focus();
    }
  }

  removeField(event) {
    const inputFieldDiv = event.target.closest(".inputField");
    const keyInput = inputFieldDiv.querySelector("input[id^='key_']");
    const key_id = keyInput.id;

    inputFieldDiv.remove();

    // Remove error messages div if inputField div is removed
    const errorDiv = document.getElementById(key_id + "_field_errors");
    if (errorDiv) {
      errorDiv.remove();
    }

    // Remove metadata field from errors if it was removed from the DOM
    this.#removeMetadataKeyIdFromErrors(key_id);

    // If only one field existed and was deleted, we re-add a new field
    if (document.querySelectorAll(".inputField").length == 0) {
      this.addField();
    }
  }

  // Metadata is constructed and validated before submission to the backend.
  buildMetadata(event) {
    event.preventDefault();
    const inputFields = document.querySelectorAll(".inputField");

    setTimeout(() => {
      for (let input of inputFields) {
        let metadata_field = input.querySelector("input[id^='key_']");
        let value_field = input.querySelector("input[id^='value_']");

        if (!metadata_field.value || !value_field.value) {
          // If either key or value is blank render error states for the field
          // which is blank
          this.#renderKeyFieldState(metadata_field);
          this.#renderValueFieldState(value_field, metadata_field.id);
        } else {
          // No errors for key or value so we remove the error states and remove
          // the metadata field from the errors
          if (this.#errors.includes(metadata_field.id)) {
            this.#removeFieldErrorState(metadata_field);
            this.#removeFieldErrorState(value_field);
            this.#removeMetadataKeyIdFromErrors(metadata_field.id);
          }
          this.#addMetadataFieldHiddenInput(metadata_field, value_field);
        }
      }

      // If no metadata field ids remain, submit the form
      if (this.#errors.length == 0) {
        this.#disableFormFieldErrorState();
        this.formTarget.requestSubmit();
      } else {
        this.#enableFormFieldErrorState(this.formErrorValue);
      }
    }, 50);
  }

  // Add hidden input for metadata field. If multiple fields with same values
  // are added to the same form, the last key/value pair will be the metadata
  // that gets added
  #addMetadataFieldHiddenInput(metadata_field, value_field) {
    // check if hidden input was already added for metadatafield key
    let hiddenInput = document.querySelector(
      `input[name="sample[create_fields][${metadata_field.value}]"`,
    );

    let metadataInput = `<input type='hidden' name="sample[create_fields][${metadata_field.value}]" value="${value_field.value}">`;

    if (hiddenInput) {
      let value = hiddenInput.value;
      if (value_field.value !== value) {
        hiddenInput.value = value_field.value;
      }
    } else {
      this.metadataToAddTarget.insertAdjacentHTML("beforeend", metadataInput);
      metadata_field.name = "";
      value_field.name = "";
    }
  }

  // Add metadata field id to errors array
  #addMetadataKeyIdToErrors(metadata_field_id) {
    if (this.#errors.indexOf(metadata_field_id) === -1) {
      this.#errors.push(metadata_field_id);
    }
  }

  // Remove metadata field id from errors array
  #removeMetadataKeyIdFromErrors(metadata_field_id) {
    this.#errors = this.#errors.filter((item) => item !== metadata_field_id);
  }

  // Render key field error state if key is blank
  // otherwise check if field has previously displayed
  // errors and then remove them if so
  #renderKeyFieldState(metadata_field) {
    if (!metadata_field.value) {
      this.#addFieldErrorState(
        metadata_field,
        this.keyMissingValue,
      );
      this.#addMetadataKeyIdToErrors(metadata_field.id);
    } else if (metadata_field.value) {
      this.#removeFieldErrorState(metadata_field);
    }
  }

  // Render value field error state if value is blank
  // otherwise check if field has previously displayed
  // errors and then remove them if so
  #renderValueFieldState(value_field, metadata_field_id) {
    if (!value_field.value) {
      this.#addFieldErrorState(
        value_field,
        this.valueMissingValue,
      );
      this.#addMetadataKeyIdToErrors(metadata_field_id);
    } else if (value_field.value) {
      this.#removeFieldErrorState(value_field);
    }
  }

  // Hide general error message alert
  #disableFormFieldErrorState() {
    this.formFieldErrorTarget.classList.add("hidden");
    this.formFieldErrorMessageTarget.innerHTML = "";
  }

  // Display general error message alert
  #enableFormFieldErrorState(message) {
    this.formFieldErrorTarget.classList.remove("hidden");
    this.formFieldErrorMessageTarget.innerHTML = message;
    this.formFieldErrorTarget.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
  }

  // Display input field error state with error messages for field
  #addFieldErrorState(field, errorMessage) {
    let field_id = field.id;
    let fieldError = document.getElementById(field_id + "_error");
    let helpTextComponent = fieldError?.querySelector('.viral-help-text');
    let inputDiv = field.closest('.form-field');

    if (helpTextComponent && helpTextComponent.textContent.trim() === errorMessage) {
      // Errors are already displayed for this field so we exit early
      return;
    }

    field.setAttribute("aria-invalid", true);
    field.setAttribute("aria-describedBy", field_id + "_error");

    // Update field styling for the new floating label form structure
    field.classList.remove("border-slate-300", "dark:border-slate-600");
    field.classList.add("border-red-500", "dark:border-red-500");

    if (fieldError) {
      fieldError.classList.remove("hidden");
    }
    if (helpTextComponent) {
      helpTextComponent.textContent = errorMessage;
      helpTextComponent.classList.remove("hidden");
    }
    if (inputDiv) {
      inputDiv.classList.add("invalid");
    }
  }

  // Remove input field error state and error messages for field
  #removeFieldErrorState(field) {
    let field_id = field.id;
    let fieldError = document.getElementById(field_id + "_error");
    let helpTextComponent = fieldError?.querySelector('.viral-help-text');
    let inputDiv = field.closest('.form-field');

    if (helpTextComponent && helpTextComponent.textContent.trim() === "") {
      // Errors are not displayed for this field so we exit early
      return;
    }

    field.removeAttribute("aria-invalid");
    field.removeAttribute("aria-describedBy");

    // Reset field styling for the new floating label form structure
    field.classList.remove("border-red-500", "dark:border-red-500");
    field.classList.add("border-slate-300", "dark:border-slate-600");

    if (fieldError) {
      fieldError.classList.add("hidden");
    }
    if (helpTextComponent) {
      helpTextComponent.textContent = "";
      helpTextComponent.classList.add("hidden");
    }
    if (inputDiv) {
      inputDiv.classList.remove("invalid");
    }
  }
}
