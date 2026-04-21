export class LinelistExportWorkerClient {
  constructor({
    resolveWorkerSource,
    onProgress,
    onDone,
    onError,
    formatUnexpectedError = (detail) => detail,
  }) {
    this.resolveWorkerSource = resolveWorkerSource;
    this.onProgress = onProgress;
    this.onDone = onDone;
    this.onError = onError;
    this.formatUnexpectedError = formatUnexpectedError;
    this.worker = null;
  }

  start(payload) {
    this.stop();

    const workerSource = this.resolveWorkerSource();
    const worker = this.buildWorker(workerSource);
    worker.onmessage = (event) => {
      void this.handleWorkerMessage(event);
    };
    worker.onerror = (event) => {
      const detail = event?.message || event?.error?.message || "";
      this.onError(this.formatUnexpectedError(detail));
    };
    this.worker = worker;
    worker.postMessage(payload);
  }

  stop() {
    if (this.worker) {
      this.worker.terminate();
      this.worker = null;
    }
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
      this.onProgress(payload);
      return;
    }

    if (payload.type === "done") {
      await this.onDone(payload);
      return;
    }

    if (payload.type === "error") {
      this.onError(payload.message);
    }
  }
}

export function resolveLinelistExportWorkerSource(
  { hasWorkerUrlValue, workerUrlValue },
  doc = document,
  loc = location,
) {
  if (hasWorkerUrlValue && workerUrlValue) {
    return workerUrlValue;
  }

  const resolvedFromImportMap = workerSourceFromImportMap(doc);
  if (resolvedFromImportMap) {
    return new URL(resolvedFromImportMap, loc.origin).href;
  }

  return new URL("../../workers/linelist_export_worker.js", import.meta.url)
    .href;
}

function workerSourceFromImportMap(doc) {
  const importMapScript = doc.querySelector("script[type='importmap']");
  if (!importMapScript?.textContent) return null;

  try {
    const importMap = JSON.parse(importMapScript.textContent);
    return importMap?.imports?.["workers/linelist_export_worker"] || null;
  } catch {
    return null;
  }
}
