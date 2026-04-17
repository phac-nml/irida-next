import { Controller } from "@hotwired/stimulus";
import * as XLSX from "xlsx";

export default class extends Controller {
  static targets = ["sampleStatus", "progressTemplate"];
  static values = {
    workerUrl: String,
    graphqlUrl: String,
    saveToServerUrl: String,
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
    saveQueuedMessage: {
      type: String,
      default: "Saved to Data Exports (ID: %{id})",
    },
    saveFailedMessage: {
      type: String,
      default: "Download completed, but saving to server failed: %{message}",
    },
  };

  connect() {
    this.worker = null;
    this._exportId = null;
    this._progressWindowOpenedAt = null;
    this._dismissProgressWindowTimeout = null;
    this._pendingSaveRequest = null;
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
    const saveToServer = this.saveToServerSelected();
    const exportName = this.selectedExportName();
    const emailNotification = this.selectedEmailNotification();
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
    this._pendingSaveRequest = {
      saveToServer,
      sampleIds,
      metadataFields,
      namespaceId,
      format,
      exportName,
      emailNotification,
    };

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
      this._pendingSaveRequest = null;
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
    } catch (error) {
      console.warn(
        "[linelist-export] Module worker unavailable, falling back to classic worker:",
        error,
      );
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
      this.download(payload);
      this.updateProgress(
        this.t(this.downloadStartedMessageValue, {
          filename: payload.filename,
        }),
        100,
      );
      const saveRequest = this._pendingSaveRequest;
      this._pendingSaveRequest = null;
      if (saveRequest?.saveToServer) {
        void this.saveToServer(saveRequest);
      } else {
        this.scheduleProgressWindowDismiss();
      }
      this.terminateWorker();
      return;
    }

