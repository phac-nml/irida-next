import { Controller } from "@hotwired/stimulus";
import { downloadLinelist } from "controllers/linelist_export/download";
import {
  buildExportFilename,
  buildSaveRequest,
  buildWorkerMessage,
  readLinelistExportFormState,
  selectedSampleIds as readSelectedSampleIds,
  selectionStorageKey as buildSelectionStorageKey,
} from "controllers/linelist_export/form_state";
import { LinelistProgressWindow } from "controllers/linelist_export/progress_window";
import {
  buildDataExportShowUrl,
  queueLinelistSave,
} from "controllers/linelist_export/save_client";
import {
  LinelistExportWorkerClient,
  resolveWorkerSourceUrl,
} from "controllers/linelist_export/worker_client";

export default class extends Controller {
  static targets = [
    "sampleStatus",
    "progressTemplate",
    "saveDetailsFieldset",
    "progressLink",
    "progressLinkRow",
  ];

  static values = {
    workerUrl: String,
    graphqlUrl: String,
    saveToServerUrl: String,
    sampleGraphqlIdPrefix: String,
    minimumVisibleDurationMs: {
      type: Number,
      default: 3500,
    },
    saveResultVisibleDurationMs: {
      type: Number,
      default: 6000,
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
    queueingSaveMessage: {
      type: String,
      default: "Queueing save to Data Exports...",
    },
    viewDataExportMessage: {
      type: String,
      default: "View in Data Exports",
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
      default: "Saving to server failed: %{message}",
    },
  };

  connect() {
    this.workerClient = null;
    this.progressWindow = new LinelistProgressWindow({
      getTemplate: () =>
        this.hasProgressTemplateTarget ? this.progressTemplateTarget : null,
    });
    this._pendingSaveRequest = null;
    this.updateSelectedCount();
    this.updateSaveToServerFields();
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
    const formState = readLinelistExportFormState(this.element);
    const selectedCount = sampleIds.length;

    if (!selectedCount) {
      this.updateProgress(this.t(this.noSelectionErrorMessageValue), 100, true);
      return;
    }

    const filename = buildExportFilename(formState.format);
    const totalCount = selectedCount;

    this.progressWindow.beginSession();
    this._pendingSaveRequest = buildSaveRequest({ sampleIds, formState });

    if (this.hasSampleStatusTarget) {
      this.sampleStatusTarget.textContent = this.t(
        this.preparingExportMessageValue,
        { count: totalCount },
      );
    }

    try {
      if (formState.saveToServer) {
        const queueingMessage = this.t(this.queueingSaveMessageValue);
        this.showProgressWindow(queueingMessage);
        this.updateProgress(queueingMessage, 75);

        if (this.hasSampleStatusTarget) {
          this.sampleStatusTarget.textContent = queueingMessage;
        }

        const saveRequest = this._pendingSaveRequest;
        this._pendingSaveRequest = null;
        void this.saveToServer(saveRequest);
      } else {
        this.showProgressWindow(
          this.t(this.preparingRowsMessageValue, { count: totalCount }),
        );

        this.spawnWorker(
          buildWorkerMessage({
            sampleIds,
            formState,
            graphqlUrl: this.graphqlUrlValue,
            csrfToken: this.csrfToken(),
            sampleGraphqlIdPrefix: this.sampleGraphqlIdPrefixValue,
            filename,
            totalCount,
          }),
        );
      }
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
    if (!this.workerClient) return;

    this.workerClient.stop();
    this.workerClient = null;
  }

  spawnWorker(workerMessage) {
    this.terminateWorker();

    const workerSource = resolveWorkerSourceUrl({
      workerUrl: this.hasWorkerUrlValue ? this.workerUrlValue : "",
    });

    this.workerClient = new LinelistExportWorkerClient({
      workerSource,
      onProgress: (payload) => this.handleWorkerProgress(payload),
      onDone: (payload) => this.handleWorkerDone(payload),
      onPayloadError: (payload) => this.handleWorkerError(payload),
      onUnexpectedError: (detail) => this.handleWorkerUnexpectedError(detail),
    });

    this.workerClient.start(workerMessage);
  }

  handleWorkerProgress(payload) {
    const message = this.t(this.createdRecordsMessageValue, {
      current: payload.current,
      total: payload.total,
    });
    this.updateProgress(message, payload.percentage);
  }

  handleWorkerDone(payload) {
    downloadLinelist(payload);

    const downloadMessage = this.t(this.downloadStartedMessageValue, {
      filename: payload.filename,
    });

    this.updateProgress(downloadMessage, 100);

    if (this.hasSampleStatusTarget) {
      this.sampleStatusTarget.textContent = downloadMessage;
    }

    const saveRequest = this._pendingSaveRequest;
    this._pendingSaveRequest = null;

    if (saveRequest?.saveToServer) {
      void this.saveToServer(saveRequest);
    } else {
      this.scheduleProgressWindowDismiss();
    }

    this.terminateWorker();
  }

  handleWorkerError(payload) {
    this.updateProgress(payload.message, 100, true);
    this._pendingSaveRequest = null;
    this.terminateWorker();
  }

  handleWorkerUnexpectedError(detail) {
    const message = this.t(this.unexpectedErrorMessageValue, {
      message: detail,
    }).replace(/:\s*$/, "");

    this.updateProgress(message, 100, true);
  }

  updateProgress(message, percentage, error = false) {
    this.progressWindow.update(message, percentage, error);
  }

  showProgressWindow(message) {
    this.progressWindow.show(message);
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

  selectedDeliveryMode() {
    const selected = this.element.querySelector(
      "input[name='data_export[delivery_mode]']:checked",
    );
    return selected?.value || "immediate_download";
  }

  saveModeSelected() {
    return this.selectedDeliveryMode() === "save_to_server";
  }

  toggleSaveToServer() {
    this.updateSaveToServerFields();
  }

  selectedSampleIds() {
    return readSelectedSampleIds(this.selectionStorageKey());
  }

  selectionStorageKey() {
    return buildSelectionStorageKey();
  }

  csrfToken() {
    const meta = document.querySelector('meta[name="csrf-token"]');
    return meta?.getAttribute("content") || "";
  }

  async saveToServer(request) {
    const saveUrl = this.saveToServerUrlValue;
    if (!saveUrl) return;

    try {
      const payload = await queueLinelistSave({
        saveUrl,
        csrfToken: this.csrfToken(),
        request,
      });

      const message = this.t(this.saveQueuedMessageValue, {
        id: payload.id,
      });

      this.progressWindow.setLink(
        buildDataExportShowUrl(saveUrl, payload.id),
        this.t(this.viewDataExportMessageValue),
      );

      if (this.hasSampleStatusTarget) {
        this.sampleStatusTarget.textContent = message;
      }

      this.updateProgress(message, 100);
      this.scheduleProgressWindowDismiss(
        this.saveResultVisibleDurationMsValue,
        true,
      );
    } catch (error) {
      const message = this.t(this.saveFailedMessageValue, {
        message: error?.message || "unknown error",
      });

      this.progressWindow.clearLink();

      if (this.hasSampleStatusTarget) {
        this.sampleStatusTarget.textContent = message;
      }

      this.updateProgress(message, 100, true);
      this.scheduleProgressWindowDismiss();
    }
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

  updateSaveToServerFields() {
    if (!this.hasSaveDetailsFieldsetTarget) return;

    const enabled = this.saveModeSelected();
    this.saveDetailsFieldsetTarget.disabled = !enabled;
    this.saveDetailsFieldsetTarget.classList.toggle("hidden", !enabled);
    this.saveDetailsFieldsetTarget.setAttribute(
      "aria-disabled",
      String(!enabled),
    );
  }

  dismissProgressWindow() {
    this.progressWindow.dismiss();
  }

  scheduleProgressWindowDismiss(
    minimumVisibleDurationMs = this.minimumVisibleDurationMsValue,
    restartWindowTimer = false,
  ) {
    this.progressWindow.scheduleDismiss(
      minimumVisibleDurationMs,
      restartWindowTimer,
    );
  }

  t(template, vars = {}) {
    return Object.entries(vars).reduce(
      (str, [key, val]) => str.replaceAll(`%{${key}}`, val),
      template,
    );
  }
}
