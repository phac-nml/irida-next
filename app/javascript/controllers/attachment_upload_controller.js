import { Controller } from "@hotwired/stimulus";

const UPLOAD_ROWS_ROLE = "upload-rows";

export default class extends Controller {
  static targets = ["submitButton", "attachmentsInput"];
  static values = {
    uploadingText: String,
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
    }

    this.attachmentsInputTarget.setAttribute("aria-required", "true");
    this.attachmentsInputTarget.setAttribute("aria-invalid", "false");
    this.submitButtonTarget.disabled = true;
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

    this.#hideAttachmentsInput();
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
    upload.rowElement.classList.add("direct-upload--error", "border-rose-600");
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
    this.#setUploadProgress(id, 100, { force: true });
  }

  uploadsStart(event) {
    if (!this.#isThisFormEvent(event)) return;

    this.#batchInProgress = true;
    this.#hasUploadError = false;
    for (const uploadKey of this.#pendingUploadKeys) {
      this.#activeUploadKeys.add(uploadKey);
    }
    this.#pendingUploadKeys.clear();

    if (this.#activeUploadKeys.size === 0) return;

    this.#hideAttachmentsInput();
    this.#rememberSubmitButtonState();
    this.#setSubmitButtonUploadingState();
  }

  uploadsEnd(event) {
    if (!this.#isThisFormEvent(event)) return;
    if (this.#activeUploadKeys.size === 0) {
      this.#batchInProgress = false;
      return;
    }

    if (!this.#hasUploadError) {
      this.#markNonErrorUploadsComplete(this.#activeUploadKeys);
      this.attachmentsInputTarget.setAttribute("aria-invalid", "false");
    }

    this.#showAttachmentsInput();
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
    this._onAllStart = this.uploadsStart.bind(this);
    this._onAllEnd = this.uploadsEnd.bind(this);
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
      "direct-upload direct-upload--pending flex-1 relative mb-1";

    const filenameRow = document.createElement("div");
    filenameRow.className = "flex justify-between mb-1 direct-upload__filename";

    const fileNameElement = document.createElement("span");
    fileNameElement.id = `direct-upload-filename-${id}`;
    fileNameElement.className = "text-sm text-gray-500 dark:text-gray-400";
    fileNameElement.textContent = fileName;

    const progressTextElement = document.createElement("span");
    progressTextElement.id = `upload-progress-${id}`;
    progressTextElement.className = "text-sm text-gray-500 dark:text-gray-400";
    progressTextElement.textContent = "0%";

    filenameRow.append(fileNameElement, progressTextElement);

    const progressTrackElement = document.createElement("div");
    progressTrackElement.className =
      "w-full bg-gray-200 rounded-full h-2.5 dark:bg-gray-700";

    const progressBarElement = document.createElement("div");
    progressBarElement.id = `direct-upload-progress-${id}`;
    progressBarElement.className = "bg-primary-600 h-2.5 rounded-full";
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
      progressBarElement,
      progressTextElement,
      status: "pending",
      lastProgress: 0,
    };
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
    upload.progressTextElement.textContent = `${roundedProgress}%`;
  }

  #markNonErrorUploadsComplete(uploadKeys) {
    for (const uploadKey of uploadKeys) {
      const upload = this.#uploads.get(uploadKey);
      if (!upload) continue;
      if (upload.status === "error") continue;

      upload.status = "complete";
      upload.rowElement.classList.remove("direct-upload--pending");
      upload.rowElement.classList.add("direct-upload--complete");
      this.#setUploadProgress(upload.id, 100, { force: true });
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

  #hideAttachmentsInput() {
    this.attachmentsInputTarget.classList.add("hidden");
    this.attachmentsInputTarget.setAttribute("aria-hidden", "true");
  }

  #showAttachmentsInput() {
    this.attachmentsInputTarget.classList.remove("hidden");
    this.attachmentsInputTarget.removeAttribute("aria-hidden");
  }
}
