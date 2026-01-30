import { Controller } from "@hotwired/stimulus";
import { formDataToJsonParams, normalizeParams } from "utilities/form";
import { announce } from "utilities/live_region";

/**
 * WorkflowSelectionController
 *
 * Manages workflow selection and submission for batch sample processing.
 * Handles form submission, spinner display, and accessibility announcements.
 *
 * @example
 * <div data-controller="workflow-selection"
 *      data-workflow-selection-field-name-value="sample_ids">
 *   <form data-workflow-selection-target="form">...</form>
 * </div>
 */
export default class extends Controller {
  // ====================================================================
  // Stimulus Configuration
  // ====================================================================

  static targets = [
    "workflow",
    "pipelineId",
    "workflowVersion",
    "form",
    "dialogClose",
    "spinner",
    "spinnerCount",
    "spinnerWorkflowName",
    "spinnerWorkflowVersion",
    "statusAnnouncement",
  ];

  static outlets = ["selection"];

  static values = {
    fieldName: String,
    featureFlag: { type: Boolean },
    submittingMessage: { type: String, default: "Submitting workflow" },
  };

  /**
   * Minimum time to display spinner for accessibility (milliseconds).
   * Ensures screen readers have time to announce the loading state.
   *
   * This value (3500ms) is based on WCAG 2.1 Success Criterion 4.1.3 (Status Messages)
   * which requires that status messages be programmatically determinable and announced
   * by assistive technologies. Screen readers typically need 2-4 seconds to process
   * and vocalize dynamic content changes, especially when multiple elements update.
   *
   * @see https://www.w3.org/WAI/WCAG21/Understanding/status-messages.html
   */
  static A11Y_SPINNER_DURATION = 3500;

  #sampleCount;

  // ====================================================================
  // Lifecycle
  // ====================================================================

  connect() {
    this.boundAmendForm = this.#amendForm.bind(this);
    this.boundOnSuccess = this.#onSuccess.bind(this);
    this.boundPreventEscape = this.#preventEscapeListener.bind(this);

    this.formTarget.addEventListener(
      "turbo:before-fetch-request",
      this.boundAmendForm,
    );

    this.formTarget.addEventListener("turbo:submit-end", this.boundOnSuccess);

    if (this.featureFlagValue) {
      this.#sampleCount = this.selectionOutlet.getStoredItemsCount();
    }
  }

  disconnect() {
    this.formTarget.removeEventListener(
      "turbo:before-fetch-request",
      this.boundAmendForm,
    );

    this.formTarget.removeEventListener(
      "turbo:submit-end",
      this.boundOnSuccess,
    );

    this.#removeEscapeListener();
  }

  // ====================================================================
  // Public Actions
  // ====================================================================

  /**
   * Select a workflow and initiate submission.
   * Updates form values, shows spinner, and submits the form.
   *
   * @param {Object} params - Workflow parameters from data attributes
   * @param {string} params.pipelineid - Pipeline identifier
   * @param {string} params.workflowversion - Workflow version string
   * @param {string} params.workflowname - Display name for the workflow
   */
  selectWorkflow({ params }) {
    this.#preventDialogClose();
    this.#setFormValues(params);
    this.#showSpinner(params);
    this.#announceSubmission(params);
    this.#submitWithAccessibilityDelay();
  }

  // ====================================================================
  // Private: Form Handling
  // ====================================================================

  /**
   * Amend the form submission to use JSON format.
   * Intercepts Turbo fetch request and converts FormData to JSON.
   *
   * @param {CustomEvent} event - Turbo before-fetch-request event
   * @private
   */
  #amendForm(event) {
    const formData = new FormData(this.formTarget);
    event.detail.fetchOptions.body = JSON.stringify(this.#toJson(formData));
    event.detail.fetchOptions.headers["Content-Type"] = "application/json";
    event.detail.resume();
  }

