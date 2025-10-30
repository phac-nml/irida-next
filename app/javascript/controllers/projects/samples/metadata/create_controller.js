import { Controller } from "@hotwired/stimulus";

/**
 * Metadata Create Controller
 *
 * Manages a dynamic metadata form where users can add/remove key-value field pairs,
 * validate fields before submission, show error states, and submit metadata as hidden form inputs.
 *
 * Features:
 * - Dynamic field addition/removal with unique ID generation
 * - Real-time field validation with error display
 * - Automatic focus management for improved UX
 * - Hidden input generation for form submission
 * - Comprehensive error state management
 *
 * @extends Controller
 */
export default class extends Controller {
  // ====================================================================
  // STIMULUS CONFIGURATION
  // ====================================================================

  static targets = [
    "metadataToAdd", // Container for hidden inputs
    "fieldsContainer", // Container for dynamic field pairs
    "fieldTemplate", // Template for new field pairs
    "form", // Main form element
    "formFieldError", // General error alert container
    "formFieldErrorMessage", // General error message element
  ];

  static values = {
    keyMissing: { type: String }, // Error message for missing key
    valueMissing: { type: String }, // Error message for missing value
    formError: { type: String }, // General form error message
  };

  // ====================================================================
  // PRIVATE PROPERTIES
  // ====================================================================

  /** @type {string[]} Array of field IDs currently in error state */
  #errorFieldIds = [];

  /** @type {number} Counter for generating unique field IDs */
  #fieldIdCounter = 0;

  // ====================================================================
  // LIFECYCLE METHODS
  // ====================================================================

  /**
   * Initialize controller when connected to DOM
   * Adds an initial empty field for user input
   */
  connect() {
    this.#addInitialField();
  }

  // ====================================================================
  // PUBLIC EVENT HANDLERS
  // ====================================================================

  /**
   * Add a new key-value field pair to the form
   * Creates unique IDs using counter and focuses the key input
   */
  addField() {
    try {
      const fieldId = this.#generateFieldId();
      const fieldHtml = this.#createFieldFromTemplate(fieldId);

      this.#insertFieldIntoContainer(fieldHtml);
      this.#focusNewKeyInput(fieldId);
    } catch (error) {
      console.error("Error adding field:", error);
    }
  }

  /**
   * Remove a field pair from the form
   * Cleans up associated error states and ensures at least one field remains
   *
   * @param {Event} event - The click event from the remove button
   */
  removeField(event) {
    try {
      const fieldContainer = this.#findFieldContainer(event.target);
      const keyInput = this.#findKeyInput(fieldContainer);

      if (!keyInput) {
        console.warn("Could not find key input for field removal");
        return;
      }

      const keyId = keyInput.id;

      this.#removeFieldFromDOM(fieldContainer, keyId);
      this.#removeFieldFromErrors(keyId);
      this.#ensureMinimumFields();
    } catch (error) {
      console.error("Error removing field:", error);
    }
  }

  /**
   * Build and validate metadata before form submission
   * Prevents default submission, validates all fields, and submits if valid
   *
   * @param {Event} event - The form submit event
   */
  buildMetadata(event) {
    event.preventDefault();

    // Use setTimeout to ensure DOM updates are processed before validation
    setTimeout(() => {
      try {
        this.#processAllMetadataFields();
        this.#submitFormIfValid();
      } catch (error) {
        console.error("Error building metadata:", error);
        this.#showFormError(this.formErrorValue);
      }
    }, 50);
  }

  // ====================================================================
  // FIELD MANAGEMENT (PRIVATE)
  // ====================================================================

