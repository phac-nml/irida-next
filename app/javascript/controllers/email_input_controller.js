/**
 * Email Input Controller
 *
 * A Stimulus controller for handling email input validation with accessibility support.
 * Validates email format, displays appropriate error messages, and manages form submission.
 */
import { Controller } from "@hotwired/stimulus";
import _ from "lodash";

export default class extends Controller {
  static targets = ["form", "emailField", "errorContainer", "errorMessage"];

  static values = {
    emailMissing: { type: String, default: "Email is required" },
    emailFormat: {
      type: String,
      default: "Please enter a valid email address",
    },
  };

  connect() {
    // Initialize field state
    this.isSubmitting = false;

    // Set up debounced validation for typing
    this.debouncedValidate = _.debounce(
      this.validateEmailSilently.bind(this),
      300,
    );

    // Add input event listener for real-time validation
    this.emailFieldTarget.addEventListener(
      "input",
      this.handleInput.bind(this),
    );
  }

  disconnect() {
    // Clean up event listeners
    this.emailFieldTarget.removeEventListener(
      "input",
      this.handleInput.bind(this),
    );
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
   * @param {Event} event - The input event
   */
  handleInput(event) {
    this.debouncedValidate();
  }

  /**
   * Validates email silently (without focus or submission effects)
   * Used during typing for real-time feedback
   */
  validateEmailSilently() {
    const email = this.emailFieldTarget.value.trim();

    if (!email) {
      // Don't show missing error during typing
      return false;
    }

    if (!this.isValidEmailFormat(email)) {
      this.showError(this.emailFormatValue, false);
      return false;
    }

    this.clearError();
    return true;
  }

  /**
   * Validates email with full error handling
   * @returns {boolean} - Whether the email is valid
   */
  validateEmail() {
    const email = this.emailFieldTarget.value.trim();

    if (!email) {
      this.showError(this.emailMissingValue, true);
      return false;
    }

    if (!this.isValidEmailFormat(email)) {
      this.showError(this.emailFormatValue, true);
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
    // Update error message
    this.errorMessageTarget.textContent = message;
    this.errorContainerTarget.classList.remove("hidden");

    // Generate a unique ID for ARIA attributes if needed
    const errorId = this.errorContainerTarget.id || `email-error-${Date.now()}`;
    if (!this.errorContainerTarget.id) {
      this.errorContainerTarget.id = errorId;
    }

    // Set validity using the Constraint Validation API
    // This makes the :invalid pseudo-class active, which Tailwind's invalid: prefix uses
    this.emailFieldTarget.setCustomValidity(message);

    // Update accessibility attributes
    this.emailFieldTarget.setAttribute("aria-invalid", "true");
    this.emailFieldTarget.setAttribute("aria-describedby", errorId);

    if (shouldFocus) {
      this.emailFieldTarget.focus();
    }
  }

  /**
   * Clears error messages and resets field styling
   */
  clearError() {
    this.errorContainerTarget.classList.add("hidden");
    this.errorMessageTarget.textContent = "";

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
      /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

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
   * Handles blur event on the email field
   * Forces validation when the user leaves the field
   */
  blur() {
    this.validateEmail();
  }
}
