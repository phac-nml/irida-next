import { describe, expect, it, vi } from "vitest";
import {
  LinelistExportWorkerClient,
  resolveLinelistExportWorkerSource,
} from "controllers/linelist_export/worker_client";

describe("linelist_export/worker_client", () => {
  it("dispatches worker message types to the matching callbacks", async () => {
    const callbacks = {
      onProgress: vi.fn(),
      onDone: vi.fn(),
      onServerSaved: vi.fn(),
      onUploadError: vi.fn(),
      onError: vi.fn(),
    };
    const client = new LinelistExportWorkerClient({
      resolveWorkerSource: vi.fn(),
      ...callbacks,
    });

    await client.handleWorkerMessage({
      data: { type: "progress", current: 1 },
    });
    await client.handleWorkerMessage({
      data: { type: "done", filename: "a.csv" },
    });
    await client.handleWorkerMessage({
      data: { type: "server_saved", serverResponse: { url: "/exports/1" } },
    });
    await client.handleWorkerMessage({
      data: { type: "upload_error", message: "failed" },
    });
    await client.handleWorkerMessage({
      data: { type: "error", message: "bad" },
    });

    expect(callbacks.onProgress).toHaveBeenCalledWith({
      type: "progress",
      current: 1,
    });
    expect(callbacks.onDone).toHaveBeenCalledWith({
      type: "done",
      filename: "a.csv",
    });
    expect(callbacks.onServerSaved).toHaveBeenCalledWith({
      type: "server_saved",
      serverResponse: { url: "/exports/1" },
    });
    expect(callbacks.onUploadError).toHaveBeenCalledWith({
      type: "upload_error",
      message: "failed",
    });
    expect(callbacks.onError).toHaveBeenCalledWith("bad");
  });

  it("falls back to a classic worker when module workers are unavailable", () => {
    const moduleError = new Error("module workers unsupported");
    const classicWorker = { terminate: vi.fn(), postMessage: vi.fn() };
    const Worker = vi
      .fn(function () {
        throw moduleError;
      })
      .mockImplementationOnce(function () {
        throw moduleError;
      })
      .mockImplementationOnce(function () {
        return classicWorker;
      });
    vi.stubGlobal("Worker", Worker);
    vi.spyOn(console, "warn").mockImplementation(() => {});

    const client = new LinelistExportWorkerClient({
      resolveWorkerSource: () => "/worker.js",
      onProgress: vi.fn(),
      onDone: vi.fn(),
      onServerSaved: vi.fn(),
      onUploadError: vi.fn(),
      onError: vi.fn(),
    });

    expect(client.buildWorker("/worker.js")).toBe(classicWorker);
    expect(Worker).toHaveBeenNthCalledWith(1, "/worker.js", { type: "module" });
    expect(Worker).toHaveBeenNthCalledWith(2, "/worker.js");
  });

  it("resolves worker source from the import map before using the fallback URL", () => {
    const doc = document.implementation.createHTMLDocument();
    const script = doc.createElement("script");
    script.type = "importmap";
    script.textContent = JSON.stringify({
      imports: {
        "workers/linelist_export_worker": "/assets/linelist-worker.js",
      },
    });
    doc.head.appendChild(script);

    expect(
      resolveLinelistExportWorkerSource(
        { hasWorkerUrlValue: false, workerUrlValue: "" },
        doc,
        { origin: "https://example.test" },
      ),
    ).toBe("https://example.test/assets/linelist-worker.js");
  });
});
