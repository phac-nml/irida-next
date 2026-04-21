import { Controller } from "@hotwired/stimulus";
import { downloadExport } from "controllers/linelist_export/downloader";
import {
  clearProgressWindowDismissTimeout as clearProgressWindowDismissTimeoutState,
  dismissProgressWindow as dismissProgressWindowState,
  scheduleProgressWindowDismiss as scheduleProgressWindowDismissState,
  showProgressWindow as showProgressWindowState,
  updateProgressWindow,
} from "controllers/linelist_export/progress_window";
import {
  csrfToken as csrfTokenFromDocument,
  selectedFormat as selectedFormatFromForm,
  selectedMetadataFields as selectedMetadataFieldsFromList,
  selectedNamespaceId as selectedNamespaceIdFromForm,
  selectedSampleIds as selectedSampleIdsFromSession,
  selectionStorageKey as buildSelectionStorageKey,
} from "controllers/linelist_export/selection";

export default class extends Controller {
  static targets = ["sampleStatus", "progressTemplate"];
  static values = {
    workerUrl: String,
    graphqlUrl: String,
    sampleGraphqlIdPrefix: String,
    minimumVisibleDurationMs: {
      type: Number,
      default: 3500,
    },
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
    this._exportId = null;
    this._progressWindowOpenedAt = null;
    this._dismissProgressWindowTimeout = null;
    this._progressMsgEl = null;
    this._progressBarEl = null;
    this._progressPctEl = null;
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
    const graphqlUrl = this.graphqlUrl();
    const sampleGraphqlIdPrefix = this.sampleGraphqlIdPrefix();
    const selectedCount = sampleIds.length;

    if (!selectedCount) {
      this.updateProgress(this.t(this.noSelectionErrorMessageValue), 100, true);
      return;
    }

    const filename = `linelist-${new Date().toISOString().replace(/[:.]/g, "-")}.${format}`;
    const totalCount = selectedCount;
    this.clearProgressWindowDismissTimeout();
    this._exportId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
    this._progressWindowOpenedAt = null;
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
        graphql_url: graphqlUrl,
        csrf_token: this.csrfToken(),
        sample_graphql_id_prefix: sampleGraphqlIdPrefix,
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
    worker.onmessage = (event) => {
      void this.handleWorkerMessage(event);
    };
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
    } catch (error) {
      console.warn(
        "[linelist-export] Module worker unavailable, falling back to classic worker:",
        error,
      );
      return new Worker(workerSource);
    }
  }

  async handleWorkerMessage(event) {
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
      try {
        await this.download(payload.filename, payload.content, payload.format);
      } catch (error) {
        const detail = error?.message || "";
        const message = this.t(this.unexpectedErrorMessageValue, {
          message: detail,
        }).replace(/:\s*$/, "");
        this.updateProgress(message, 100, true);
        this.terminateWorker();
        return;
      }

      this.updateProgress(
        this.t(this.downloadStartedMessageValue, {
          filename: payload.filename,
        }),
        100,
      );
      this.scheduleProgressWindowDismiss();
      this.terminateWorker();
      return;
    }

    if (payload.type === "error") {
      this.updateProgress(payload.message, 100, true);
      this.terminateWorker();
    }
  }

  updateProgress(message, percentage, error = false) {
    updateProgressWindow(this, message, percentage, error);
  }

  async download(filename, content, format = "csv") {
    await downloadExport(filename, content, format);
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
    return selectedMetadataFieldsFromList(this.element);
  }

  selectedFormat() {
    return selectedFormatFromForm(this.element);
  }

  selectedNamespaceId() {
    return selectedNamespaceIdFromForm(this.element);
  }

  selectedSampleIds() {
    return selectedSampleIdsFromSession(this.selectionStorageKey());
  }

  graphqlUrl() {
    return this.graphqlUrlValue;
  }

  csrfToken() {
    return csrfTokenFromDocument();
  }

  sampleGraphqlIdPrefix() {
    return this.sampleGraphqlIdPrefixValue;
  }

  selectionStorageKey() {
    return buildSelectionStorageKey();
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

  dismissProgressWindow() {
    dismissProgressWindowState(this);
  }

  showProgressWindow(message) {
    showProgressWindowState(this, message);
  }

  scheduleProgressWindowDismiss() {
    scheduleProgressWindowDismissState(this);
  }

  clearProgressWindowDismissTimeout() {
    clearProgressWindowDismissTimeoutState(this);
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
      return importMap?.imports?.["workers/linelist_export_worker"] || null;
    } catch {
      return null;
    }
  }

  t(template, vars = {}) {
    return Object.entries(vars).reduce(
      (str, [key, val]) => str.replaceAll(`%{${key}}`, val),
      template,
    );
  }
}
