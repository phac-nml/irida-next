import { Controller } from "@hotwired/stimulus";

const UPLOAD_ROWS_ROLE = "upload-rows";

export default class extends Controller {
  static targets = [
    "submitButton",
    "attachmentsInput",
    "uploadErrorAlert",
    "formErrorAlert",
  ];
  static values = {
    uploadingText: String,
    successText: String,
    errorFallbackText: String,
  };
  #uploads = new Map();
  #pendingUploadKeys = new Set();
  #activeUploadKeys = new Set();
  #formElement;
  #rowsElement;
  #submitButtonState;
  #hasUploadError = false;
  #batchInProgress = false;

  connect() {
    this.#bindHandlers();
    this.#formElement =
      this.attachmentsInputTarget.form || this.element.closest("form");

    this.element.addEventListener("direct-upload:initialize", this._onInit);
    this.element.addEventListener("direct-upload:start", this._onStart);
    this.element.addEventListener("direct-upload:progress", this._onProgress);
    this.element.addEventListener("direct-upload:error", this._onError);
    this.element.addEventListener("direct-upload:end", this._onEnd);

    if (this.#formElement) {
      this.#formElement.addEventListener(
        "direct-uploads:start",
        this._onAllStart,
      );
      this.#formElement.addEventListener("direct-uploads:end", this._onAllEnd);
      this.#formElement.addEventListener("ajax:error", this._onFormError);
      this.#formElement.addEventListener(
        "turbo:submit-end",
        this._onTurboSubmitEnd,
      );
    }

    this.attachmentsInputTarget.setAttribute("aria-required", "true");
    this.attachmentsInputTarget.setAttribute("aria-invalid", "false");
    this.submitButtonTarget.disabled = true;
    this.#hideErrorAlerts();
  }

  disconnect() {
    this.element.removeEventListener("direct-upload:initialize", this._onInit);
    this.element.removeEventListener("direct-upload:start", this._onStart);
    this.element.removeEventListener(
      "direct-upload:progress",
      this._onProgress,
    );
    this.element.removeEventListener("direct-upload:error", this._onError);
    this.element.removeEventListener("direct-upload:end", this._onEnd);

    if (this.#formElement) {
      this.#formElement.removeEventListener(
        "direct-uploads:start",
        this._onAllStart,
      );
      this.#formElement.removeEventListener(
        "direct-uploads:end",
        this._onAllEnd,
      );
      this.#formElement.removeEventListener("ajax:error", this._onFormError);
      this.#formElement.removeEventListener(
        "turbo:submit-end",
        this._onTurboSubmitEnd,
      );
    }

    this.#uploads.clear();
    this.#pendingUploadKeys.clear();
    this.#activeUploadKeys.clear();
    this.#batchInProgress = false;
  }

  uploadInitialize(event) {
    if (!this.#isAttachmentUploadEvent(event)) return;

    const { id, file } = event.detail;
    const uploadKey = this.#uploadKey(id);
    const existingUpload = this.#uploads.get(uploadKey);
    if (existingUpload) {
      existingUpload.rowElement.remove();
      this.#activeUploadKeys.delete(uploadKey);
      this.#pendingUploadKeys.delete(uploadKey);
    }

    const upload = this.#buildUploadRow(id, file.name);

    this.#ensureRowsElement().append(upload.rowElement);
    this.#uploads.set(uploadKey, upload);
    if (this.#batchInProgress) {
      this.#activeUploadKeys.add(uploadKey);
    } else {
      this.#pendingUploadKeys.add(uploadKey);
    }
    this.#setUploadProgress(id, 0, { force: true });
  }

  uploadStart(event) {
    if (!this.#isAttachmentUploadEvent(event)) return;

    const { id } = event.detail;
    const upload = this.#uploads.get(this.#uploadKey(id));
    if (!upload) return;

    upload.status = "uploading";
    upload.rowElement.classList.remove("direct-upload--pending");

    this.#disableAttachmentsInput();
    this.#rememberSubmitButtonState();
    this.#setSubmitButtonUploadingState();
  }

  uploadProgress(event) {
    if (!this.#isAttachmentUploadEvent(event)) return;

    const { id, progress } = event.detail;
    this.#setUploadProgress(id, progress);
  }

  uploadError(event) {
    if (!this.#isAttachmentUploadEvent(event)) return;

    event.preventDefault();
    const { id, error } = event.detail;
    const upload = this.#uploads.get(this.#uploadKey(id));
    if (!upload) return;

    this.#hasUploadError = true;
    upload.status = "error";
    const errorMessage = this.#errorFallbackText();
    this.#setUploadStatusMessage(upload, "error", errorMessage);
    upload.rowElement.classList.add("direct-upload--error");
    upload.rowElement.setAttribute("title", error);
    this.attachmentsInputTarget.setAttribute("aria-invalid", "true");
  }

  uploadEnd(event) {
    if (!this.#isAttachmentUploadEvent(event)) return;

    const { id } = event.detail;
    const upload = this.#uploads.get(this.#uploadKey(id));
    if (!upload || upload.status === "error") return;

    upload.status = "complete";
    upload.rowElement.classList.remove("direct-upload--pending");
    upload.rowElement.classList.add("direct-upload--complete");
    this.#setUploadStatusMessage(upload, "complete", this.#successText());
  }

  #uploadsStart(event) {
    if (!this.#isThisFormEvent(event)) return;

    this.#batchInProgress = true;
    this.#hasUploadError = false;
    this.#hideErrorAlerts();
    for (const uploadKey of this.#pendingUploadKeys) {
      this.#activeUploadKeys.add(uploadKey);
    }
    this.#pendingUploadKeys.clear();

    if (this.#activeUploadKeys.size === 0) return;

    this.#disableAttachmentsInput();
    this.#rememberSubmitButtonState();
    this.#setSubmitButtonUploadingState();
  }

  #uploadsEnd(event) {
    if (!this.#isThisFormEvent(event)) return;
    if (this.#activeUploadKeys.size === 0) {
      this.#batchInProgress = false;
      return;
    }

    if (!this.#hasUploadError) {
      this.#markNonErrorUploadsComplete(this.#activeUploadKeys);
      this.attachmentsInputTarget.setAttribute("aria-invalid", "false");
      this.#clearSelectedFiles();
    } else {
      for (const uploadKey of this.#activeUploadKeys) {
        const upload = this.#uploads.get(uploadKey);
        if (upload && upload.status === "pending") {
          upload.status = "error";
          this.#setUploadStatusMessage(
            upload,
            "error",
            this.#errorFallbackText(),
          );
          upload.rowElement.classList.add("direct-upload--error");
          upload.rowElement.setAttribute(
            "title",
            "Upload cancelled due to previous error",
          );
        }
      }
      this.#clearDirectUploadHiddenInputs();
      this.#showUploadErrorAlert();
    }

    this.#enableAttachmentsInput();
    this.#restoreSubmitButtonState();
    this.#clearBatchUploads(this.#activeUploadKeys);
    this.#activeUploadKeys.clear();
    this.#batchInProgress = false;
  }

  #bindHandlers() {
    this._onInit = this.uploadInitialize.bind(this);
    this._onStart = this.uploadStart.bind(this);
    this._onProgress = this.uploadProgress.bind(this);
    this._onError = this.uploadError.bind(this);
    this._onEnd = this.uploadEnd.bind(this);
    this._onAllStart = this.#uploadsStart.bind(this);
    this._onAllEnd = this.#uploadsEnd.bind(this);
    this._onFormError = this.formError.bind(this);
    this._onTurboSubmitEnd = this.#handleTurboSubmitEnd.bind(this);
  }

  formError(event) {
    if (!this.#isThisFormEvent(event)) return;
    this.#hideUploadErrorAlert();
    this.#showFormErrorAlert();
  }

  #handleTurboSubmitEnd(event) {
    if (!this.#isThisFormEvent(event)) return;
    if (event.detail?.success === false) {
      this.formError(event);
      return;
    }
    this.#hideErrorAlerts();
  }

  #isAttachmentUploadEvent(event) {
    return event.target === this.attachmentsInputTarget;
  }

  #isThisFormEvent(event) {
    return event.target === this.#formElement;
  }

  #uploadKey(id) {
    return String(id);
  }

  #ensureRowsElement() {
    if (this.#rowsElement?.isConnected) return this.#rowsElement;

    const existingRowsElement = this.element.querySelector(
      `[data-attachment-upload-role="${UPLOAD_ROWS_ROLE}"]`,
    );
    if (existingRowsElement) {
      this.#rowsElement = existingRowsElement;
      return this.#rowsElement;
    }

    const rowsElement = document.createElement("div");
    rowsElement.dataset.attachmentUploadRole = UPLOAD_ROWS_ROLE;
    rowsElement.className = "grid gap-1";
    this.attachmentsInputTarget.insertAdjacentElement(
      "beforebegin",
      rowsElement,
    );
    this.#rowsElement = rowsElement;

    return this.#rowsElement;
  }

  #buildUploadRow(id, fileName) {
    const rowElement = document.createElement("div");
    rowElement.id = `direct-upload-${id}`;
    rowElement.className =
      "direct-upload direct-upload--pending flex-1 relative mb-3 p-3 border border-slate-200 dark:border-slate-700 rounded-lg bg-white dark:bg-slate-800 shadow-sm";

    const filenameRow = document.createElement("div");
    filenameRow.className =
      "flex justify-between items-center mb-2 direct-upload__filename";

    const fileNameElement = document.createElement("span");
    fileNameElement.id = `direct-upload-filename-${id}`;
    fileNameElement.className =
      "text-sm font-medium text-slate-700 dark:text-slate-200 truncate pr-4";
    fileNameElement.textContent = fileName;

    const progressTextElement = document.createElement("span");
    progressTextElement.id = `upload-progress-${id}`;
    progressTextElement.className =
      "text-sm font-medium text-slate-500 dark:text-slate-400 whitespace-nowrap flex items-center gap-1.5";
    progressTextElement.textContent = "0%";

    filenameRow.append(fileNameElement, progressTextElement);

    const progressTrackElement = document.createElement("div");
    progressTrackElement.className =
      "w-full bg-slate-100 rounded-full h-1.5 dark:bg-slate-700 overflow-hidden";

    const progressBarElement = document.createElement("div");
    progressBarElement.id = `direct-upload-progress-${id}`;
    progressBarElement.className =
      "bg-primary-600 h-full rounded-full transition-all duration-300 ease-out";
    progressBarElement.style.width = "0%";
    progressBarElement.setAttribute("role", "progressbar");
    progressBarElement.setAttribute("aria-valuemin", "0");
    progressBarElement.setAttribute("aria-valuemax", "100");
    progressBarElement.setAttribute("aria-valuenow", "0");
    progressBarElement.setAttribute("aria-valuetext", "0%");
    progressBarElement.setAttribute(
      "aria-label",
      `${this.#uploadingText()} ${fileName}`.trim(),
    );
    progressBarElement.setAttribute("aria-describedby", fileNameElement.id);

    progressTrackElement.append(progressBarElement);
    rowElement.append(filenameRow, progressTrackElement);

    return {
      id,
      rowElement,
      progressTrackElement,
      progressBarElement,
      progressTextElement,
      status: "pending",
      lastProgress: 0,
    };
  }

  #setUploadStatusMessage(upload, status, message) {
    const isComplete = status === "complete";
    const isError = status === "error";

    upload.progressTrackElement.classList.add("hidden");
    upload.progressBarElement.removeAttribute("aria-valuenow");
    upload.progressBarElement.removeAttribute("aria-valuetext");
    upload.progressBarElement.removeAttribute("role");

    upload.progressTextElement.className =
      "text-sm font-medium whitespace-nowrap flex items-center gap-1.5";

    if (isComplete) {
      upload.progressTextElement.classList.add(
        "text-green-600",
        "dark:text-green-400",
      );
      upload.progressTextElement.innerHTML = `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7"></path></svg><span>${message}</span>`;
      upload.rowElement.classList.replace(
        "border-slate-200",
        "border-green-200",
      );
      upload.rowElement.classList.replace(
        "dark:border-slate-700",
        "dark:border-green-900/50",
      );
      upload.rowElement.classList.add("bg-green-50/50", "dark:bg-green-900/10");
    } else if (isError) {
      upload.progressTextElement.classList.add(
        "text-rose-600",
        "dark:text-rose-400",
      );
      upload.progressTextElement.innerHTML = `<svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12"></path></svg><span>${message}</span>`;
      upload.rowElement.classList.replace(
        "border-slate-200",
        "border-rose-200",
      );
      upload.rowElement.classList.replace(
        "dark:border-slate-700",
        "dark:border-rose-900/50",
      );
      upload.rowElement.classList.add("bg-rose-50/50", "dark:bg-rose-900/10");
    } else {
      upload.progressTextElement.classList.add(
        "text-slate-500",
        "dark:text-slate-400",
      );
      upload.progressTextElement.textContent = message;
    }
  }

  #setUploadProgress(id, progress, { force = false } = {}) {
    const upload = this.#uploads.get(this.#uploadKey(id));
    if (!upload) return;

    const boundedProgress = Math.min(Math.max(progress, 0), 100);
    const nextProgress = force
      ? boundedProgress
      : Math.max(upload.lastProgress, boundedProgress);
    const roundedProgress = Math.round(nextProgress);

    upload.lastProgress = nextProgress;
    upload.progressBarElement.style.width = `${nextProgress}%`;
    upload.progressBarElement.setAttribute(
      "aria-valuenow",
      `${roundedProgress}`,
    );
    upload.progressBarElement.setAttribute(
      "aria-valuetext",
      `${roundedProgress}%`,
    );
    if (roundedProgress === 100) {
      upload.progressTextElement.textContent = this.#successText();
    } else {
      upload.progressTextElement.textContent = `${roundedProgress}%`;
    }
  }

  #markNonErrorUploadsComplete(uploadKeys) {
    for (const uploadKey of uploadKeys) {
      const upload = this.#uploads.get(uploadKey);
      if (!upload) continue;
      if (upload.status === "error") continue;

      upload.status = "complete";
      upload.rowElement.classList.remove("direct-upload--pending");
      upload.rowElement.classList.add("direct-upload--complete");
      this.#setUploadStatusMessage(upload, "complete", this.#successText());
    }
  }

  #clearBatchUploads(uploadKeys) {
    for (const uploadKey of uploadKeys) {
      this.#uploads.delete(uploadKey);
      this.#pendingUploadKeys.delete(uploadKey);
    }
  }

  #rememberSubmitButtonState() {
    if (this.#submitButtonState) return;

    this.#submitButtonState = {
      disabled: this.submitButtonTarget.disabled,
      label: this.#submitButtonLabel(),
    };
  }

  #restoreSubmitButtonState() {
    if (!this.#submitButtonState) return;

    this.submitButtonTarget.disabled = this.#submitButtonState.disabled;
    this.#setSubmitButtonLabel(this.#submitButtonState.label);
    this.#submitButtonState = undefined;
  }

  #setSubmitButtonUploadingState() {
    this.submitButtonTarget.disabled = true;
    this.#setSubmitButtonLabel(this.#uploadingText());
  }

  #submitButtonLabel() {
    return this.submitButtonTarget.matches("input[type='submit']")
      ? this.submitButtonTarget.value
      : this.submitButtonTarget.textContent;
  }

  #setSubmitButtonLabel(label) {
    if (this.submitButtonTarget.matches("input[type='submit']")) {
      this.submitButtonTarget.value = label;
      return;
    }

    this.submitButtonTarget.textContent = label;
  }

  #uploadingText() {
    return this.hasUploadingTextValue ? this.uploadingTextValue : "Uploading";
  }

  #successText() {
    return this.hasSuccessTextValue
      ? this.successTextValue
      : "Uploaded successfully";
  }

  #errorFallbackText() {
    return this.hasErrorFallbackTextValue
      ? this.errorFallbackTextValue
      : "Upload failed";
  }

  #disableAttachmentsInput() {
    this.attachmentsInputTarget.disabled = true;
  }

  #enableAttachmentsInput() {
    this.attachmentsInputTarget.disabled = false;
  }

  #clearSelectedFiles() {
    this.attachmentsInputTarget.value = "";
  }

  #clearDirectUploadHiddenInputs() {
    if (!this.#formElement) return;

    const fieldName = this.attachmentsInputTarget.name;
    const hiddenInputs = this.#formElement.querySelectorAll(
      "input[type='hidden']",
    );

    for (const hiddenInput of hiddenInputs) {
      if (hiddenInput.name === fieldName) {
        hiddenInput.remove();
      }
    }
  }

  #showUploadErrorAlert() {
    if (!this.hasUploadErrorAlertTarget) return;
    this.uploadErrorAlertTarget.classList.remove("hidden");
  }

  #hideUploadErrorAlert() {
    if (!this.hasUploadErrorAlertTarget) return;
    this.uploadErrorAlertTarget.classList.add("hidden");
  }

  #showFormErrorAlert() {
    if (!this.hasFormErrorAlertTarget) return;
    this.formErrorAlertTarget.classList.remove("hidden");
  }

  #hideFormErrorAlert() {
    if (!this.hasFormErrorAlertTarget) return;
    this.formErrorAlertTarget.classList.add("hidden");
  }

  #hideErrorAlerts() {
    this.#hideUploadErrorAlert();
    this.#hideFormErrorAlert();
  }
}
