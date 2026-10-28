import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import LinelistImportController from "../../../app/javascript/controllers/linelist_import_controller.js";

// The controller imports `xlsx` (CDN-only in production); mock it so the test
// controls the parsed worksheet and headers.
const { mockRead, mockSheetToJson } = vi.hoisted(() => ({
  mockRead: vi.fn(),
  mockSheetToJson: vi.fn(),
}));

vi.mock("xlsx", () => ({
  read: mockRead,
  utils: { sheet_to_json: mockSheetToJson },
}));

// onload is assigned after readAsArrayBuffer in the controller, so defer it.
class FakeFileReader {
  static instances = [];

  constructor() {
    this.result = null;
    this.onload = null;
    FakeFileReader.instances.push(this);
  }

  readAsArrayBuffer() {
    this.result = new ArrayBuffer(0);
  }

  load(result) {
    this.result = result;
    this.onload?.();
  }
}

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

const PROGRESS_TEMPLATE = `
	<template data-linelist-import-target="progressTemplate">
		<div>
			<p data-linelist-import-progress-message></p>
			<div data-linelist-import-progress-bar></div>
			<span data-linelist-import-progress-percent></span>
		</div>
	</template>`;

function markup() {
  return `
		<div data-controller="linelist-import"
				 data-linelist-import-graphql-url-value="/graphql"
				 data-linelist-import-group-puid-value="group-1"
				 data-linelist-import-project-puid-value="project-1">
			<select data-linelist-import-target="sampleIdColumn">
				<option value="">Select a sample column</option>
			</select>
			<button data-linelist-import-target="submitButton" type="submit"></button>
			<div data-linelist-import-target="metadataColumns"></div>
			<div data-linelist-import-target="error" class="hidden"></div>
      <div data-linelist-import-target="errorMessage"></div>
			<input name="file_import[metadata_columns][]" value="age">
			<input name="file_import[metadata_columns][]" value="empty_field">
			<input name="file_import[ignore_empty_values]" type="checkbox" checked>
			<template data-linelist-import-target="alertTemplate">
				<li>PLACEHOLDER</li>
			</template>
			<template data-linelist-import-target="dialogTemplate">
				<div><ul id="error-messages"></ul></div>
			</template>
			<template data-linelist-import-target="flashTemplate">
				<div>Import complete</div>
			</template>
			<div id="flashes"></div>
			${PROGRESS_TEMPLATE}
		</div>`;
}

