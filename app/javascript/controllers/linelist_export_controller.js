import { Controller } from "@hotwired/stimulus";

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
    this._exportId = null;
    this._progressWindowOpenedAt = null;
    this._dismissProgressWindowTimeout = null;
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
      this.download(payload.filename, payload.content);
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
