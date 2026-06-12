import { Controller } from "@hotwired/stimulus";
import {
  downloadExport,
  XlsxLibraryLoadError,
} from "controllers/linelist_export/downloader";
import {
  clearProgressWindowDismissTimeout as clearProgressWindowDismissTimeoutState,
  dismissProgressWindow as dismissProgressWindowState,
  scheduleProgressWindowDismiss as scheduleProgressWindowDismissState,
  showProgressWindow as showProgressWindowState,
  updateProgressWindow,
} from "utilities/progress_window";
import { t } from "utilities/message_formatter";
import {
  csrfToken as csrfTokenFromDocument,
  selectedFormat as selectedFormatFromForm,
  selectedMetadataFields as selectedMetadataFieldsFromList,
  selectedNamespaceId as selectedNamespaceIdFromForm,
  selectedSampleIds as selectedSampleIdsFromSession,
  selectionStorageKey as buildSelectionStorageKey,
} from "controllers/linelist_export/selection";
import {
  LinelistExportWorkerClient,
  resolveLinelistExportWorkerSource,
} from "controllers/linelist_export/worker_client";
import { closeDialog } from "utilities/dialog";

let activeExports = 0;
let beforeUnloadHandler = null;

function bindExportBeforeUnload() {
  if (beforeUnloadHandler) return;

  beforeUnloadHandler = (event) => {
    if (activeExports <= 0) return;

    event.preventDefault();
    event.returnValue = "";
    return "";
  };

  window.addEventListener("beforeunload", beforeUnloadHandler);
}

function unbindExportBeforeUnload() {
  if (!beforeUnloadHandler) return;

  window.removeEventListener("beforeunload", beforeUnloadHandler);
  beforeUnloadHandler = null;
}

function startExportBeforeUnloadGuard() {
  activeExports += 1;
  bindExportBeforeUnload();
}

function stopExportBeforeUnloadGuard() {
  activeExports = Math.max(activeExports - 1, 0);

  if (activeExports === 0) {
    unbindExportBeforeUnload();
  }
}

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
    xlsxLoadErrorMessage: {
      type: String,
      default:
        "Unable to load the XLSX export library. Please retry or export as CSV.",
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
    // Preserve in-flight export state if Stimulus reconnects this controller.
    this.workerClient ||= this.buildWorkerClient();
    this._exportId ||= null;
    this._progressWindowOpenedAt ||= null;
    this._dismissProgressWindowTimeout ||= null;
    this._progressMsgEl = null;
    this._progressBarEl = null;
    this._progressPctEl = null;
    this.progressWindowDismissed ??= false;
    this.updateSelectedCount();
  }

  disconnect() {
    // Keep in-progress progress UI across Turbo page transitions.
    // Intentionally no-op so active exports continue while users browse.
  }

  submit(event) {
    event.preventDefault();
    event.stopPropagation();
    closeDialog(this.element, this.application);
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
      this.updateProgress(t(this.noSelectionErrorMessageValue), 100, true);
      return;
    }

    const filename = `linelist-${new Date().toISOString().replace(/[:.]/g, "-")}.${format}`;
    const totalCount = selectedCount;
    this.clearProgressWindowDismissTimeout();
    this._exportId = `${Date.now()}-${Math.random().toString(36).slice(2, 7)}`;
    this._progressWindowOpenedAt = null;
    this.progressWindowDismissed = false;

    if (this.hasSampleStatusTarget) {
      this.sampleStatusTarget.textContent = t(
        this.preparingExportMessageValue,
        { count: totalCount },
      );
    }

    try {
      this.showProgressWindow(
        t(this.preparingRowsMessageValue, { count: totalCount }),
      );

      startExportBeforeUnloadGuard();

      this.workerClient.start({
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
        t(this.startErrorMessageValue, {
          message: error?.message || "unknown error",
        }),
        100,
        true,
      );
      this.terminateWorker();
    }
  }

  terminateWorker() {
    this.workerClient?.stop();
    stopExportBeforeUnloadGuard();
  }

  buildWorkerClient() {
    return new LinelistExportWorkerClient({
      resolveWorkerSource: () => resolveLinelistExportWorkerSource(this),
      onProgress: (payload) => {
        this.handleWorkerProgress(payload);
      },
      onDone: async (payload) => {
        await this.handleWorkerDone(payload);
      },
      onError: (message) => {
        this.handleWorkerError(message);
      },
      formatUnexpectedError: (detail) => this.formatUnexpectedError(detail),
    });
  }

  handleWorkerProgress(payload) {
    const message = t(this.createdRecordsMessageValue, {
      current: payload.current,
      total: payload.total,
    });
    this.updateProgress(message, payload.percentage);
  }

  async handleWorkerDone(payload) {
    try {
      await this.download(payload.filename, payload.content, payload.format);
    } catch (error) {
      if (error instanceof XlsxLibraryLoadError) {
        this.handleWorkerError(t(this.xlsxLoadErrorMessageValue));
        return;
      }

      this.handleWorkerError(this.formatUnexpectedError(error?.message || ""));
      return;
    }

    this.updateProgress(
      t(this.downloadStartedMessageValue, {
        filename: payload.filename,
      }),
      100,
    );
    this.scheduleProgressWindowDismiss();
    this.terminateWorker();
  }

  handleWorkerError(message) {
    this.updateProgress(message, 100, true);
    this.terminateWorker();
  }

  formatUnexpectedError(detail) {
    return t(this.unexpectedErrorMessageValue, {
      message: detail,
    }).replace(/:\s*$/, "");
  }

  updateProgress(message, percentage, error = false) {
    updateProgressWindow(this, message, percentage, error);
  }

  async download(filename, content, format = "csv") {
    await downloadExport(filename, content, format);
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
      this.sampleStatusTarget.textContent = t(this.selectedCountMessageValue, {
        count: selected,
      });
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
}
