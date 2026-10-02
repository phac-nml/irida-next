import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Controller } from "@hotwired/stimulus";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import SpreadsheetImportController from "../../../app/javascript/controllers/spreadsheet_import_controller.js";

let workbook;
let spreadsheetHeaders;

vi.mock("xlsx", () => ({
  read: vi.fn(() => workbook),
  utils: {
    sheet_to_json: vi.fn(() => [spreadsheetHeaders]),
  },
}));

class FileReaderStub {
  static instances = [];

  constructor() {
    this.onload = null;
    this.result = null;
    FileReaderStub.instances.push(this);
  }

  readAsArrayBuffer(file) {
    this.file = file;
  }

  load(result) {
    this.result = result;
    this.onload();
  }
}

class RefreshOutletStub extends Controller {
  ignoreNextRefresh() {
    this.ignoredRefreshes = (this.ignoredRefreshes || 0) + 1;
  }
}

function markup({ project = false, refresh = false } = {}) {
  return `
    ${refresh ? '<div id="refresh" data-controller="refresh"></div>' : ""}
    <div
      id="spreadsheet-import"
      data-controller="spreadsheet-import"
      data-spreadsheet-import-select-sample-value="Select sample name"
      data-spreadsheet-import-select-description-value="Select description"
      data-spreadsheet-import-select-project-value="Select project"
      ${refresh ? 'data-spreadsheet-import-refresh-outlet="#refresh"' : ""}
    >
      ${project ? '<input id="spreadsheet_import_static_project_id_hidden" value="">' : ""}
      <select id="spreadsheet_import_sample_name_column" data-spreadsheet-import-target="sampleNameColumn">
        <option value="">Select sample name</option>
      </select>
      ${project ? '<select id="spreadsheet_import_project_puid_column" data-spreadsheet-import-target="projectPUIDColumn"><option value="">Select project</option></select>' : ""}
      <select id="spreadsheet_import_sample_description_column" data-spreadsheet-import-target="sampleDescriptionColumn">
        <option value="">Select description</option>
      </select>
      <button data-spreadsheet-import-target="submitButton" disabled></button>
      <div data-spreadsheet-import-target="metadata" class="hidden"></div>
    </div>
  `;
}

