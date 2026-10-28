import Controller from "controllers/metadata/file_import_controller";
import { resolveLinelistImportWorkerSource } from "controllers/linelist_import/worker_source";
import { closeDialog, ensureDialog, openDialog } from "utilities/dialog";
import { ensureFlash } from "utilities/flash";
import { t } from "utilities/message_formatter";
import {
  clearProgressWindowDismissTimeout,
  scheduleProgressWindowDismiss,
  showProgressWindow,
  updateProgressWindow,
} from "utilities/progress_window";

export default class extends Controller {
  static targets = [
    "alertTemplate",
    "dialogTemplate",
    "errorMessage",
    "flashTemplate",
    "progressTemplate",
  ];
  static values = {
    workerUrl: String,
    graphqlUrl: String,
    groupPuid: String,
    projectPuid: String,
    minimumVisibleDurationMs: {
      type: Number,
      default: 3500,
    },
    importStartedMessage: {
      type: String,
      default: "Starting metadata import...",
    },
    importedRecordsMessage: {
      type: String,
      default: "Imported %{current} of %{total} records",
    },
    importCompleteMessage: {
      type: String,
      default: "The metadata import is complete",
    },
    importRetryMessage: {
      type: String,
      default: "Retrying import (attempt %{attempt} of %{maxAttempts})",
    },
    duplicateHeadersMessage: {
      type: String,
      default:
        "The uploaded spreadsheet contains duplicate column headers. Please rename them before importing.",
    },
    noValidMetadataMessage: {
      type: String,
      default: "The uploaded spreadsheet contains no viable metadata",
    },
    errorMessage: {
      type: String,
      default: "Unexpected error while importing metadata: %{message}",
    },
  };

  connect() {
    this._fileType = null;
    this._operationId ||= null;
    this._progressWindowOpenedAt ||= null;
    this._dismissProgressWindowTimeout ||= null;
    this.progressWindowDismissed ??= false;
    this._file = null;
    // Init before super.connect so a file processed on connect (pre-selected) is not reset.
    super.connect();
  }

  readFile(event) {
    const { files } = event.target;

    super.removeSampleIDInputOptions();
    super.resetDialogState();
    super.disableErrorState();
    this.errorMessageTarget.textContent = this.noValidMetadataMessageValue;

    if (!files.length) {
      return;
    }

    const file = files[0];
    this._file = file;
    this._fileType = file.type;
    this.#terminateWorker();
    this._worker = this.#buildWorker();
    this._worker?.postMessage({ type: "read_headers", file });
  }

  handleSubmit(event) {
    event.preventDefault();
    event.stopPropagation();
    this.#terminateWorker();
    this._worker = this.#buildWorker();
    if (!this._worker) return;

    closeDialog(this.element, this.application);
    this._operationId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
    clearProgressWindowDismissTimeout(this);
    this.progressWindowDismissed = false;
    this._progressWindowOpenedAt = null;
    showProgressWindow(this, t(this.importStartedMessageValue));
    this.#processRows();
  }

  #processRows() {
    const selectedMetadataColumns = Array.from(
      this.element.querySelectorAll('[name="file_import[metadata_columns][]"]'),
      (el) => el.value,
    );

    const ignoreEmptyValues = this.element.querySelector(
      '[name="file_import[ignore_empty_values]"]',
    ).checked;