  /**
   * Add initial field when controller connects
   */
  #addInitialField() {
    this.addField();
  }

  /**
   * Generate unique field ID using counter
   * @returns {number} Unique field identifier
   */
  #generateFieldId() {
    return this.#fieldIdCounter++;
  }

  /**
   * Create field HTML from template with unique ID
   * @param {number} fieldId - Unique identifier for the field
   * @returns {string} HTML string for the new field
   */
  #createFieldFromTemplate(fieldId) {
    if (!this.fieldTemplateTarget?.innerHTML) {
      throw new Error("Field template not found or empty");
    }

    return this.fieldTemplateTarget.innerHTML.replace(/PLACEHOLDER/g, fieldId);
  }

  /**
   * Insert field HTML into the container
   * @param {string} fieldHtml - HTML string to insert
   */
  #insertFieldIntoContainer(fieldHtml) {
    this.fieldsContainerTarget.insertAdjacentHTML("beforeend", fieldHtml);
  }

  /**
   * Focus on the key input of newly added field
   * @param {number} fieldId - ID of the field to focus
   */
  #focusNewKeyInput(fieldId) {
    const keyInput = document.getElementById(`key_${fieldId}`);
    keyInput?.focus();
  }

  /**
   * Find the field container element from event target
   * @param {Element} target - Event target element
   * @returns {Element} Field container element
   */
  #findFieldContainer(target) {
    const container = target.closest(".inputField");
    if (!container) {
      throw new Error("Could not find field container");
    }
    return container;
  }

  /**
   * Find key input within field container
   * @param {Element} container - Field container element
   * @returns {Element|null} Key input element
   */
  #findKeyInput(container) {
    return container.querySelector("input[id^='key_']");
  }

  /**
   * Remove field and associated error elements from DOM
   * @param {Element} fieldContainer - Container to remove
   * @param {string} keyId - Key ID for error cleanup
   */
  #removeFieldFromDOM(fieldContainer, keyId) {
    fieldContainer.remove();

    // Clean up associated error div
    const errorDiv = document.getElementById(`${keyId}_field_errors`);
    errorDiv?.remove();
  }

  /**
   * Remove field ID from error tracking
   * @param {string} keyId - Field ID to remove from errors
   */
  #removeFieldFromErrors(keyId) {
    this.#removeFieldIdFromErrors(keyId);
  }

  /**
   * Ensure at least one field exists in the form
   */
  #ensureMinimumFields() {
    const remainingFields = document.querySelectorAll(".inputField");
    if (remainingFields.length === 0) {
      this.addField();
    }
  }

  // ====================================================================
  // METADATA PROCESSING (PRIVATE)
  // ====================================================================

  /**
   * Process all metadata fields for validation and hidden input generation
   */
  #processAllMetadataFields() {
    const inputFields = this.#getAllInputFields();

    for (const fieldContainer of inputFields) {
      this.#processMetadataField(fieldContainer);
    }
  }

  /**
   * Get all input field containers
   * @returns {NodeList} All field containers
   */
  #getAllInputFields() {
    return document.querySelectorAll(".inputField");
  }

  /**
   * Process individual metadata field for validation and input generation
   * @param {Element} fieldContainer - Container with key/value inputs
   */
  #processMetadataField(fieldContainer) {
    const keyInput = fieldContainer.querySelector("input[id^='sample_key_']");
    const valueInput = fieldContainer.querySelector(
      "input[id^='sample_value_']",
    );

    if (!keyInput || !valueInput) {
      console.warn("Could not find key or value input in field");
      return;
    }

    const hasKeyValue = Boolean(keyInput.value?.trim());
    const hasValueValue = Boolean(valueInput.value?.trim());

    if (!hasKeyValue || !hasValueValue) {
      this.#handleFieldValidationErrors(
        keyInput,
        valueInput,
        hasKeyValue,
        hasValueValue,
      );
    } else {
      this.#handleValidField(keyInput, valueInput);
    }
  }

  /**
   * Handle validation errors for invalid fields
   * @param {Element} keyInput - Key input element
   * @param {Element} valueInput - Value input element
   * @param {boolean} hasKeyValue - Whether key has value
   * @param {boolean} hasValueValue - Whether value has value
   */
  #handleFieldValidationErrors(
    keyInput,
    valueInput,
    hasKeyValue,
    hasValueValue,
  ) {
    if (!hasKeyValue) {
      this.#showFieldError(keyInput, this.keyMissingValue);
      this.#addFieldIdToErrors(keyInput.id);
    } else {
      this.#hideFieldError(keyInput);
    }

    if (!hasValueValue) {
      this.#showFieldError(valueInput, this.valueMissingValue);
      this.#addFieldIdToErrors(keyInput.id);
    } else {
      this.#hideFieldError(valueInput);
    }
  }

  /**
   * Handle valid field by clearing errors and creating hidden input
   * @param {Element} keyInput - Key input element
   * @param {Element} valueInput - Value input element
   */
  #handleValidField(keyInput, valueInput) {
    if (this.#isFieldInError(keyInput.id)) {
      this.#hideFieldError(keyInput);
      this.#hideFieldError(valueInput);
      this.#removeFieldIdFromErrors(keyInput.id);
    }
    this.#createHiddenMetadataInput(keyInput, valueInput);
  }

  /**
   * Create or update hidden input for metadata submission
   * @param {Element} keyInput - Key input element
   * @param {Element} valueInput - Value input element
   */
  #createHiddenMetadataInput(keyInput, valueInput) {
    const key = keyInput.value.trim();
    const value = valueInput.value.trim();
    const inputName = `sample[create_fields][${key}]`;

    let existingHiddenInput = document.querySelector(
      `input[name="${inputName}"]`,
    );

    if (existingHiddenInput) {
      // Update existing hidden input if value changed
      if (existingHiddenInput.value !== value) {
        existingHiddenInput.value = value;
      }
    } else {
      // Create new hidden input
      const hiddenInputHtml = `<input type="hidden" name="${inputName}" value="${value}">`;
      this.metadataToAddTarget.insertAdjacentHTML("beforeend", hiddenInputHtml);

      // Clear names to prevent duplicate submission
      keyInput.name = "";
      valueInput.name = "";
    }
  }

  /**
   * Submit form if validation passes
   */
  #submitFormIfValid() {
    if (this.#hasNoErrors()) {
      this.#hideFormError();
      this.formTarget.requestSubmit();
    } else {
      this.#showFormError(this.formErrorValue);
    }
  }

  // ====================================================================
  // ERROR MANAGEMENT (PRIVATE)
  // ====================================================================

  /**
   * Add field ID to error tracking array
   * @param {string} fieldId - Field ID to add to errors
   */
  #addFieldIdToErrors(fieldId) {
    if (!this.#errorFieldIds.includes(fieldId)) {
      this.#errorFieldIds.push(fieldId);
    }
  }

  /**
   * Remove field ID from error tracking array
   * @param {string} fieldId - Field ID to remove from errors
   */
  #removeFieldIdFromErrors(fieldId) {
    this.#errorFieldIds = this.#errorFieldIds.filter((id) => id !== fieldId);
  }

  /**
   * Check if field is currently in error state
   * @param {string} fieldId - Field ID to check
   * @returns {boolean} Whether field is in error state
   */
  #isFieldInError(fieldId) {
    return this.#errorFieldIds.includes(fieldId);
  }

  /**
   * Check if there are no validation errors
   * @returns {boolean} Whether form is valid
   */
  #hasNoErrors() {
    return this.#errorFieldIds.length === 0;
  }

  // ====================================================================
  // UI ERROR STATE MANAGEMENT (PRIVATE)
  // ====================================================================

  /**
   * Show error state for individual field
   * @param {Element} field - Input field element
   * @param {string} errorMessage - Error message to display
   */
  #showFieldError(field, errorMessage) {
    if (!field) return;

    const fieldId = field.id;
    const errorContainer = document.getElementById(`${fieldId}_error`);
    const helpTextComponent = errorContainer?.querySelector("span.grow");
    const inputContainer = field.closest(".form-field");

    // Skip if error already displayed
    if (helpTextComponent?.textContent.trim() === errorMessage) {
      return;
    }

    this.#setFieldAriaAttributes(field, fieldId);
    this.#setFieldErrorStyling(field);
    this.#showErrorElements(
      errorContainer,
      helpTextComponent,
      inputContainer,
      errorMessage,
    );
  }

  /**
   * Hide error state for individual field
   * @param {Element} field - Input field element
   */
  #hideFieldError(field) {
    if (!field) return;

    const fieldId = field.id;
    const errorContainer = document.getElementById(`${fieldId}_error`);
    const helpTextComponent = errorContainer?.querySelector("span.grow");
    const inputContainer = field.closest(".form-field");

    // Skip if no error is displayed
    if (helpTextComponent?.textContent.trim() === "") {
      return;
    }

    this.#clearFieldAriaAttributes(field);
    this.#clearFieldErrorStyling(field);
    this.#hideErrorElements(errorContainer, helpTextComponent, inputContainer);
  }

  /**
   * Set ARIA attributes for field error state
   * @param {Element} field - Input field element
   * @param {string} fieldId - Field identifier
   */
  #setFieldAriaAttributes(field, fieldId) {
    field.setAttribute("aria-invalid", "true");
    field.setAttribute("aria-describedby", `${fieldId}_error`);
  }

  /**
   * Clear ARIA attributes from field
   * @param {Element} field - Input field element
   */
  #clearFieldAriaAttributes(field) {
    field.removeAttribute("aria-invalid");
    field.removeAttribute("aria-describedby");
  }

  /**
   * Apply error styling to field
   * @param {Element} field - Input field element
   */
  #setFieldErrorStyling(field) {
    field.classList.remove("border-slate-300", "dark:border-slate-600");
    field.classList.add("border-red-500", "dark:border-red-500");
  }

  /**
   * Clear error styling from field
   * @param {Element} field - Input field element
   */
  #clearFieldErrorStyling(field) {
    field.classList.remove("border-red-500", "dark:border-red-500");
    field.classList.add("border-slate-300", "dark:border-slate-600");
  }

  /**
   * Show error elements and set message
   * @param {Element} errorContainer - Error container element
   * @param {Element} helpTextComponent - Help text component
   * @param {Element} inputContainer - Input container element
   * @param {string} errorMessage - Error message to display
   */
  #showErrorElements(
    errorContainer,
    helpTextComponent,
    inputContainer,
    errorMessage,
  ) {
    if (errorContainer) {
      errorContainer.classList.remove("hidden");
      // Also make sure the parent span is visible
      const parentSpan = errorContainer.querySelector("span");
      if (parentSpan) {
        parentSpan.classList.remove("hidden");
      }
    }

    if (helpTextComponent) {
      helpTextComponent.textContent = errorMessage;
    }

    inputContainer?.classList.add("invalid");
  }

  /**
   * Hide error elements and clear message
   * @param {Element} errorContainer - Error container element
   * @param {Element} helpTextComponent - Help text component
   * @param {Element} inputContainer - Input container element
   */
  #hideErrorElements(errorContainer, helpTextComponent, inputContainer) {
    if (errorContainer) {
      errorContainer.classList.add("hidden");
      // Also hide the parent span
      const parentSpan = errorContainer.querySelector("span");
      if (parentSpan) {
        parentSpan.classList.add("hidden");
      }
    }

    if (helpTextComponent) {
      helpTextComponent.textContent = "";
    }

    inputContainer?.classList.remove("invalid");
  }

  /**
   * Show general form error message
   * @param {string} message - Error message to display
   */
  #showFormError(message) {
    this.formFieldErrorTarget.classList.remove("hidden");
    this.formFieldErrorMessageTarget.innerHTML = message;
    this.formFieldErrorTarget.scrollIntoView({
      behavior: "smooth",
      block: "start",
    });
  }

  /**
   * Hide general form error message
   */
  #hideFormError() {
    this.formFieldErrorTarget.classList.add("hidden");
    this.formFieldErrorMessageTarget.innerHTML = "";
  }
}
