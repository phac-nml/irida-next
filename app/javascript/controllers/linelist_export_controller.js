import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["sampleStatus", "progressTemplate"];
  static values = {
    workerUrl: String,
    noSelectionErrorMessage: {
      type: String,
      default: "Please select at least 1 sample before exporting.",
    },
    selectedCountMessage: {
      type: String,
      default: "Selected samples: %{count}",
    },
    preparingRowsMessage: { type: String, default: "Preparing %{count} rows" },
    preparingExportMessage: {
      type: String,
      default: "Preparing linelist export for %{count} rows...",
    },
    startErrorMessage: {
      type: String,
      default: "Unable to start export: %{message}",
    },
    xlsxUnsupportedMessage: {
      type: String,
      default: "XLSX export is not supported in this client-side flow yet.",
    },
    unexpectedErrorMessage: {
      type: String,
      default: "Unexpected error while generating export: %{message}",
    },
    downloadStartedMessage: {
      type: String,
      default: "Download started: %{filename}",
    },
    createdRecordsMessage: {
      type: String,
      default: "Created %{current} of %{total} records",
    },
  };

  connect() {
    this.worker = null;
    this.progressWindowDismissed = false;
    this.updateSelectedCount();
  }

  disconnect() {
    // Keep in-progress progress UI across Turbo page transitions.
    // Intentionally no-op so active exports continue while users browse.
  }

  submit(event) {
    event.preventDefault();
    event.stopPropagation();
    this.closeDialog();
    this.startExport();
  }

  startExport() {
    const sampleIds = this.selectedSampleIds();
    const metadataFields = this.selectedMetadataFields();
    const format = this.selectedFormat();
    const namespaceId = this.selectedNamespaceId();
    const selectedCount = sampleIds.length;

    if (!selectedCount) {
      this.updateProgress(this.t(this.noSelectionErrorMessageValue), 100, true);
      return;
    }

    if (format !== "csv") {
      this.updateProgress(
        this.t(this.xlsxUnsupportedMessageValue, { format }),
        100,
        true,
      );
      return;
    }

    const filename = `linelist-${new Date().toISOString().replace(/[:.]/g, "-")}.${format}`;
    const totalCount = selectedCount;
    this.progressWindowDismissed = false;

    if (this.hasSampleStatusTarget) {
      this.sampleStatusTarget.textContent = this.t(
        this.preparingExportMessageValue,
        { count: totalCount },
      );
    }

    try {
      this.showProgressWindow(
        this.t(this.preparingRowsMessageValue, { count: totalCount }),
      );
      this.spawnWorker();

      this.worker.postMessage({
        sample_ids: sampleIds,
        metadata_fields: metadataFields,
        namespace_id: namespaceId,
        format,
        filename,
        total_count: totalCount,
      });
    } catch (error) {
      this.updateProgress(
        this.t(this.startErrorMessageValue, {
          message: error?.message || "unknown error",
        }),
        100,
        true,
      );
      this.terminateWorker();
    }
  }

  terminateWorker() {
    if (this.worker) {
      this.worker.terminate();
      this.worker = null;
    }
  }

  spawnWorker() {
    this.terminateWorker();

    const workerSource = this.workerSourceUrl();
    const worker = this.buildWorker(workerSource);
    worker.onmessage = (event) => this.handleWorkerMessage(event);
    worker.onerror = (event) => {
      const detail = event?.message || event?.error?.message || "";
      const message = this.t(this.unexpectedErrorMessageValue, {
        message: detail,
      }).replace(/:\s*$/, "");
      this.updateProgress(message, 100, true);
    };
    this.worker = worker;
  }

  buildWorker(workerSource) {
    try {
      return new Worker(workerSource, { type: "module" });
    } catch {
      return new Worker(workerSource);
    }
  }

  handleWorkerMessage(event) {
    const payload = event.data || {};

    if (payload.type === "progress") {
      const message = this.t(this.createdRecordsMessageValue, {
        current: payload.current,
        total: payload.total,
      });
      this.updateProgress(message, payload.percentage);
      return;
    }

    if (payload.type === "done") {
      this.download(payload.filename, payload.content);
      this.updateProgress(
        this.t(this.downloadStartedMessageValue, {
          filename: payload.filename,
        }),
        100,
      );
      setTimeout(() => {
        this.dismissProgressWindow();
      }, 2500);
      this.terminateWorker();
      return;
    }

    if (payload.type === "error") {
      this.updateProgress(payload.message, 100, true);
      this.terminateWorker();
    }
  }

  updateProgress(message, percentage, error = false) {
    if (this.progressWindowDismissed) return;

    const percent = Math.min(Math.max(percentage, 0), 100);
    this.ensureProgressWindow();

    if (this._progressMsgEl) {
      this._progressMsgEl.textContent = message;
      if (error) {
        this._progressMsgEl.setAttribute("role", "alert");
        this._progressMsgEl.removeAttribute("aria-live");
      } else {
        this._progressMsgEl.setAttribute("aria-live", "polite");
        this._progressMsgEl.removeAttribute("role");
      }
    }

    if (this._progressBarEl) {
      this._progressBarEl.style.width = `${percent}%`;
      this._progressBarEl.setAttribute("aria-valuenow", Math.round(percent));
      this._progressBarEl.classList.toggle("bg-red-600", error);
      this._progressBarEl.classList.toggle("bg-primary-600", !error);
    }

    if (this._progressPctEl) {
      this._progressPctEl.textContent = `${Math.round(percent)}%`;
    }
  }

  download(filename, csvContent) {
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = filename;
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    URL.revokeObjectURL(url);
  }

  closeDialog() {
    const dialogHost = this.element.closest(
      '[data-controller~="viral--dialog"]',
    );
    if (!dialogHost) return;

    const dialogController =
      this.application.getControllerForElementAndIdentifier(
        dialogHost,
        "viral--dialog",
      );

    if (dialogController?.close) {
      dialogController.close();
      return;
    }

    const dialogElement = dialogHost.querySelector(
      "[data-viral--dialog-target='dialog']",
    );
    if (dialogElement?.close) {
      dialogElement.close();
    }
  }

  selectedMetadataFields() {
    return Array.from(
      this.element.querySelectorAll(
        "input[name='data_export[export_parameters][metadata_fields][]']:checked",
      ),
    ).map((checkbox) => checkbox.value);
  }

  selectedFormat() {
    const selected = this.element.querySelector(
      "input[name='data_export[export_parameters][linelist_format]']:checked",
    );
    return selected?.value || "csv";
  }

  selectedNamespaceId() {
    const namespaceInput = this.element.querySelector(
      "input[name='data_export[export_parameters][namespace_id]']",
    );
    return namespaceInput?.value || "";
  }

  selectedSampleIds() {
    const storageKey = this.selectionStorageKey();
    const value = sessionStorage.getItem(storageKey);
    if (!value) return [];

    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  selectionStorageKey() {
    return `${location.protocol}//${location.host}${location.pathname}`;
  }

  updateSelectedCount() {
    const selected = this.selectedSampleIds().length;
    if (this.hasSampleStatusTarget) {
      this.sampleStatusTarget.textContent = this.t(
        this.selectedCountMessageValue,
        { count: selected },
      );
    }
  }

  handleProgressWindowClick(event) {
    if (!event?.target?.closest?.('[data-linelist-export-dismiss="true"]'))
      return;
    this.dismissProgressWindow();
  }

  dismissProgressWindow() {
    const progressWindow = document.getElementById(
      "linelist-export-progress-window",
    );
    if (!progressWindow) return;

    progressWindow.remove();
    this.progressWindowDismissed = true;
    this._progressMsgEl = null;
    this._progressBarEl = null;
    this._progressPctEl = null;
  }

  ensureProgressWindow() {
    let progressWindow = document.getElementById(
      "linelist-export-progress-window",
    );
    if (!progressWindow) {
      progressWindow = this.createProgressWindow();
    } else if (!this._progressMsgEl) {
      // Recover refs after Turbo reconnect
      this._progressMsgEl = progressWindow.querySelector(
        "[data-linelist-export-progress-message]",
      );
      this._progressBarEl = progressWindow.querySelector(
        "[data-linelist-export-progress-bar]",
      );
      this._progressPctEl = progressWindow.querySelector(
        "[data-linelist-export-progress-percent]",
      );
    }
    return progressWindow;
  }

  createProgressWindow() {
    const progressWindow = document.createElement("div");
    progressWindow.id = "linelist-export-progress-window";
    progressWindow.className = "fixed bottom-5 right-5 z-50 w-80 space-y-2";
    progressWindow.setAttribute("data-turbo-permanent", "");
    progressWindow.addEventListener("click", (event) =>
      this.handleProgressWindowClick(event),
    );

    if (this.hasProgressTemplateTarget) {
      const clone = this.progressTemplateTarget.content.cloneNode(true);
      this._progressMsgEl = clone.querySelector(
        "[data-linelist-export-progress-message]",
      );
      this._progressBarEl = clone.querySelector(
        "[data-linelist-export-progress-bar]",
      );
      this._progressPctEl = clone.querySelector(
        "[data-linelist-export-progress-percent]",
      );
      progressWindow.appendChild(clone);
    }

    document.body.appendChild(progressWindow);
    return progressWindow;
  }

  showProgressWindow(message) {
    this.updateProgress(message, 0);
  }

  workerSourceUrl() {
    if (this.hasWorkerUrlValue && this.workerUrlValue) {
      return this.workerUrlValue;
    }

    const resolvedFromImportMap = this.workerSourceFromImportMap();
    if (resolvedFromImportMap) {
      return new URL(resolvedFromImportMap, location.origin).href;
    }

    return new URL("../workers/linelist_export_worker.js", import.meta.url)
      .href;
  }

  workerSourceFromImportMap() {
    const importMapScript = document.querySelector("script[type='importmap']");
    if (!importMapScript?.textContent) return null;

    try {
      const importMap = JSON.parse(importMapScript.textContent);
      return (
        importMap?.imports?.["workers/linelist_export_worker"] ||
        importMap?.imports?.["controllers/linelist_export_worker"] ||
        null
      );
    } catch (_error) {
      return null;
    }
  }

  t(template, vars = {}) {
    return Object.entries(vars).reduce(
      (str, [key, val]) => str.replace(`%{${key}}`, val),
      template,
    );
  }
}
