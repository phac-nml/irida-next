function buildWorker(workerSource) {
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

function workerSourceFromImportMap() {
  const importMapScript = document.querySelector("script[type='importmap']");
  if (!importMapScript?.textContent) return null;

  try {
    const importMap = JSON.parse(importMapScript.textContent);
    return importMap?.imports?.["workers/linelist_export_worker"] || null;
  } catch {
    return null;
  }
}

export function resolveWorkerSourceUrl({ workerUrl }) {
  if (workerUrl) return workerUrl;

  const resolvedFromImportMap = workerSourceFromImportMap();
  if (resolvedFromImportMap) {
    return new URL(resolvedFromImportMap, location.origin).href;
  }

  return new URL("../../workers/linelist_export_worker.js", import.meta.url)
    .href;
}

export class LinelistExportWorkerClient {
  constructor({
    workerSource,
    onProgress,
    onDone,
    onPayloadError,
    onUnexpectedError,
  }) {
    this.workerSource = workerSource;
    this.onProgress = onProgress;
    this.onDone = onDone;
    this.onPayloadError = onPayloadError;
    this.onUnexpectedError = onUnexpectedError;
    this.worker = null;
  }

  start(message) {
    this.stop();

    const worker = buildWorker(this.workerSource);
    worker.onmessage = (event) => this.handleMessage(event.data || {});
    worker.onerror = (event) => {
      const detail = event?.message || event?.error?.message || "";
      this.onUnexpectedError?.(detail);
      this.stop();
    };

    this.worker = worker;
    this.worker.postMessage(message);
  }

  stop() {
    if (!this.worker) return;

    this.worker.terminate();
    this.worker = null;
  }

  handleMessage(payload) {
    if (payload.type === "progress") {
      this.onProgress?.(payload);
      return;
    }

    if (payload.type === "done") {
      this.onDone?.(payload);
      this.stop();
      return;
    }

    if (payload.type === "error") {
      this.onPayloadError?.(payload);
      this.stop();
    }
  }
}
