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
} from "controllers/linelist_export/progress_window";
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
import { uploadLinelistExport } from "controllers/linelist_export/server_upload";

export default class extends Controller {
  static targets = [
    "sampleStatus",
    "progressTemplate",
    "saveToServerNameWrapper",
    "saveToServerNameInput",
  ];
  static values = {
    workerUrl: String,
    graphqlUrl: String,
    uploadUrl: String,
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
    saveToServerUploadingMessage: {
      type: String,
      default: "Saving linelist export to server...",
    },
    saveToServerSuccessMessage: {
      type: String,
      default: "Linelist export saved to server.",
    },
    saveToServerErrorMessage: {
      type: String,
      default: "Upload failed: %{message}",
    },
    viewExportLinkLabel: {
      type: String,
      default: "View saved export",
    },
  };

  connect() {
    // Preserve in-flight export state if Stimulus reconnects this controller.
    this.workerClient ||= this.buildWorkerClient();
    this._exportId ||= null;
    this._progressWindowOpenedAt ||= null;
    this._dismissProgressWindowTimeout ||= null;
    this._pendingUpload ||= null;
    this._lastCompletedPayload ||= null;
    this._progressMsgEl = null;
    this._progressBarEl = null;
    this._progressPctEl = null;
    this.progressWindowDismissed ??= false;
    this.progressWindowActionsEnabled = true;
    this.progressWindowClickHandler ||= (event) =>
      this.handleProgressWindowClick(event);
    this.updateSelectedCount();
    this.toggleSaveToServer();
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
    const saveToServer = this.saveToServerSelected();
    const exportName = this.selectedExportName();
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
    this._pendingUpload = {
      saveToServer,
      name: exportName,
      namespaceId,
      format,
      sampleIds,
      metadataFields,
    };
    this._lastCompletedPayload = null;

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
    this.workerClient?.stop();
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
    const message = this.t(this.createdRecordsMessageValue, {
      current: payload.current,
      total: payload.total,
    });
    this.updateProgress(message, payload.percentage);
  }

