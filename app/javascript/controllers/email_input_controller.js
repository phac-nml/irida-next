/**
 * Email Input Controller
 *
 * A Stimulus controller for handling email input validation with accessibility support.
 * Validates email format, displays appropriate error messages, and manages form submission.
 */
import { Controller } from "@hotwired/stimulus";
import debounce from "debounce";

export default class extends Controller {
  static targets = ["form", "emailField", "errorContainer"];

  static values = {
    emailMissing: { type: String },
    emailFormat: { type: String },
  };

  connect() {
    // Initialize field state
    this.isSubmitting = false;

    // Validate required Stimulus values
    this.#validateRequiredValues();

    // Set up debounced validation for typing
    this.debouncedValidate = debounce(
      () => this.validateEmail(false, false),
      300,
    );

    // Add input event listener for real-time validation
    this.handleInput = this.handleInput.bind(this);
    this.emailFieldTarget.addEventListener("input", this.handleInput);
  }

  disconnect() {
    // Clean up event listeners
    this.emailFieldTarget.removeEventListener("input", this.handleInput);
  }

  /**
   * Handles form submission with validation
   * @param {Event} event - The submission event
   */
  submit(event) {
    event.preventDefault();

    // Prevent double submission
    if (this.isSubmitting) return;

    this.isSubmitting = true;

    if (this.validateEmail()) {
      // Use requestAnimationFrame instead of setTimeout for better performance
      requestAnimationFrame(() => {
        this.formTarget.submit();
      });
    } else {
      this.isSubmitting = false;
    }
  }

  /**
   * Handles input events on the email field
   */
  handleInput() {
    this.debouncedValidate();
  }

  /**
   * Validates email with optional error handling and focus behavior
   * @param {boolean} showMissingError - Whether to show error for missing email
   * @param {boolean} shouldFocus - Whether to focus the field on error
   * @returns {boolean} - Whether the email is valid
   */
  validateEmail(showMissingError = true, shouldFocus = true) {
    const email = this.emailFieldTarget.value.trim();

    if (!email) {
      if (showMissingError) {
        this.showError(this.emailMissingValue, shouldFocus);
      }
      return false;
    }

    if (!this.isValidEmailFormat(email)) {
      this.showError(this.emailFormatValue, shouldFocus);
      return false;
    }

    this.clearError();
    return true;
  }

  /**
   * Shows error message and updates field styling
   * @param {string} message - The error message to display
   * @param {boolean} shouldFocus - Whether to focus the field
   */
  showError(message, shouldFocus = true) {
    const messageTextSpan =
      this.errorContainerTarget.querySelector("span.grow");
    // Update error message
    messageTextSpan.textContent = message;
    this.errorContainerTarget.classList.remove("hidden");

    // Generate a unique ID for ARIA attributes if needed
    if (!this.errorContainerTarget.id) {
      this.errorContainerTarget.id = `email-error-${Date.now()}`;
    }

    // Set validity using the Constraint Validation API
    // This makes the :invalid pseudo-class active, which Tailwind's invalid: prefix uses
    this.emailFieldTarget.setCustomValidity(message);

    // Update accessibility attributes
    this.emailFieldTarget.setAttribute("aria-invalid", "true");
    this.emailFieldTarget.setAttribute(
      "aria-describedby",
      this.errorContainerTarget.id,
    );

    if (shouldFocus) {
      this.emailFieldTarget.focus();
    }
  }

  /**
   * Clears error messages and resets field styling
   */
  clearError() {
    this.errorContainerTarget.classList.add("hidden");

    // Clear validity using the Constraint Validation API
    // This removes the :invalid pseudo-class, which Tailwind's invalid: prefix uses
    this.emailFieldTarget.setCustomValidity("");

    // Update accessibility attributes
    this.emailFieldTarget.setAttribute("aria-invalid", "false");
    this.emailFieldTarget.removeAttribute("aria-describedby");
  }

  /**
   * Validates an email address format according to RFC standards
   * @param {string} email - The email to validate
   * @returns {boolean} - Whether the email format is valid
   */
  isValidEmailFormat(email) {
    // Comprehensive RFC 5322 compatible regex
    // Covers most valid email formats while rejecting obvious mistakes
    const emailRegex =
      /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/; // eslint-disable-line

    if (!emailRegex.test(email)) {
      return false;
    }

    // Additional validation for reasonable lengths
    const [localPart, domain] = email.split("@");

    // RFC 5321 SMTP limits
    if (!localPart || !domain || localPart.length > 64 || domain.length > 255) {
      return false;
    }

    // Domain format validation (must have at least one period and valid TLD)
    const domainParts = domain.split(".");
    if (
      domainParts.length < 2 ||
      domainParts[domainParts.length - 1].length < 2
    ) {
      return false;
    }

    return true;
  }

  /**
   * Validates that required Stimulus values are provided
   * @throws {Error} If a required value is missing
   */
  #validateRequiredValues() {
    if (this.emailMissingValue === undefined) {
      throw new Error("email-missing value is required");
    }
    if (this.emailFormatValue === undefined) {
      throw new Error("email-format value is required");
    }
  }
}