describe("spreadsheet import controller", () => {
  let application;

  async function mount(options) {
    document.body.innerHTML = markup(options);
    application = startApplication();
    application.register("spreadsheet-import", SpreadsheetImportController);
    application.register("refresh", RefreshOutletStub);
    await Promise.resolve();
    await new Promise((resolve) => requestAnimationFrame(resolve));
    return application.getControllerForElementAndIdentifier(
      document.getElementById("spreadsheet-import"),
      "spreadsheet-import",
    );
  }

  async function loadHeaders(controller, headers) {
    workbook = { SheetNames: ["Sheet1"], Sheets: { Sheet1: {} } };
    spreadsheetHeaders = headers;
    controller.readFile({ target: { files: [{}] } });
    FileReaderStub.instances.at(-1).load("contents");
  }

  beforeEach(() => {
    FileReaderStub.instances = [];
    workbook = undefined;
    spreadsheetHeaders = undefined;
    vi.stubGlobal("FileReader", FileReaderStub);
  });

  afterEach(async () => {
    await stopApplication(application);
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
    document.body.innerHTML = "";
  });

  it("starts with a disabled form for a non-project import", async () => {
    const controller = await mount();

    expect(controller.sampleNameColumnTarget.disabled).toBe(false);
    expect(controller.sampleDescriptionColumnTarget.disabled).toBe(false);
    expect(controller.submitButtonTarget.disabled).toBe(true);
  });

  it("reads and sorts headers, selects defaults, and emits metadata", async () => {
    const controller = await mount();
    const metadataEvents = [];
    controller.element.addEventListener(
      "spreadsheet-import:sendMetadata",
      (event) => metadataEvents.push(event.detail),
    );
    workbook = {
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: { worksheet: true } },
    };
    spreadsheetHeaders = ["zebra", "SAMPLE ID", "Description", "alpha"];
    const file = { type: "text/csv" };

    controller.readFile({ target: { files: [file] } });
    const reader = FileReaderStub.instances[0];
    reader.load("contents");

    expect(reader.file).toBe(file);
    expect(controller.sampleNameColumnTarget.value).toBe("SAMPLE ID");
    expect(controller.sampleDescriptionColumnTarget.value).toBe("Description");
    expect(controller.submitButtonTarget.disabled).toBe(false);
    expect(controller.metadataTarget.classList.contains("hidden")).toBe(false);
    expect(metadataEvents.at(-1)).toEqual({
      content: { metadata: ["alpha", "zebra"] },
    });
    expect(
      Array.from(controller.sampleNameColumnTarget.options).map(
        (option) => option.value,
      ),
    ).toEqual(["", "SAMPLE ID", "alpha", "zebra"]);
  });

  it("supports project imports with a selected project column", async () => {
    const controller = await mount({ project: true });
    workbook = {
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: {} },
    };
    spreadsheetHeaders = ["sample", "project_puid", "description", "metadata"];

    controller.readFile({ target: { files: [{}] } });
    FileReaderStub.instances[0].load("contents");

    expect(controller.sampleNameColumnTarget.value).toBe("sample");
    expect(controller.projectPUIDColumnTarget.value).toBe("project_puid");
    expect(controller.sampleDescriptionColumnTarget.value).toBe("description");
    expect(controller.submitButtonTarget.disabled).toBe(false);
    expect(controller.metadataTarget.classList.contains("hidden")).toBe(false);
  });

  it("keeps submission disabled when no sample or description headers exist", async () => {
    const controller = await mount();
    await loadHeaders(controller, ["age", "zebra"]);

    expect(controller.sampleNameColumnTarget.value).toBe("");
    expect(controller.sampleDescriptionColumnTarget.value).toBe("");
    expect(controller.submitButtonTarget.disabled).toBe(true);
  });

  it("uses the static project selection when no project column is selected", async () => {
    const controller = await mount({ project: true });
    controller.staticProjectInput.value = "project-1";
    await loadHeaders(controller, ["sample_name", "description"]);
    controller.changeInputValue({
      target: {
        id: controller.sampleNameColumnTarget.id,
        value: "sample_name",
      },
    });

    expect(controller.submitButtonTarget.disabled).toBe(false);
  });

  it("updates selections for each input and ignores unrelated inputs", async () => {
    const controller = await mount({ project: true });
    await loadHeaders(controller, [
      "sample",
      "project_puid",
      "description",
      "age",
    ]);

    for (const target of [
      controller.sampleNameColumnTarget,
      controller.sampleDescriptionColumnTarget,
      controller.projectPUIDColumnTarget,
    ]) {
      controller.changeInputValue({ target: { id: target.id, value: "age" } });
    }
    controller.changeInputValue({ target: { id: "unrelated", value: "age" } });

    expect(controller.sampleNameColumnTarget.value).toBe("age");
    expect(controller.sampleDescriptionColumnTarget.value).toBe("age");
    expect(controller.projectPUIDColumnTarget.value).toBe("age");
  });

  it("clears all options and returns when no file is selected", async () => {
    const controller = await mount({ project: true });
    controller.sampleNameColumnTarget.append(new Option("Old", "Old"));
    controller.projectPUIDColumnTarget.append(new Option("Old", "Old"));
    controller.sampleDescriptionColumnTarget.append(new Option("Old", "Old"));
    controller.submitButtonTarget.disabled = false;

    controller.readFile({ target: { files: [] } });

    expect(controller.sampleNameColumnTarget.options).toHaveLength(1);
    expect(controller.projectPUIDColumnTarget.options).toHaveLength(1);
    expect(controller.sampleDescriptionColumnTarget.options).toHaveLength(1);
    expect(controller.submitButtonTarget.disabled).toBe(true);
    expect(FileReaderStub.instances).toHaveLength(0);
  });

  it("hides metadata and disables submit when every header is selected", async () => {
    const controller = await mount();
    await loadHeaders(controller, ["sample", "description"]);
    controller.changeInputValue({
      target: { id: controller.sampleNameColumnTarget.id, value: "sample" },
    });
    controller.changeInputValue({
      target: {
        id: controller.sampleDescriptionColumnTarget.id,
        value: "description",
      },
    });

    expect(controller.metadataTarget.classList.contains("hidden")).toBe(true);
    expect(controller.submitButtonTarget.disabled).toBe(false);
  });

  it("notifies refresh outlets on submit", async () => {
    const controller = await mount({ refresh: true });
    const refresh = application.getControllerForElementAndIdentifier(
      document.getElementById("refresh"),
      "refresh",
    );

    controller.handleSubmit();

    expect(refresh.ignoredRefreshes).toBe(1);
  });
});