    if (payload.type === "error") {
      this.updateProgress(payload.message, 100, true);
      this._pendingSaveRequest = null;
      this.terminateWorker();
    }
  }

  updateProgress(message, percentage, error = false) {
    if (this.progressWindowDismissed) return;

    const percent = Math.min(Math.max(percentage, 0), 100);
    this.ensureExportCard();

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
      this._progressBarEl.setAttribute("aria-label", message);
      this._progressBarEl.classList.toggle("bg-red-600", error);
      this._progressBarEl.classList.toggle("bg-primary-600", !error);
    }

    if (this._progressPctEl) {
      this._progressPctEl.textContent = `${Math.round(percent)}%`;
    }
  }

  download(payload) {
    const filename = payload?.filename || "linelist-export.csv";
    const format = payload?.format === "xlsx" ? "xlsx" : "csv";
    const blob =
      format === "xlsx"
        ? this.xlsxBlobFromRows(payload?.rows)
        : new Blob([payload?.content || ""], {
            type: "text/csv;charset=utf-8;",
          });

    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = filename;
    document.body.appendChild(anchor);
    anchor.click();
    anchor.remove();
    URL.revokeObjectURL(url);
  }

  xlsxBlobFromRows(rows) {
    const workbook = XLSX.utils.book_new();
    const sheet = XLSX.utils.aoa_to_sheet(Array.isArray(rows) ? rows : []);
    XLSX.utils.book_append_sheet(workbook, sheet, "Linelist");
    const content = XLSX.write(workbook, { bookType: "xlsx", type: "array" });
    return new Blob([content], {
      type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    });
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
        "input[name='data_export[export_parameters][metadata_fields][]']",
      ),
    ).map((input) => input.value);
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

  selectedExportName() {
    const nameInput = this.element.querySelector(
      "input[name='data_export[name]']",
    );
    return nameInput?.value?.trim() || "";
  }

  selectedEmailNotification() {
    const emailCheckbox = this.element.querySelector(
      "input[name='data_export[email_notification]']",
    );
    return Boolean(emailCheckbox?.checked);
  }

  saveToServerSelected() {
    const checkbox = this.element.querySelector(
      "input[name='data_export[save_to_server]']",
    );
    return Boolean(checkbox?.checked);
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

  graphqlUrl() {
    return this.graphqlUrlValue;
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta?.getAttribute("content") || "";
  }

  sampleGraphqlIdPrefix() {
    return this.sampleGraphqlIdPrefixValue;
  }

  saveToServerUrl() {
    return this.saveToServerUrlValue;
  }

  async saveToServer(request) {
    const saveUrl = this.saveToServerUrl();
    if (!saveUrl) return;

    try {
      const response = await fetch(saveUrl, {
        method: "POST",
        credentials: "same-origin",
        headers: {
          "Content-Type": "application/json",
          Accept: "application/json",
          "X-CSRF-Token": this.csrfToken(),
        },
        body: JSON.stringify({
          data_export: {
            ...(request.exportName ? { name: request.exportName } : {}),
            email_notification: request.emailNotification,
            export_type: "linelist",
            export_parameters: {
              ids: request.sampleIds,
              namespace_id: request.namespaceId,
              linelist_format: request.format,
              metadata_fields: request.metadataFields,
            },
          },
        }),
      });

      let payload = {};
      try {
        payload = await response.json();
      } catch {
        payload = {};
      }

      if (!response.ok) {
        const detail = Array.isArray(payload?.errors)
          ? payload.errors.join(", ")
          : `Request failed (${response.status})`;
        throw new Error(detail);
      }

      const message = this.t(this.saveQueuedMessageValue, {
        id: payload.id,
      });

      if (this.hasSampleStatusTarget) {
        this.sampleStatusTarget.textContent = message;
      }
      this.updateProgress(message, 100);
      this.scheduleProgressWindowDismiss();
    } catch (error) {
      const message = this.t(this.saveFailedMessageValue, {
        message: error?.message || "unknown error",
      });

      if (this.hasSampleStatusTarget) {
        this.sampleStatusTarget.textContent = message;
      }
      this.updateProgress(message, 100, true);
      this.scheduleProgressWindowDismiss();
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
    this.clearProgressWindowDismissTimeout();

    if (this._exportId) {
      const card = document.getElementById(
        `linelist-export-card-${this._exportId}`,
      );
      if (card) card.remove();
    }

    const container = document.getElementById(
      "linelist-export-progress-window",
    );
    if (container && container.children.length === 0) container.remove();

    this.progressWindowDismissed = true;
    this._exportId = null;
    this._progressWindowOpenedAt = null;
    this._progressMsgEl = null;
    this._progressBarEl = null;
    this._progressPctEl = null;
  }

  ensureExportCard() {
    if (!this._exportId) return null;

    const cardId = `linelist-export-card-${this._exportId}`;
    let card = document.getElementById(cardId);

    if (!card) {
      card = this.createExportCard(cardId);
    } else if (!this._progressMsgEl) {
      // Recover refs after Turbo reconnect
      this._progressMsgEl = card.querySelector(
        "[data-linelist-export-progress-message]",
      );
      this._progressBarEl = card.querySelector(
        "[data-linelist-export-progress-bar]",
      );
      this._progressPctEl = card.querySelector(
        "[data-linelist-export-progress-percent]",
      );
    }

    return card;
  }

  ensureProgressContainer() {
    let container = document.getElementById("linelist-export-progress-window");
    if (!container) {
      container = document.createElement("div");
      container.id = "linelist-export-progress-window";
      container.className = "fixed bottom-5 right-5 z-50 w-80 space-y-2";
      container.setAttribute("data-turbo-permanent", "");
      document.body.appendChild(container);
    }
    return container;
  }

  createExportCard(cardId) {
    const container = this.ensureProgressContainer();
    const card = document.createElement("div");
    card.id = cardId;
    card.addEventListener("click", (event) =>
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
      card.appendChild(clone);
    }

    container.appendChild(card);
    return card;
  }

  showProgressWindow(message) {
    if (!this._progressWindowOpenedAt) {
      this._progressWindowOpenedAt = Date.now();
    }
    this.updateProgress(message, 0);
  }

  scheduleProgressWindowDismiss() {
    if (this.progressWindowDismissed) return;

    this.clearProgressWindowDismissTimeout();

    const openedAt = this._progressWindowOpenedAt || Date.now();
    const elapsedMs = Date.now() - openedAt;
    const remainingMs = Math.max(
      this.minimumVisibleDurationMsValue - elapsedMs,
      0,
    );

    this._dismissProgressWindowTimeout = setTimeout(() => {
      this.dismissProgressWindow();
    }, remainingMs);
  }

  clearProgressWindowDismissTimeout() {
    if (!this._dismissProgressWindowTimeout) return;

    clearTimeout(this._dismissProgressWindowTimeout);
    this._dismissProgressWindowTimeout = null;
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
