import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = ["sampleStatus"];

  connect() {
    this.worker = null;
    this.workerSource = null;
    this.currentFileName = "linelist-export";
    this.updateSelectedCount();
  }

  disconnect() {
    this.terminateWorker();
    this.revokeWorkerSource();
  }

  submit(event) {
    event.preventDefault();
    this.startExport();
  }

  startExport() {
    const sampleIds = this.selectedSampleIds();
    const metadataFields = this.selectedMetadataFields();
    const format = this.selectedFormat();
    const count = sampleIds.length;
    const filename = `linelist-${new Date().toISOString().replace(/[:.]/g, "-")}.${format}`;
    const totalCount = count > 0 ? count : 5;

    if (this.sampleStatusTarget) {
      this.sampleStatusTarget.textContent = `Preparing linelist export for ${totalCount} samples...`;
    }

    this.showProgressWindow(`Preparing ${totalCount} samples`);
    this.currentFileName = filename;
    this.spawnWorker();

    this.worker.postMessage({
      sample_ids: sampleIds,
      metadata_fields: metadataFields,
      format,
      filename,
      total_count: totalCount,
    });
  }

  terminateWorker() {
    if (this.worker) {
      this.worker.terminate();
      this.worker = null;
    }
    this.revokeWorkerSource();
  }

  spawnWorker() {
    this.terminateWorker();

    const worker = new Worker(this.workerSourceUrl(), {
      type: "module",
    });
    worker.onmessage = (event) => this.handleWorkerMessage(event);
    worker.onerror = () =>
      this.updateProgress(
        "Unexpected error while generating export.",
        100,
        true,
      );
    this.worker = worker;
  }

  handleWorkerMessage(event) {
    const payload = event.data || {};

    if (payload.type === "progress") {
      this.updateProgress(payload.message, payload.percentage);
      return;
    }

    if (payload.type === "done") {
      this.updateProgress(`Download ready: ${payload.filename}`, 100);
      this.download(payload.filename, payload.content);
      this.terminateWorker();
      return;
    }

    if (payload.type === "error") {
      this.updateProgress(payload.message, 100, true);
      this.terminateWorker();
    }
  }

  updateProgress(message, percentage, error = false) {
    const percent = Math.min(Math.max(percentage, 0), 100);
    const container = this.ensureProgressWindow();
    if (!container) return;

    container.innerHTML = this.renderProgressWindowHtml(
      message,
      percent,
      error,
    );
  }

  download(filename, csvContent) {
    const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
    const url = URL.createObjectURL(blob);
    const anchor = document.createElement("a");
    anchor.href = url;
    anchor.download = filename;
    anchor.click();
    URL.revokeObjectURL(url);
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

  selectedSampleIds() {
    const storageKey = this.selectionStorageKey();
    const value = sessionStorage.getItem(storageKey);

    if (!value) {
      return [];
    }

    try {
      const parsed = JSON.parse(value);
      return Array.isArray(parsed) ? parsed : [];
    } catch (_error) {
      return [];
    }
  }

  selectionStorageKey() {
    return `${location.protocol}//${location.host}${location.pathname}`;
  }

  updateSelectedCount() {
    const selected = this.selectedSampleIds().length;
    if (this.hasSampleStatusTarget) {
      this.sampleStatusTarget.textContent = `Selected samples: ${selected}`;
    }
  }

  ensureProgressWindow() {
    let window = document.getElementById("linelist-export-progress-window");
    if (!window) {
      window = document.createElement("div");
      window.id = "linelist-export-progress-window";
      window.className = "fixed bottom-5 right-5 z-50 w-80 space-y-2";
      document.body.appendChild(window);
    }
    return window;
  }

  showProgressWindow(message) {
    this.updateProgress(message, 0);
  }

  renderProgressWindowHtml(message, percentage, error = false) {
    const barColor = error ? "bg-red-600" : "bg-primary-600";
    return `
      <div class="rounded-lg border border-slate-200 bg-white p-4 shadow dark:border-slate-700 dark:bg-slate-800">
        <p class="mb-2 text-sm text-slate-900 dark:text-slate-100">${message}</p>
        <div class="h-2 w-full overflow-hidden rounded bg-slate-200 dark:bg-slate-700">
          <div class="${barColor} h-2 rounded" style="width:${percentage}%"></div>
        </div>
        <p class="mt-2 text-xs text-slate-700 dark:text-slate-300">${Math.round(percentage)}%</p>
      </div>
    `;
  }

  workerSourceUrl() {
    this.revokeWorkerSource();

    const source = `
      self.onmessage = async (event) => {
        const { sample_ids: sampleIds, metadata_fields: metadataFields, total_count: totalCount, filename } = event.data || {};
        const fields = Array.isArray(metadataFields) ? metadataFields : [];
        const ids = Array.isArray(sampleIds) && sampleIds.length ? sampleIds : [];
        const rows = Math.max(ids.length, Number(totalCount) || 1);
        const header = ["SAMPLE PUID", "SAMPLE NAME", "PROJECT PUID", ...fields.map((field) => String(field).toUpperCase())];
        const lines = [header.join(",")];

        const escape = (value) => {
          const text = String(value ?? "");
          if (text.includes(",") || text.includes('"') || text.includes("\\n")) {
            return '"' + text.replace(/"/g, '""') + '"';
          }
          return text;
        };

        for (let i = 0; i < rows; i += 1) {
          const sampleId = ids[i] ? String(ids[i]) : "sample-" + (i + 1);
          const row = [
            escape("sample-" + sampleId),
            escape("Sample " + sampleId),
            escape("project-" + (i + 1)),
          ];

          fields.forEach((field) => {
            row.push(escape("value-" + field + "-" + sampleId));
          });

          lines.push(row.join(","));
        const percentage = ((i + 1) / rows) * 100;
          self.postMessage({
            type: "progress",
            percentage,
            message: "Created " + (i + 1) + " of " + rows + " records",
          });
        }

        await new Promise((resolve) => setTimeout(resolve, 75));
        self.postMessage({
          type: "done",
          filename,
          content: lines.join("\\n"),
        });
      };
    `;
    this.workerSource = URL.createObjectURL(
      new Blob([source], { type: "text/javascript" }),
    );
    return this.workerSource;
  }

  revokeWorkerSource() {
    if (!this.workerSource) {
      return;
    }

    URL.revokeObjectURL(this.workerSource);
    this.workerSource = null;
  }
}