  async handleWorkerDone(payload) {
    this._lastCompletedPayload = payload;

    if (this._pendingUpload?.saveToServer) {
      await this.handleServerSave(payload);
      this.terminateWorker();
      return;
    }

    try {
      await this.download(payload.filename, payload.content, payload.format);
    } catch (error) {
      if (error instanceof XlsxLibraryLoadError) {
        this.handleWorkerError(this.t(this.xlsxLoadErrorMessageValue));
        return;
      }

      this.handleWorkerError(this.formatUnexpectedError(error?.message || ""));
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
  }

  handleWorkerError(message) {
    this.updateProgress(message, 100, true);
    this.terminateWorker();
  }

  formatUnexpectedError(detail) {
    return this.t(this.unexpectedErrorMessageValue, {
      message: detail,
    }).replace(/:\s*$/, "");
  }

  updateProgress(message, percentage, error = false) {
    updateProgressWindow(this, message, percentage, error);
  }

  async handleServerSave(payload) {
    this.hideUploadLink();
    this.hideUploadActions();
    this.updateProgress(this.saveToServerUploadingMessageValue, 100);

    try {
      const response = await this.uploadToServer(payload);
      this.updateProgress(this.saveToServerSuccessMessageValue, 100);
      this.showUploadLink(response.url);
    } catch (error) {
      if (error instanceof XlsxLibraryLoadError) {
        this.updateProgress(this.t(this.xlsxLoadErrorMessageValue), 100, true);
      } else {
        this.updateProgress(
          this.t(this.saveToServerErrorMessageValue, {
            message: error?.message || "request failed",
          }),
          100,
          true,
        );
      }

      this.showUploadActions();
    }
  }

  async uploadToServer(payload) {
    if (!this.hasUploadUrlValue || !this.uploadUrlValue) {
      throw new Error("Upload endpoint is not configured.");
    }

    return uploadLinelistExport({
      uploadUrl: this.uploadUrlValue,
      csrfToken: this.csrfToken(),
      payload,
      pendingUpload: this._pendingUpload || {},
    });
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

  saveToServerSelected() {
    const saveToServerInput = this.element.querySelector(
      "input[name='data_export[save_to_server]']",
    );
    return !!saveToServerInput?.checked;
  }

  selectedExportName() {
    if (!this.hasSaveToServerNameInputTarget) return "";

    return this.saveToServerNameInputTarget.value.trim();
  }

  toggleSaveToServer() {
    if (!this.hasSaveToServerNameWrapperTarget) return;

    const showNameInput = this.saveToServerSelected();
    this.saveToServerNameWrapperTarget.classList.toggle(
      "hidden",
      !showNameInput,
    );

    if (!showNameInput && this.hasSaveToServerNameInputTarget) {
      this.saveToServerNameInputTarget.value = "";
    }
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

  handleProgressWindowClick(event) {
    if (event?.target?.closest?.('[data-linelist-export-dismiss="true"]')) {
      this.dismissProgressWindow();
      return;
    }

    if (
      event?.target?.closest?.('[data-linelist-export-retry-upload="true"]')
    ) {
      void this.retryUpload();
      return;
    }

    if (
      event?.target?.closest?.('[data-linelist-export-download-local="true"]')
    ) {
      void this.downloadLocalFallback();
    }
  }

  async retryUpload() {
    if (!this._lastCompletedPayload) return;

    await this.handleServerSave(this._lastCompletedPayload);
  }

  async downloadLocalFallback() {
    if (!this._lastCompletedPayload) return;

    try {
      await this.download(
        this._lastCompletedPayload.filename,
        this._lastCompletedPayload.content,
        this._lastCompletedPayload.format,
      );
    } catch (error) {
      if (error instanceof XlsxLibraryLoadError) {
        this.updateProgress(this.t(this.xlsxLoadErrorMessageValue), 100, true);
      } else {
        this.updateProgress(
          this.formatUnexpectedError(error?.message || ""),
          100,
          true,
        );
      }
      return;
    }

    this.hideUploadActions();
    this.updateProgress(
      this.t(this.downloadStartedMessageValue, {
        filename: this._lastCompletedPayload.filename,
      }),
      100,
    );
    this.scheduleProgressWindowDismiss();
  }

  dismissProgressWindow() {
    dismissProgressWindowState(this);
    this._pendingUpload = null;
    this._lastCompletedPayload = null;
  }

  showProgressWindow(message) {
    this.hideUploadLink();
    this.hideUploadActions();
    showProgressWindowState(this, message);
  }

  showUploadLink(url) {
    const linkContainer = this.progressLinkContainerElement();
    const link = this.progressLinkElement();
    if (!linkContainer || !link) return;

    const safeUrl = this.safeInternalHref(url);
    if (!safeUrl) return;

    link.href = safeUrl;
    link.textContent = this.viewExportLinkLabelValue;
    linkContainer.classList.remove("hidden");
  }

  hideUploadLink() {
    const linkContainer = this.progressLinkContainerElement();
    const link = this.progressLinkElement();
    if (!linkContainer || !link) return;

    linkContainer.classList.add("hidden");
    const defaultHref = this.safeInternalHref(
      link.getAttribute("data-default-href"),
    );
    if (defaultHref) {
      link.href = defaultHref;
    } else {
      link.removeAttribute("href");
    }
    link.textContent = "";
  }

  showUploadActions() {
    const uploadActions = this.uploadActionsElement();
    if (!uploadActions) return;

    uploadActions.classList.remove("hidden");
  }

  hideUploadActions() {
    const uploadActions = this.uploadActionsElement();
    if (!uploadActions) return;

    uploadActions.classList.add("hidden");
  }

  // Progress cards are cloned from a template and mounted under document.body,
  // which puts them outside this controller's target scope.
  progressCardElement() {
    if (!this._exportId) return null;

    return document.getElementById(`linelist-export-card-${this._exportId}`);
  }

  progressLinkContainerElement() {
    return this.progressCardElement()?.querySelector(
      "[data-linelist-export-progress-link-container]",
    );
  }

  progressLinkElement() {
    return this.progressCardElement()?.querySelector(
      "[data-linelist-export-progress-link]",
    );
  }

  uploadActionsElement() {
    return this.progressCardElement()?.querySelector(
      "[data-linelist-export-upload-actions]",
    );
  }

  scheduleProgressWindowDismiss() {
    scheduleProgressWindowDismissState(this);
  }

  clearProgressWindowDismissTimeout() {
    clearProgressWindowDismissTimeoutState(this);
  }

  safeInternalHref(rawUrl) {
    if (!rawUrl) return null;

    try {
      const parsed = new URL(rawUrl, window.location.origin);
      if (!["http:", "https:"].includes(parsed.protocol)) return null;
      if (parsed.origin !== window.location.origin) return null;

      return `${parsed.pathname}${parsed.search}${parsed.hash}`;
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
