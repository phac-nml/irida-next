import { afterEach, describe, expect, it } from "vitest";
import { resolveLinelistImportWorkerSource } from "../../../../app/javascript/controllers/linelist_import/worker_source.js";

describe("resolveLinelistImportWorkerSource", () => {
  afterEach(() => {
    document.head.replaceChildren();
  });

  it("prefers an explicit worker URL value", () => {
    const source = resolveLinelistImportWorkerSource({
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
      imports: { "workers/linelist_import_worker": "/assets/worker-abc.js" },
    });
    doc.head.appendChild(script);

    const source = resolveLinelistImportWorkerSource(
      { hasWorkerUrlValue: false, workerUrlValue: "" },
      doc,
      { origin: "https://app.test" },
    );

    expect(source).toBe("https://app.test/assets/worker-abc.js");
  });

  it("falls back to the bundled worker module when no import map entry exists", () => {
    const doc = document.implementation.createHTMLDocument("");
    const source = resolveLinelistImportWorkerSource(
      { hasWorkerUrlValue: false, workerUrlValue: "" },
      doc,
      { origin: "https://app.test" },
    );
    expect(source).toContain("workers/linelist_import_worker.js");
  });

  it("falls back when the import map JSON is invalid", () => {
    const doc = document.implementation.createHTMLDocument("");
    const script = doc.createElement("script");
    script.setAttribute("type", "importmap");
    script.textContent = "{ not valid json";
    doc.head.appendChild(script);

    const source = resolveLinelistImportWorkerSource(
      { hasWorkerUrlValue: false, workerUrlValue: "" },
      doc,
      { origin: "https://app.test" },
    );

    expect(source).toContain("workers/linelist_import_worker.js");
  });

  it("falls back when the import map has no matching entry", () => {
    const doc = document.implementation.createHTMLDocument("");
    const script = doc.createElement("script");
    script.setAttribute("type", "importmap");
    script.textContent = JSON.stringify({ imports: {} });
    doc.head.appendChild(script);

    const source = resolveLinelistImportWorkerSource(
      { hasWorkerUrlValue: false, workerUrlValue: "" },
      doc,
      { origin: "https://app.test" },
    );

    expect(source).toContain("workers/linelist_import_worker.js");
  });

  it("falls back when the import map script has no content", () => {
    const doc = document.implementation.createHTMLDocument("");
    const script = doc.createElement("script");
    script.setAttribute("type", "importmap");
    doc.head.appendChild(script);

    const source = resolveLinelistImportWorkerSource(
      { hasWorkerUrlValue: false, workerUrlValue: "" },
      doc,
      { origin: "https://app.test" },
    );

    expect(source).toContain("workers/linelist_import_worker.js");
  });
});
