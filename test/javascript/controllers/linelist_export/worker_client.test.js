import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  LinelistExportWorkerClient,
  resolveLinelistExportWorkerSource,
} from "../../../../app/javascript/controllers/linelist_export/worker_client.js";

class FakeWorker {
  static instances = [];
  constructor(source, options) {
    this.source = source;
    this.options = options;
    this.posted = [];
    this.terminated = false;
    this.onmessage = null;
    this.onerror = null;
    FakeWorker.instances.push(this);
  }
  postMessage(payload) {
    this.posted.push(payload);
  }
  terminate() {
    this.terminated = true;
  }
}

function buildClient(overrides = {}) {
  const handlers = {
    onProgress: vi.fn(),
    onDone: vi.fn(),
    onError: vi.fn(),
    resolveWorkerSource: () => "worker-source.js",
    ...overrides,
  };
  return { client: new LinelistExportWorkerClient(handlers), handlers };
}

describe("LinelistExportWorkerClient", () => {
  beforeEach(() => {
    FakeWorker.instances = [];
    vi.stubGlobal("Worker", FakeWorker);
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("starts a module worker and posts the payload", () => {
    const { client } = buildClient();
    client.start({ format: "csv" });

    const worker = FakeWorker.instances.at(-1);
    expect(worker.source).toBe("worker-source.js");
    expect(worker.options).toEqual({ type: "module" });
    expect(worker.posted).toEqual([{ format: "csv" }]);
    expect(client.worker).toBe(worker);
  });

  it("terminates a previous worker before starting a new one", () => {
    const { client } = buildClient();
    client.start({ run: 1 });
    const first = FakeWorker.instances.at(-1);
    client.start({ run: 2 });

    expect(first.terminated).toBe(true);
    expect(FakeWorker.instances).toHaveLength(2);
  });

  it("falls back to a classic worker when the module worker throws", () => {
    let call = 0;
    class ThrowingModuleWorker extends FakeWorker {
      constructor(source, options) {
        super(source, options);
        call += 1;
        if (call === 1) throw new Error("no module workers");
      }
    }
    vi.stubGlobal("Worker", ThrowingModuleWorker);
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    const { client } = buildClient();

    client.start({ format: "csv" });

    expect(client.worker.options).toBeUndefined();
    expect(warn).toHaveBeenCalled();
  });

  it("routes progress messages to onProgress", async () => {
    const { client, handlers } = buildClient();
    client.start({});
    const worker = FakeWorker.instances.at(-1);

    await worker.onmessage({ data: { type: "progress", current: 1 } });

    expect(handlers.onProgress).toHaveBeenCalledWith({
      type: "progress",
      current: 1,
    });
  });

  it("routes done messages to onDone", async () => {
    const onDone = vi.fn().mockResolvedValue();
    const { client } = buildClient({ onDone });
    client.start({});
    const worker = FakeWorker.instances.at(-1);

    await worker.onmessage({ data: { type: "done", filename: "f.csv" } });

    expect(onDone).toHaveBeenCalledWith({ type: "done", filename: "f.csv" });
  });

  it("routes error messages to onError", async () => {
    const { client, handlers } = buildClient();
    client.start({});
    const worker = FakeWorker.instances.at(-1);

    await worker.onmessage({ data: { type: "error", message: "boom" } });

    expect(handlers.onError).toHaveBeenCalledWith("boom");
  });

  it("ignores messages with no data or unknown type", async () => {
    const { client, handlers } = buildClient();
    client.start({});
    const worker = FakeWorker.instances.at(-1);

    await worker.onmessage({});
    await worker.onmessage({ data: { type: "mystery" } });

    expect(handlers.onProgress).not.toHaveBeenCalled();
    expect(handlers.onDone).not.toHaveBeenCalled();
    expect(handlers.onError).not.toHaveBeenCalled();
  });

  it("formats worker errors from the message field", () => {
    const formatUnexpectedError = vi.fn((detail) => `formatted:${detail}`);
    const { client, handlers } = buildClient({ formatUnexpectedError });
    client.start({});
    const worker = FakeWorker.instances.at(-1);

    worker.onerror({ message: "explode" });

    expect(formatUnexpectedError).toHaveBeenCalledWith("explode");
    expect(handlers.onError).toHaveBeenCalledWith("formatted:explode");
  });

  it("formats worker errors from the nested error message", () => {
    const { client, handlers } = buildClient();
    client.start({});
    const worker = FakeWorker.instances.at(-1);

    worker.onerror({ error: { message: "nested" } });

    expect(handlers.onError).toHaveBeenCalledWith("nested");
  });

  it("uses an empty detail when the error has no message", () => {
    const { client, handlers } = buildClient();
    client.start({});
    const worker = FakeWorker.instances.at(-1);

    worker.onerror(null);

    expect(handlers.onError).toHaveBeenCalledWith("");
  });

  it("uses the identity default formatter when none is provided", () => {
    const onError = vi.fn();
    const client = new LinelistExportWorkerClient({
      resolveWorkerSource: () => "s.js",
      onProgress: vi.fn(),
      onDone: vi.fn(),
      onError,
    });
    client.start({});
    const worker = FakeWorker.instances.at(-1);

    worker.onerror({ message: "raw" });

    expect(onError).toHaveBeenCalledWith("raw");
  });

  it("stops safely when no worker is active", () => {
    const { client } = buildClient();
    expect(() => client.stop()).not.toThrow();
    expect(client.worker).toBeNull();
  });
});

describe("resolveLinelistExportWorkerSource", () => {
  afterEach(() => {
    document.head.replaceChildren();
  });

  it("prefers an explicit worker URL value", () => {
    const source = resolveLinelistExportWorkerSource({
      hasWorkerUrlValue: true,
      workerUrlValue: "https://cdn.test/worker.js",
    });
    expect(source).toBe("https://cdn.test/worker.js");
  });

  it("resolves from the import map when no worker URL value is set", () => {
    const doc = document.implementation.createHTMLDocument("");
    const script = doc.createElement("script");
    script.setAttribute("type", "importmap");
    script.textContent = JSON.stringify({
      imports: { "workers/linelist_export_worker": "/assets/worker-abc.js" },
    });
    doc.head.appendChild(script);

    const source = resolveLinelistExportWorkerSource(
      { hasWorkerUrlValue: false, workerUrlValue: "" },
      doc,
      { origin: "https://app.test" },
    );

    expect(source).toBe("https://app.test/assets/worker-abc.js");
  });

  it("falls back to the bundled worker module when no import map entry exists", () => {
    const doc = document.implementation.createHTMLDocument("");
    const source = resolveLinelistExportWorkerSource(
      { hasWorkerUrlValue: false, workerUrlValue: "" },
      doc,
      { origin: "https://app.test" },
    );
    expect(source).toContain("workers/linelist_export_worker.js");
  });

  it("falls back when the import map JSON is invalid", () => {
    const doc = document.implementation.createHTMLDocument("");
    const script = doc.createElement("script");
    script.setAttribute("type", "importmap");
    script.textContent = "{ not valid json";
    doc.head.appendChild(script);

    const source = resolveLinelistExportWorkerSource(
      { hasWorkerUrlValue: false, workerUrlValue: "" },
      doc,
      { origin: "https://app.test" },
    );

    expect(source).toContain("workers/linelist_export_worker.js");
  });

  it("falls back when the import map has no matching entry", () => {
    const doc = document.implementation.createHTMLDocument("");
    const script = doc.createElement("script");
    script.setAttribute("type", "importmap");
    script.textContent = JSON.stringify({ imports: {} });
    doc.head.appendChild(script);

    const source = resolveLinelistExportWorkerSource(
      { hasWorkerUrlValue: false, workerUrlValue: "" },
      doc,
      { origin: "https://app.test" },
    );

    expect(source).toContain("workers/linelist_export_worker.js");
  });

  it("falls back when the import map script has no content", () => {
    const doc = document.implementation.createHTMLDocument("");
    const script = doc.createElement("script");
    script.setAttribute("type", "importmap");
    doc.head.appendChild(script);

    const source = resolveLinelistExportWorkerSource(
      { hasWorkerUrlValue: false, workerUrlValue: "" },
      doc,
      { origin: "https://app.test" },
    );

    expect(source).toContain("workers/linelist_export_worker.js");
  });
});
