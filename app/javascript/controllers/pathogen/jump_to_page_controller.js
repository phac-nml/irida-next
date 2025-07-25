import { Controller } from "@hotwired/stimulus";

/**
 * Stimulus controller for the jump-to-page pagination component.
 * Provides enhanced accessibility features, client-side validation,
 * and user feedback for page navigation.
 */
export default class extends Controller {
  static targets = ["input", "error", "announcement", "submit"];

  connect() {
    this.minPage = parseInt(this.inputTarget.min);
    this.maxPage = parseInt(this.inputTarget.max);
    this.currentPage = parseInt(this.inputTarget.value);

    // Set up initial state
    this.clearError();

    // Add input event listener for real-time validation
    this.inputTarget.addEventListener("input", this.validateInput.bind(this));
  }

  /**
   * Validates the page number input and shows error messages if needed
   * @param {Event} event - The input event
   */
  validateInput(event) {
    const value = parseInt(event.target.value);
    const isValid = this.isValidPageNumber(value);

    if (event.target.value === "") {
      // Empty input - clear error but don't show validation
      this.clearError();
      this.setInputValidity(false);
      return;
    }

    if (!isValid) {
      this.showError();
      this.setInputValidity(false);
    } else {
      this.clearError();
      this.setInputValidity(true);
    }
  }

  /**
   * Submits the form if the input is valid
   * @param {Event} event - The change or enter key event
   */
  submitForm(event) {
    const value = parseInt(this.inputTarget.value);

    if (this.isValidPageNumber(value)) {
      this.clearError();
      this.setInputValidity(true);

      // Announce the navigation attempt
      this.announceNavigation(value);

      // Submit the form
      this.submitTarget.click();
    } else {
      this.showError();
      this.setInputValidity(false);
      event.preventDefault();
    }
  }

  /**
   * Announces page changes to screen readers after successful navigation
   * @param {Event} event - The turbo:submit-end event
   */
  announcePageChange(event) {
    if (event.detail.success) {
      const newPage = parseInt(this.inputTarget.value);
      const totalPages = this.maxPage;

      // Get the translated message
      const message = this.getNavigationMessage(newPage, totalPages);
      this.announcementTarget.textContent = message;

      // Clear the announcement after a delay to allow it to be read
      setTimeout(() => {
        this.announcementTarget.textContent = "";
      }, 3000);
    }
  }

  /**
   * Checks if a page number is valid
   * @param {number} pageNumber - The page number to validate
   * @returns {boolean} True if valid, false otherwise
   */
  isValidPageNumber(pageNumber) {
    return (
      !isNaN(pageNumber) &&
      Number.isInteger(pageNumber) &&
      pageNumber >= this.minPage &&
      pageNumber <= this.maxPage
    );
  }

  /**
   * Shows the error message
   */
  showError() {
    const errorMessage = this.getErrorMessage();
    this.errorTarget.textContent = errorMessage;
    this.errorTarget.classList.remove("hidden");
    this.inputTarget.setAttribute("aria-invalid", "true");
  }

  /**
   * Clears the error message
   */
  clearError() {
    this.errorTarget.textContent = "";
    this.errorTarget.classList.add("hidden");
    this.inputTarget.setAttribute("aria-invalid", "false");
  }

  /**
   * Sets the visual validity state of the input
   * @param {boolean} isValid - Whether the input is valid
   */
  setInputValidity(isValid) {
    const input = this.inputTarget;

    if (isValid) {
      input.classList.remove("border-red-500", "dark:border-red-500");
      input.classList.add("border-slate-300", "dark:border-slate-600");
    } else {
      input.classList.remove("border-slate-300", "dark:border-slate-600");
      input.classList.add("border-red-500", "dark:border-red-500");
    }
  }

  /**
   * Announces navigation attempt to screen readers
   * @param {number} targetPage - The page being navigated to
   */
  announceNavigation(targetPage) {
    if (targetPage !== this.currentPage) {
      const message = `Navigating to page ${targetPage}...`;
      this.announcementTarget.textContent = message;
    }
  }

  /**
   * Gets the localized error message
   * @returns {string} The error message
   */
  getErrorMessage() {
    // Try to get the message from data attributes or fall back to English
    const message =
      this.element.dataset.errorMessage ||
      `Invalid page number. Please enter a number between ${this.minPage} and ${this.maxPage}.`;

    return message
      .replace("%{min}", this.minPage)
      .replace("%{max}", this.maxPage);
  }

  /**
   * Gets the localized navigation success message
   * @param {number} page - The current page
   * @param {number} total - Total number of pages
   * @returns {string} The navigation message
   */
  getNavigationMessage(page, total) {
    // Try to get the message from data attributes or fall back to English
    const message =
      this.element.dataset.navigationMessage ||
      `Navigated to page %{page} of %{total}`;

    return message.replace("%{page}", page).replace("%{total}", total);
  }
}