    this._worker.postMessage({
      csrf_token: this.#csrfToken(),
      mime_type: this._fileType,
      graphql_url: this.graphqlUrlValue,
      group_puid: this.groupPuidValue,
      project_puid: this.projectPuidValue,
      file: this._file,
      sample_id_column: this.sampleIdColumnTarget.value,
      metadata_columns: selectedMetadataColumns,
      ignore_empty_values: ignoreEmptyValues,
    });
  }

  #onHeaders({ headers }) {
    this.headers = headers;

    if (this.#hasDuplicateHeaders()) {
      this.errorMessageTarget.textContent = this.duplicateHeadersMessageValue;
      this.#showDuplicateHeadersError();
      return;
    }

    super.addSampleIDInputOptions();
  }

  #buildWorker() {
    let worker;
    if (typeof Worker !== "undefined") {
      worker = new Worker(resolveLinelistImportWorkerSource(this), {
        type: "module",
      });

      worker.onerror = (error) => {
        console.error("Worker failed:", error.message);
        this.#terminateWorker();
      };

      // Listen for messages from the worker
      worker.onmessage = (event) => {
        const payload = event.data || {};

        if (payload.type === "headers") {
          this.#onHeaders(payload);
        }

        if (payload.type === "progress") {
          this.#onProgress(payload);
        }

        if (payload.type === "retry") {
          this.#onRetry(payload);
        }

        if (payload.type === "done") {
          this.#onDone();
        }

        if (payload.type === "error") {
          this.#onError(payload);
        }
      };
    } else {
      console.error("Web Workers are not supported in this browser.");
    }

    return worker;
  }

  #errorMessageNode(error) {
    const clone = this.alertTemplateTarget.content.cloneNode(true);
    const walker = document.createTreeWalker(clone, NodeFilter.SHOW_TEXT);
    let currentNode = walker.nextNode();

    while (currentNode) {
      if (currentNode.textContent?.includes("PLACEHOLDER")) {
        currentNode.textContent = currentNode.textContent.replaceAll(
          "PLACEHOLDER",
          error,
        );
      }

      currentNode = walker.nextNode();
    }

    return clone.firstElementChild;
  }

  #onProgress(payload) {
    const message = t(this.importedRecordsMessageValue, {
      current: payload.current,
      total: payload.total,
    });

    if (payload.result?.overallStatus === "successful") {
      if (payload.current === payload.total) {
        ensureFlash(this);
      }
    } else if (
      payload.result?.overallStatus === "unsuccessful" ||
      payload.result?.overallStatus === "successful with errors"
    ) {
      const dialog = ensureDialog(this);
      if (dialog) {
        payload.result?.errors.forEach((error) => {
          const errorMessage = this.#errorMessageNode(error.message);
          const errorMessageList = dialog.querySelector("#error-messages");
          if (errorMessageList && errorMessage) {
            errorMessageList.append(errorMessage);
          }
        });
        if (payload.current === payload.total) {
          openDialog(dialog, this.application);
        }
      }
    }

    updateProgressWindow(
      this,
      message,
      (payload.current / payload.total) * 100,
    );
  }

  #onDone() {
    const message = t(this.importCompleteMessageValue);
    updateProgressWindow(this, message, 100);
    scheduleProgressWindowDismiss(this);
    this.#terminateWorker();
  }

  #onRetry(payload) {
    const message = t(this.importRetryMessageValue, {
      attempt: payload.attempt,
      maxAttempts: payload.maxAttempts,
    });
    updateProgressWindow(
      this,
      message,
      (payload.current / payload.total) * 100,
    );
  }

  #onError(payload) {
    const message = t(this.errorMessageValue, { message: payload.message });
    updateProgressWindow(this, message, 100, true);
    this.#terminateWorker();
  }

  #csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute("content") : "";
  }

  #showDuplicateHeadersError() {
    this.errorTarget.classList.remove("hidden");
    this.errorTarget.removeAttribute("aria-hidden");
    this.submitButtonTarget.disabled = true;
    this.submitButtonTarget.setAttribute("aria-disabled", "true");
  }

  #hasDuplicateHeaders() {
    const normalizedHeaders = this.headers
      .filter((header) => header != null && String(header).trim() !== "")
      .map((header) => String(header).trim().toLowerCase());

    return new Set(normalizedHeaders).size !== normalizedHeaders.length;
  }

  #terminateWorker() {
    if (this._worker) {
      this._worker.terminate();
      this._worker = null;
    }
  }
}
