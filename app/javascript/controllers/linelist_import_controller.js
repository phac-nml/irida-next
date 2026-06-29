import * as XLSX from "xlsx";
import Controller from "controllers/metadata/file_import_controller";
import { omitBy, pick } from "utilities/collection";
import { closeDialog, ensureDialog, openDialog } from "utilities/dialog";
import { ensureFlash } from "utilities/flash";
import { t } from "utilities/message_formatter";
import {
  scheduleProgressWindowDismiss,
  showProgressWindow,
  updateProgressWindow,
} from "utilities/progress_window";

export default class extends Controller {
  static targets = [
    "alertTemplate",
    "dialogTemplate",
    "flashTemplate",
    "progressTemplate",
  ];
  static values = {
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
    errorMessage: {
      type: String,
      default: "Unexpected error while importing metadata: %{message}",
    },
  };

  connect() {
    super.connect();
    this._fileType = null;
    this._operationId ||= null;
    this._progressWindowOpenedAt ||= null;
    this._worksheet = null;
  }

  readFile(event) {
    const { files } = event.target;

    super.removeSampleIDInputOptions();
    super.resetDialogState();
    super.disableErrorState();

    if (!files.length) {
      return;
    }

    const file = files[0];
    this._fileType = file.type;
    const reader = new FileReader();
    reader.readAsArrayBuffer(file);

    reader.onload = () => {
      const workbook = XLSX.read(reader.result);
      const worksheetName = workbook.SheetNames[0];
      this._worksheet = workbook.Sheets[worksheetName];
      this.headers = XLSX.utils.sheet_to_json(this._worksheet, {
        header: 1,
      })[0];
      super.addSampleIDInputOptions();
    };
  }

  handleSubmit(event) {
    event.preventDefault();
    event.stopPropagation();
    this._worker?.terminate();
    this._worker ||= this.#buildWorker();
    closeDialog(this.element, this.application);
    this._operationId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
    this._progressWindowOpenedAt = null;
    showProgressWindow(this, t(this.importStartedMessageValue));
    this.#processRows();
  }

  #processRows() {
    const allRows = XLSX.utils.sheet_to_json(this._worksheet, {
      header: this.headers,
      range: 1,
      defval: null,
    });

    const selectedMetadataColumns = Array.from(
      this.element.querySelectorAll('[name="file_import[metadata_columns][]"]'),
      (el) => el.value,
    );

    const ignoreEmptyValues = this.element.querySelector(
      '[name="file_import[ignore_empty_values]"]',
    ).checked;

    const rows = allRows.map((row) => [
      row[this.sampleIdColumnTarget.value],
      omitBy(
        pick(row, selectedMetadataColumns),
        (value) => ignoreEmptyValues && value == null,
      ),
    ]);

    // Send data to worker
    this._worker.postMessage({
      csrf_token: this.#csrfToken(),
      mime_type: this._fileType,
      graphql_url: this.graphqlUrlValue,
      group_puid: this.groupPuidValue,
      project_puid: this.projectPuidValue,
      rows: rows,
    });
  }

  #buildWorker() {
    let worker;

    if (typeof Worker !== "undefined") {
      worker = new Worker(
        import.meta.resolve("workers/linelist_import_worker"),
        { type: "module" },
      );

      worker.onerror = (error) => {
        console.error("Worker failed:", error.message);
        this.#terminateWorker();
      };

      // Listen for messages from the worker
      worker.onmessage = (event) => {
        const payload = event.data || {};

        if (payload.type === "progress") {
          this.#onProgress(payload);
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

  #onError(payload) {
    const message = t(this.errorMessageValue, { message: payload.message });
    updateProgressWindow(this, message, 100, true);
    this.#terminateWorker();
  }

  #csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta ? meta.getAttribute("content") : "";
  }

  #terminateWorker() {
    if (this._worker) {
      this._worker.terminate();
      this._worker = null;
    }
  }
}