  /**
   * Handle successful form submission.
   * Clears selection if configured to do so.
   *
   * @param {CustomEvent} event - Turbo submit-end event
   * @private
   */
  #onSuccess(event) {
    if (event.detail.success && this.clearSelectionValue) {
      this.selectionOutlet.clear();
    }
  }

  /**
   * Set hidden form field values for the selected workflow.
   *
   * @param {Object} params - Workflow parameters
   * @private
   */
  #setFormValues(params) {
    this.pipelineIdTarget.value = params.pipelineid;
    this.workflowVersionTarget.value = params.workflowversion;
  }

  /**
   * Convert FormData to JSON with sample IDs.
   *
   * @param {FormData} formData - Form data to convert
   * @returns {Object} JSON-serializable object
   * @private
   */
  #toJson(formData) {
    const params = formDataToJsonParams(formData);

    // add sample_ids under the fieldNameValue key to the params
    if (this.featureFlagValue) {
      normalizeParams(params, this.fieldNameValue, this.#sampleCount, 0);
    } else {
      normalizeParams(
        params,
        this.fieldNameValue,
        this.selectionOutlet.getOrCreateStoredItems(),
        0,
      );
    }

    return params;
  }

  /**
   * Submit the form with an accessibility delay.
   * Ensures the spinner is visible long enough for screen readers.
   *
   * @private
   */
  #submitWithAccessibilityDelay() {
    const submitStart = Date.now();

    document.addEventListener(
      "turbo:before-stream-render",
      (event) => {
        const elapsed = Date.now() - submitStart;
        const remaining = this.constructor.A11Y_SPINNER_DURATION - elapsed;

        if (remaining > 0) {
          const defaultRender = event.detail.render;
          event.detail.render = (streamElement) => {
            setTimeout(() => defaultRender(streamElement), remaining);
          };
        }
      },
      { once: true },
    );

    this.formTarget.requestSubmit();
  }

  // ====================================================================
  // Private: UI Management
  // ====================================================================

  /**
   * Prevent the dialog from being closed during submission.
   * Hides close button and blocks Escape key.
   * Falls back to querying within the closest dialog if target not available.
   *
   * @private
   */
  #preventDialogClose() {
    const closeButton = this.hasDialogCloseTarget
      ? this.dialogCloseTarget
      : this.element.closest("dialog")?.querySelector(".dialog--close");

    if (closeButton) {
      closeButton.classList.add("hidden");
    }
    document.addEventListener("keydown", this.boundPreventEscape, true);
  }

  /**
   * Remove the Escape key listener.
   *
   * @private
   */
  #removeEscapeListener() {
    document.removeEventListener("keydown", this.boundPreventEscape, true);
  }

  /**
   * Prevent Escape key from closing the dialog.
   *
   * @param {KeyboardEvent} event - Keyboard event
   * @private
   */
  #preventEscapeListener(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      event.stopPropagation();
    }
  }

  /**
   * Show the spinner with workflow details.
   * Uses targeted elements instead of innerHTML replacement for security.
   *
   * @param {Object} params - Workflow parameters
   * @private
   */
  #showSpinner(params) {
    if (!this.hasSpinnerTarget) return;

    this.spinnerTarget.classList.remove("hidden");

    if (this.hasSpinnerCountTarget) {
      const count = this.featureFlagValue
        ? this.#sampleCount
        : this.selectionOutlet.getOrCreateStoredItems().length;
      this.spinnerCountTarget.textContent = String(count);
    }

    if (this.hasSpinnerWorkflowNameTarget) {
      this.spinnerWorkflowNameTarget.textContent = params.workflowname;
    }

    if (this.hasSpinnerWorkflowVersionTarget) {
      this.spinnerWorkflowVersionTarget.textContent = params.workflowversion;
    }
  }

  // ====================================================================
  // Private: Accessibility
  // ====================================================================

  /**
   * Announce the submission to screen readers.
   * Uses the shared live region utility for consistent announcement behavior.
   *
   * @param {Object} params - Workflow parameters
   * @private
   */
  #announceSubmission(params) {
    const count = this.featureFlagValue
      ? this.#sampleCount
      : this.selectionOutlet.getOrCreateStoredItems().length;
    const message = `${this.submittingMessageValue}: ${params.workflowname} version ${params.workflowversion} for ${count} samples`;

    announce(message, {
      element: this.hasStatusAnnouncementTarget
        ? this.statusAnnouncementTarget
        : null,
    });
  }
}
