import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { FileReaderStub } from "../helpers/file_reader.js";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import LinelistImportController from "../../../app/javascript/controllers/linelist_import_controller.js";

vi.mock("xlsx", () => ({
  read: vi.fn(() => ({})),
  utils: {
    sheet_to_json: vi.fn(() => []),
  },
}));

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
    FileReaderStub.instances = [];
    FakeWorker.instances = [];
    vi.stubGlobal("FileReader", FileReaderStub);
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
    expect(FileReaderStub.instances).toHaveLength(0);
  });

  it("reads the first worksheet and populates the sample id options", async () => {
    const controller = await mount();
    const xlsx = await vi.importMock("xlsx");
    vi.spyOn(xlsx, "read").mockReturnValue({
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: { worksheet: true } },
    });
    vi.spyOn(xlsx.utils, "sheet_to_json").mockReturnValue([
      ["sample_id", "age"],
    ]);

    controller.readFile({
      target: { files: [{ type: "text/csv", name: "samples.csv" }] },
    });
    const reader = FileReaderStub.instances[0];
    reader.load("file contents");

    expect(controller._fileType).toBe("text/csv");
    expect(controller.headers).toEqual(["sample_id", "age"]);
    expect(controller.sampleIdColumnTarget.value).toBe("sample_id");
    expect(controller.sampleIdColumnTarget.options).toHaveLength(3);
    expect(controller.sampleIdColumnTarget.disabled).toBe(false);
  });

  it("sends selected rows and import settings to the worker", async () => {
    const controller = await mount();
    controller.headers = ["sample_id", "age", "empty_field"];
    controller._worksheet = { worksheet: true };
    controller._fileType = "text/csv";
    controller.sampleIdColumnTarget.append(
      new Option("sample_id", "sample_id"),
    );
    controller.sampleIdColumnTarget.value = "sample_id";
    const xlsx = await vi.importMock("xlsx");
    vi.spyOn(xlsx.utils, "sheet_to_json").mockReturnValue([
      { sample_id: "S1", age: 42, empty_field: null },
      { sample_id: "S2", age: null, empty_field: "present" },
    ]);

    controller.handleSubmit(new Event("submit", { cancelable: true }));
    const worker = FakeWorker.instances[0];

    expect(worker.posted).toEqual([
      {
        csrf_token: "csrf-token-1",
        mime_type: "text/csv",
        graphql_url: "/graphql",
        group_puid: "group-1",
        project_puid: "project-1",
        rows: [
          ["S1", { age: 42 }],
          ["S2", { empty_field: "present" }],
        ],
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
