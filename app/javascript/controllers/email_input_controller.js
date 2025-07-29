import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["form", "submit"];
  static values = {
    emailMissing: { type: String },
    emailFormat: { type: String },
  };

  #emailError = "";

  #form_error_text_css = ["text-red-500"];

  #email_error_state = [
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

  #email_valid_state = [
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
    let email = document.getElementById("user_email");
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
    let emailError = document.getElementById(
      "forgot_password_email_error",
    ).lastElementChild;
    let emailErrorSpan = emailError.getElementsByClassName("grow")[0];
    let email = document.getElementById("user_email");
    let emailField = document.getElementById("forgot_password_email_field");

    email.setAttribute("autofocus", true);
    email.setAttribute("aria-invalid", true);
    email.setAttribute("aria-describedBy", "forgot_password_email_error");
    email.classList.remove(...this.#email_valid_state);
    email.classList.add(...this.#email_error_state);
    emailError.classList.remove("hidden");
    emailErrorSpan.innerHTML = this.#emailError;
    emailErrorSpan.classList.add(...this.#form_error_text_css);
    emailField.classList.add("invalid");
  }

  #removeEmailFieldErrorState() {
    let emailError = document.getElementById(
      "forgot_password_email_error",
    ).lastElementChild;
    let emailErrorSpan = emailError.getElementsByClassName("grow")[0];
    let email = document.getElementById("user_email");
    let emailField = document.getElementById("forgot_password_email_field");

    email.removeAttribute("autofocus", false);
    email.removeAttribute("aria-invalid");
    email.removeAttribute("aria-describedBy");
    email.classList.remove(...this.#email_error_state);
    email.classList.add(...this.#email_valid_state);
    emailError.classList.add("hidden");
    emailErrorSpan.innerHTML = "";
    emailErrorSpan.classList.remove(...this.#form_error_text_css);
    emailField.classList.remove("invalid");
  }

  #validateEmailFormat(email) {
    return String(email)
      .toLowerCase()
      .match(
        /^(([^<>()[\]\\.,;:\s@"]+(\.[^<>()[\]\\.,;:\s@"]+)*)|.(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/,
      );
  }
}