describe("linelist import controller", () => {
  let application;

  async function mount() {
    document.body.innerHTML = markup();
    application = startApplication();
    application.register("linelist-import", LinelistImportController);
    await Promise.resolve();
    return application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="linelist-import"]'),
      "linelist-import",
    );
  }

  const messageText = () =>
    document.querySelector("[data-linelist-import-progress-message]")
      ?.textContent;

  beforeEach(() => {
    FakeFileReader.instances = [];
    FakeWorker.instances = [];
    vi.stubGlobal("FileReader", FakeFileReader);
    vi.stubGlobal("Worker", FakeWorker);
    document.head.innerHTML = '<meta name="csrf-token" content="csrf-token-1">';
  });

  afterEach(async () => {
    await stopApplication(application);
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
    document.head.replaceChildren();
  });

  it("returns early when no file is selected", async () => {
    const controller = await mount();
    controller._fileType = "text/csv";
    controller.readFile({ target: { files: [] } });

    expect(controller._fileType).toBe("text/csv");
  });

  it("reads the first worksheet and populates the sample id options", async () => {
    const controller = await mount();
    const file = { type: "text/csv", name: "samples.csv" };

    controller.readFile({
      target: { files: [file] },
    });
    const worker = FakeWorker.instances[0];
    worker.onmessage({
      data: { type: "headers", headers: ["sample_id", "age"] },
    });

    expect(controller._fileType).toBe("text/csv");
    expect(worker.posted).toEqual([{ type: "read_headers", file }]);
    expect(controller.headers).toEqual(["sample_id", "age"]);
    expect(controller.sampleIdColumnTarget.value).toBe("sample_id");
    expect(controller.sampleIdColumnTarget.options).toHaveLength(3);
    expect(controller.sampleIdColumnTarget.disabled).toBe(false);
  });

  it("rejects duplicate headers and disables importing", async () => {
    const controller = await mount();

    controller.readFile({
      target: { files: [{ type: "text/csv", name: "samples.csv" }] },
    });
    FakeWorker.instances[0].onmessage({
      data: { type: "headers", headers: ["sample_id", " Age ", "age"] },
    });

    expect(controller.errorMessageTarget.textContent).toBe(
      "The uploaded spreadsheet contains duplicate column headers. Please rename them before importing.",
    );
    expect(controller.errorTarget).not.toHaveClass("hidden");
    expect(controller.errorTarget).not.toHaveAttribute("aria-hidden");
    expect(controller.submitButtonTarget).toBeDisabled();
    expect(controller.submitButtonTarget).toHaveAttribute(
      "aria-disabled",
      "true",
    );
    expect(controller.sampleIdColumnTarget.options).toHaveLength(1);
  });

  it("sends selected rows and import settings to the worker", async () => {
    const controller = await mount();
    const file = { type: "text/csv", name: "samples.csv" };
    controller._file = file;
    controller._fileType = "text/csv";
    controller.sampleIdColumnTarget.append(
      new Option("sample_id", "sample_id"),
    );
    controller.sampleIdColumnTarget.value = "sample_id";
    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    expect(worker.posted).toEqual([
      {
        csrf_token: "csrf-token-1",
        mime_type: "text/csv",
        graphql_url: "/graphql",
        group_puid: "group-1",
        project_puid: "project-1",
        file,
        sample_id_column: "sample_id",
        metadata_columns: ["age", "empty_field"],
        ignore_empty_values: true,
      },
    ]);
    expect(messageText()).toBe("Starting metadata import...");
  });

  it("sends an empty CSRF token when the page has no CSRF meta tag", async () => {
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._worksheet = {};
    document.head.replaceChildren();
    const xlsx = await vi.importMock("xlsx");
    vi.spyOn(xlsx.utils, "sheet_to_json").mockReturnValue([]);

    controller.handleSubmit(new Event("submit", { cancelable: true }));

    expect(FakeWorker.instances[0].posted[0].csrf_token).toBe("");
  });

  it("adds successful completion to the flash path on the final progress event", async () => {
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._worksheet = {};
    const xlsx = await vi.importMock("xlsx");
    xlsx.utils.sheet_to_json.mockReturnValue([]);
    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    worker.onmessage({
      data: {
        type: "progress",
        current: 1,
        total: 1,
        result: { overallStatus: "successful" },
      },
    });

    expect(messageText()).toBe("Imported 1 of 1 records");
    expect(worker.terminated).toBe(false);
  });

  it("updates progress for non-final and unrecognized results", async () => {
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._worksheet = {};
    const xlsx = await vi.importMock("xlsx");
    xlsx.utils.sheet_to_json.mockReturnValue([]);
    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    worker.onmessage({
      data: {
        type: "progress",
        current: 1,
        total: 2,
        result: { overallStatus: "successful" },
      },
    });

    worker.onmessage({
      data: { type: "progress", current: 1, total: 2, result: {} },
    });

    expect(messageText()).toBe("Imported 1 of 2 records");
  });

  it("reports transient retry progress from the worker", async () => {
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._file = { type: "text/csv", name: "samples.csv" };
    controller._fileType = "text/csv";
    controller.sampleIdColumnTarget.append(
      new Option("sample_id", "sample_id"),
    );
    controller.sampleIdColumnTarget.value = "sample_id";

    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    worker.onmessage({
      data: {
        type: "retry",
        current: 100,
        total: 200,
        attempt: 1,
        maxAttempts: 3,
      },
    });

    expect(messageText()).toBe("Retrying import (attempt 1 of 3)");
  });

  it("keeps importing after the dialog controller disconnects", async () => {
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._file = { type: "text/csv", name: "samples.csv" };
    controller._fileType = "text/csv";
    controller.sampleIdColumnTarget.append(
      new Option("sample_id", "sample_id"),
    );
    controller.sampleIdColumnTarget.value = "sample_id";

    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];
    controller.disconnect();

    worker.onmessage({
      data: {
        type: "progress",
        current: 1,
        total: 2,
        result: { overallStatus: "successful" },
      },
    });

    expect(worker.terminated).toBe(false);
    expect(messageText()).toBe("Imported 1 of 2 records");
  });

  it("reports worker errors and terminates the worker", async () => {
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._worksheet = {};
    const xlsx = await vi.importMock("xlsx");
    xlsx.utils.sheet_to_json.mockReturnValue([]);
    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    worker.onmessage({ data: { type: "error", message: "Import failed" } });

    expect(messageText()).toBe(
      "Unexpected error while importing metadata: Import failed",
    );
    expect(worker.terminated).toBe(true);
  });

  it("renders import errors from an unsuccessful progress result", async () => {
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._worksheet = {};
    const xlsx = await vi.importMock("xlsx");
    xlsx.utils.sheet_to_json.mockReturnValue([]);
    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    worker.onmessage({
      data: {
        type: "progress",
        current: 1,
        total: 1,
        result: {
          overallStatus: "successful with errors",
          errors: [{ message: "Invalid value" }],
        },
      },
    });

    expect(document.querySelector("#error-messages li").textContent).toBe(
      "Invalid value",
    );
  });

  it("handles non-final errors without opening the dialog", async () => {
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._worksheet = {};
    const xlsx = await vi.importMock("xlsx");
    xlsx.utils.sheet_to_json.mockReturnValue([]);
    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    worker.onmessage({
      data: {
        type: "progress",
        current: 1,
        total: 2,
        result: { overallStatus: "unsuccessful", errors: [] },
      },
    });

    expect(messageText()).toBe("Imported 1 of 2 records");
  });

  it("ignores errors when no dialog or error list is available", async () => {
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._worksheet = {};
    const xlsx = await vi.importMock("xlsx");
    xlsx.utils.sheet_to_json.mockReturnValue([]);
    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    controller._operationId = null;
    worker.onmessage({
      data: {
        type: "progress",
        current: 1,
        total: 1,
        result: { overallStatus: "unsuccessful", errors: [] },
      },
    });

    controller._operationId = "without-list";
    controller.dialogTemplateTarget.innerHTML = "<div></div>";
    worker.onmessage({
      data: {
        type: "progress",
        current: 1,
        total: 1,
        result: { overallStatus: "unsuccessful", errors: [{ message: "Bad" }] },
      },
    });

    expect(
      document.querySelector('[id^="linelist-import-dialog-"]'),
    ).not.toBeNull();
  });

  it("handles empty worker messages and worker failures", async () => {
    const consoleError = vi
      .spyOn(console, "error")
      .mockImplementation(() => {});
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._worksheet = {};
    const xlsx = await vi.importMock("xlsx");
    xlsx.utils.sheet_to_json.mockReturnValue([]);
    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    worker.onmessage({});
    worker.onerror({ message: "worker crashed" });

    expect(worker.terminated).toBe(true);
    expect(consoleError).toHaveBeenCalledWith(
      "Worker failed:",
      "worker crashed",
    );
  });

  it("does not submit when workers are unavailable", async () => {
    vi.stubGlobal("Worker", undefined);
    const consoleError = vi
      .spyOn(console, "error")
      .mockImplementation(() => {});
    const controller = await mount();

    expect(() =>
      controller.handleSubmit(new Event("submit", { cancelable: true })),
    ).not.toThrow();
    expect(consoleError).toHaveBeenCalledWith(
      "Web Workers are not supported in this browser.",
    );
  });

  it("reports completion and terminates the worker", async () => {
    const controller = await mount();
    controller.headers = ["sample_id"];
    controller._worksheet = {};
    const xlsx = await vi.importMock("xlsx");
    xlsx.utils.sheet_to_json.mockReturnValue([]);
    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    worker.onmessage({ data: { type: "done" } });

    expect(messageText()).toBe("The metadata import is complete");
    expect(worker.terminated).toBe(true);
  });
});
