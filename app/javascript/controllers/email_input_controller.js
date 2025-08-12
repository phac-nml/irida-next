import { Controller } from "@hotwired/stimulus";
import { FIELD_CLASSES } from "utilities/styles";

export default class extends Controller {
  static targets = [
    "form",
    "submit",
    "emailError",
    "emailFieldDiv",
    "emailField",
  ];
  static values = {
    emailMissing: { type: String },
    emailFormat: { type: String },
  };

  #emailError = "";

  connect() {}

  idempotentConnect() {}

  submit(event) {
    event.preventDefault();
    setTimeout(() => {
      let emailValid = this.#validateEmail();

      if (emailValid) {
        this.formTarget.submit();
      }
    }, 50);
  }

  #validateEmail() {
    let email = this.emailFieldTarget;
    let hasErrors = false;

    if (email.value === "") {
      this.#emailError = this.emailMissingValue;
      hasErrors = true;
    } else {
      if (!this.#validateEmailFormat(email.value)) {
        this.#emailError = this.emailFormatValue;
        hasErrors = true;
      }
    }

    if (hasErrors) {
      this.#addEmailFieldErrorState();
      return false;
    } else {
      this.#removeEmailFieldErrorState();
    }

    return true;
  }

  #addEmailFieldErrorState() {
    let emailError = this.emailErrorTarget.lastElementChild;
    let emailErrorSpan = emailError.getElementsByClassName("grow")[0];
    let email = this.emailFieldTarget;
    let emailField = this.emailFieldDivTarget;

    email.setAttribute("autofocus", true);
    email.setAttribute("aria-invalid", true);
    email.setAttribute("aria-describedBy", "forgot_password_email_error");
    email.classList.remove(...FIELD_CLASSES["VALID"]);
    email.classList.add(...FIELD_CLASSES["ERROR"]);
    emailError.classList.remove("hidden");
    emailErrorSpan.innerHTML = this.#emailError;
    emailErrorSpan.classList.add(...FIELD_CLASSES["ERROR_SPAN"]);
    emailField.classList.add("invalid");
  }

  #removeEmailFieldErrorState() {
    let emailError = this.emailErrorTarget.lastElementChild;
    let emailErrorSpan = emailError.getElementsByClassName("grow")[0];
    let email = this.emailFieldTarget;
    let emailField = this.emailFieldDivTarget;

    email.removeAttribute("autofocus", false);
    email.removeAttribute("aria-invalid");
    email.removeAttribute("aria-describedBy");
    email.classList.remove(...FIELD_CLASSES["ERROR"]);
    email.classList.add(...FIELD_CLASSES["VALID"]);
    emailError.classList.add("hidden");
    emailErrorSpan.innerHTML = "";
    emailErrorSpan.classList.remove(...FIELD_CLASSES["ERROR_SPAN"]);
    emailField.classList.remove("invalid");
  }

  #validateEmailFormat(email) {
    // Basic format check
    const basicEmailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!basicEmailRegex.test(email)) {
      return false;
    }

    // Additional validation
    const [localPart, domain] = email.split("@");

    // Reasonable length checks
    if (localPart.length > 64 || domain.length > 253) {
      return false;
    }

    // Domain format check
    const domainRegex =
      /^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;
    return domainRegex.test(domain);
  }
}
