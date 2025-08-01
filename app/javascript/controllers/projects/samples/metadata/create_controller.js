import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["metadataToAdd", "fieldsContainer", "fieldTemplate"];

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

    // If only one field existed and was deleted, we re-add a new field
    if (document.querySelectorAll(".inputField").length == 0) {
      this.addField();
    }
  }

  // Metadata is constructed and validated before submission to the backend. Any fields that has key and/or value blank,
  // we ignore and do not submit those fields.
  buildMetadata(event) {
    event.preventDefault();
    const inputFields = document.querySelectorAll(".inputField");
    let errors = [];
    for (let input of inputFields) {
      let metadata_field = input.querySelector(".keyInput");
      let value = input.querySelector(".valueInput");

      if (metadata_field.value === "" || value.value === "") {
        if (errors.indexOf(metadata_field.value) === -1) {
          errors.push(metadata_field.value);
        }
        if (metadata_field.value === "") {
          this.#addKeyFieldErrorState(metadata_field);
        } else if (metadata_field.value !== "") {
          this.#removeKeyFieldErrorState(metadata_field);
        }

        if (value.value === "") {
          this.#addValueFieldErrorState(value);
        } else if (value.value !== "") {
          this.#removeValueFieldErrorState(value);
        }
      } else {
        this.#removeKeyFieldErrorState(metadata_field);
        this.#removeValueFieldErrorState(value);
        errors.pop(metadata_field.value);

        let metadataInput = `<input type='hidden' name="sample[create_fields][${metadata_field.value}]" value="${value.value}">`;
        this.metadataToAddTarget.insertAdjacentHTML("beforeend", metadataInput);
        metadata_field.name = "";
        value.name = "";
      }
    }
    if (errors.length == 0) {
      this.submit(event);
    }
  }

  submit(event) {
    let form = event.target.closest("form");
    form.requestSubmit();
  }

  #addKeyFieldErrorState(metadata_field) {
    let field_id = metadata_field.id;
    let fieldError = document.getElementById(
      field_id + "_error",
    ).lastElementChild;
    let fieldErrorSpan = fieldError.getElementsByClassName("grow")[0];
    let keyField = document.getElementById(field_id + "_key_input");
    metadata_field.setAttribute("aria-invalid", true);
    metadata_field.setAttribute("aria-describedBy", field_id + "_error");
    metadata_field.classList.remove(...this.#field_valid_state);
    metadata_field.classList.add(...this.#field_error_state);
    fieldError.classList.remove("hidden");
    fieldErrorSpan.innerHTML = this.keyMissingValue;
    fieldErrorSpan.classList.add(...this.#form_error_text_css);
    keyField.classList.add("invalid");
  }

  #removeKeyFieldErrorState(metadata_field) {
    let field_id = metadata_field.id;
    let fieldError = document.getElementById(
      field_id + "_error",
    ).lastElementChild;
    let fieldErrorSpan = fieldError.getElementsByClassName("grow")[0];
    let keyField = document.getElementById(field_id + "_key_input");
    metadata_field.removeAttribute("aria-invalid");
    metadata_field.removeAttribute("aria-describedBy");
    metadata_field.classList.add(...this.#field_valid_state);
    metadata_field.classList.remove(...this.#field_error_state);
    fieldError.classList.add("hidden");
    fieldErrorSpan.innerHTML = "";
    fieldErrorSpan.classList.remove(...this.#form_error_text_css);
    keyField.classList.remove("invalid");
  }

  #addValueFieldErrorState(value_field) {
    let field_id = value_field.id;
    let fieldError = document.getElementById(
      field_id + "_error",
    ).lastElementChild;
    let fieldErrorSpan = fieldError.getElementsByClassName("grow")[0];
    let valueField = document.getElementById(field_id + "_value_input");
    value_field.setAttribute("aria-invalid", true);
    value_field.setAttribute("aria-describedBy", field_id + "_error");
    value_field.classList.remove(...this.#field_valid_state);
    value_field.classList.add(...this.#field_error_state);
    fieldError.classList.remove("hidden");
    fieldErrorSpan.innerHTML = this.valueMissingValue;
    fieldErrorSpan.classList.add(...this.#form_error_text_css);
    valueField.classList.add("invalid");
  }

  #removeValueFieldErrorState(value_field) {
    let field_id = value_field.id;
    let fieldError = document.getElementById(
      field_id + "_error",
    ).lastElementChild;
    let fieldErrorSpan = fieldError.getElementsByClassName("grow")[0];
    let valueField = document.getElementById(field_id + "_value_input");
    value_field.removeAttribute("aria-invalid");
    value_field.removeAttribute("aria-describedBy");
    value_field.classList.add(...this.#field_valid_state);
    value_field.classList.remove(...this.#field_error_state);
    fieldError.classList.add("hidden");
    fieldErrorSpan.innerHTML = "";
    fieldErrorSpan.classList.remove(...this.#form_error_text_css);
    valueField.classList.remove("invalid");
  }
}
