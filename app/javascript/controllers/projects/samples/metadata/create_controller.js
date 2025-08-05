import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "metadataToAdd",
    "fieldsContainer",
    "fieldTemplate",
    "form",
  ];

  static values = {
    keyMissing: { type: String },
    valueMissing: { type: String },
  };

  #form_error_text_css = ["text-red-500"];

  #field_error_state = [
    "bg-slate-50",
    "border",
    "border-red-500",
    "text-slate-900",
    "text-sm",
    "rounded-lg",
    "block",
    "w-full",
    "p-2.5",
    "dark:bg-slate-700",
    "dark:border-slate-600",
    "dark:placeholder-slate-400",
    "dark:text-white",
  ];

  #field_valid_state = [
    "bg-slate-50",
    "border",
    "border-slate-300",
    "text-slate-900",
    "text-sm",
    "rounded-lg",
    "block",
    "w-full",
    "p-2.5",
    "dark:bg-slate-700",
    "dark:border-slate-600",
    "dark:placeholder-slate-400",
    "dark:text-white",
  ];

  #errors = [];

  connect() {
    this.addField();
  }

  // Add new field and replace the PLACEHOLDER with a current datetime for unique identifier
  addField() {
    const currentTime = new Date().getTime();
    let newField = this.fieldTemplateTarget.innerHTML.replace(
      /PLACEHOLDER/g,
      currentTime,
    );
    this.fieldsContainerTarget.insertAdjacentHTML("beforeend", newField);

    document.getElementById(`key[${currentTime}]`).focus();
  }

  removeField(event) {
    let key_id = event.target
      .closest(".inputField")
      .querySelector("div")
      .querySelector("input").id;
    event.target.closest(".inputField").remove();

    // Remove error messages div if inputField div is removed
    document.getElementById(key_id + "_field_errors").remove();

    this.#errors = this.#errors.filter(
      (item) => item.toString() !== key_id.toString(),
    );

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
        let metadata_field = input.querySelector(".keyInput");
        let value = input.querySelector(".valueInput");

        if (!metadata_field.value || !value.value) {
          if (!metadata_field.value) {
            this.#addFieldErrorState(
              metadata_field,
              "key_input",
              this.keyMissingValue,
            );
            if (this.#errors.indexOf(metadata_field.id) === -1) {
              this.#errors.push(metadata_field.id.toString());
            }
          } else if (metadata_field.value) {
            this.#removeFieldErrorState(metadata_field, "key_input");
          }

          if (!value.value) {
            this.#addFieldErrorState(
              value,
              "value_input",
              this.valueMissingValue,
            );
            if (this.#errors.indexOf(metadata_field.id) === -1) {
              this.#errors.push(metadata_field.id);
            }
          } else if (value.value) {
            this.#removeFieldErrorState(value, "value_input");
          }
        } else {
          if (this.#errors.includes(metadata_field.id)) {
            this.#removeFieldErrorState(
              metadata_field,
              "key_input",
              this.valueMissingValue,
            );
            this.#removeFieldErrorState(
              value,
              "value_input",
              this.valueMissingValue,
            );
            this.#errors = this.#errors.filter(
              (item) => item.toString() !== metadata_field.id.toString(),
            );
          }

          let metadataInput = `<input type='hidden' name="sample[create_fields][${metadata_field.value}]" value="${value.value}">`;
          this.metadataToAddTarget.insertAdjacentHTML(
            "beforeend",
            metadataInput,
          );
          metadata_field.name = "";
          value.name = "";
        }
      }

      if (this.#errors.length == 0) {
        this.formTarget.requestSubmit();
      }
    }, 50);
  }

  #addFieldErrorState(field, inputDivIdSuffix, errorMessage) {
    let field_id = field.id;
    let fieldError = document.getElementById(
      field_id + "_error",
    ).lastElementChild;
    let fieldErrorSpan = fieldError.getElementsByClassName("grow")[0];
    let keyField = document.getElementById(field_id + "_" + inputDivIdSuffix);
    field.setAttribute("aria-invalid", true);
    field.setAttribute("aria-describedBy", field_id + "_error");
    field.classList.remove(...this.#field_valid_state);
    field.classList.add(...this.#field_error_state);
    fieldError.classList.remove("hidden");
    fieldErrorSpan.innerHTML = errorMessage;
    fieldErrorSpan.classList.add(...this.#form_error_text_css);
    keyField.classList.add("invalid");
  }

  #removeFieldErrorState(field, inputDivIdSuffix) {
    let field_id = field.id;
    let fieldError = document.getElementById(
      field_id + "_error",
    ).lastElementChild;
    let fieldErrorSpan = fieldError.getElementsByClassName("grow")[0];
    let keyField = document.getElementById(field_id + "_" + inputDivIdSuffix);
    field.removeAttribute("aria-invalid");
    field.removeAttribute("aria-describedBy");
    field.classList.add(...this.#field_valid_state);
    field.classList.remove(...this.#field_error_state);
    fieldError.classList.add("hidden");
    fieldErrorSpan.innerHTML = "";
    fieldErrorSpan.classList.remove(...this.#form_error_text_css);
    keyField.classList.remove("invalid");
  }
}
