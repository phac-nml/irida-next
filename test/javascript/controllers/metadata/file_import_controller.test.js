import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Controller } from "@hotwired/stimulus";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";
import FileImportController from "../../../../app/javascript/controllers/metadata/file_import_controller.js";

vi.mock("xlsx", () => ({
  read: vi.fn(),
  utils: { sheet_to_json: vi.fn() },
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

class SortableOutletStub extends Controller {
  connect() {
    this.connectCount = 0;
  }

  idempotentConnect() {
    this.connectCount += 1;
  }
}

class RefreshOutletStub extends Controller {
  ignoreNextRefresh() {
    this.ignoredRefreshes = (this.ignoredRefreshes || 0) + 1;
  }
}

function markup({
  sortableOutlet = false,
  refreshOutlet = false,
  includeMetadataColumns = true,
} = {}) {
  return `
    ${sortableOutlet ? '<div id="sortable" data-controller="sortable-lists--v1--two-lists-selection"></div>' : ""}
    ${refreshOutlet ? '<div id="refresh" data-controller="refresh"></div>' : ""}
    <div
      id="file-import"
      data-controller="metadata--file-import"
      ${sortableOutlet ? 'data-metadata--file-import-sortable-lists--v1--two-lists-selection-outlet="#sortable"' : ""}
      ${refreshOutlet ? 'data-metadata--file-import-refresh-outlet="#refresh"' : ""}
    >
      <select data-metadata--file-import-target="sampleIdColumn">
        <option value="">Select a sample column</option>
      </select>
      ${includeMetadataColumns ? '<div data-metadata--file-import-target="metadataColumns" class="hidden"></div>' : ""}
      <button data-metadata--file-import-target="submitButton" disabled></button>
      <div data-metadata--file-import-target="error" class="hidden"></div>
    </div>
  `;
}

describe("metadata file import controller", () => {
  let application;

  async function mount(options) {
    document.body.innerHTML = markup(options);
    application = startApplication();
    application.register("metadata--file-import", FileImportController);
    application.register(
      "sortable-lists--v1--two-lists-selection",
      SortableOutletStub,
    );
    application.register("refresh", RefreshOutletStub);
    await Promise.resolve();
    await new Promise((resolve) => requestAnimationFrame(resolve));
    return application.getControllerForElementAndIdentifier(
      document.getElementById("file-import"),
      "metadata--file-import",
    );
  }

  beforeEach(() => {
    FileReaderStub.instances = [];
    vi.stubGlobal("FileReader", FileReaderStub);
  });

  afterEach(async () => {
    await stopApplication(application);
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
    document.body.innerHTML = "";
  });

  it("initializes empty headers and metadata columns", async () => {
    const controller = await mount();

    expect(controller.headers).toEqual([]);
    expect(controller.columns).toEqual([]);
  });

  it("adds options, detects the sample column case-insensitively, and emits metadata", async () => {
    const controller = await mount({ sortableOutlet: true });
    const metadataEvents = [];
    controller.element.addEventListener(
      "metadata--file-import:sendMetadata",
      (event) => {
        metadataEvents.push(event.detail);
      },
    );
    controller.headers = ["Name", "SAMPLE ID", "Project ID", "Age"];

    controller.addSampleIDInputOptions();

    expect(
      Array.from(controller.sampleIdColumnTarget.options).map(
        (option) => option.value,
      ),
    ).toEqual(["", "Name", "SAMPLE ID", "Project ID", "Age"]);
    expect(controller.sampleIdColumnTarget.value).toBe("SAMPLE ID");
    expect(controller.sampleIdColumnTarget.disabled).toBe(false);
    expect(controller.submitButtonTarget.disabled).toBe(false);
    expect(controller.metadataColumnsTarget.classList.contains("hidden")).toBe(
      false,
    );
    expect(controller.columns).toEqual(["Name", "Age"]);
    expect(metadataEvents).toEqual([
      { content: { metadata: ["Name", "Age"] } },
    ]);
    expect(
      application.getControllerForElementAndIdentifier(
        document.getElementById("sortable"),
        "sortable-lists--v1--two-lists-selection",
      ).connectCount,
    ).toBe(1);
  });

  it("enables an explicitly selected sample column and resets when cleared", async () => {
    const controller = await mount();
    controller.headers = ["Sample", "Age"];
    controller.sampleIdColumnTarget.value = "Sample";

    controller.changeSampleIDInput({ target: { value: "Sample" } });

    expect(controller.submitButtonTarget.disabled).toBe(false);
    expect(controller.columns).toEqual(["Age"]);

    controller.changeSampleIDInput({ target: { value: "" } });

    expect(controller.submitButtonTarget.disabled).toBe(true);
    expect(controller.metadataColumnsTarget.classList.contains("hidden")).toBe(
      true,
    );
    expect(controller.errorTarget.getAttribute("aria-disabled")).toBe("true");
  });

  it("shows an error and disables submission when no metadata columns remain", async () => {
    const controller = await mount();
    controller.headers = ["sample_id", "Project ID", "description"];
    controller.sampleIdColumnTarget.value = "sample_id";

    controller.changeSampleIDInput({ target: { value: "sample_id" } });

    expect(controller.columns).toEqual([]);
    expect(controller.metadataColumnsTarget.classList.contains("hidden")).toBe(
      true,
    );
    expect(controller.errorTarget.classList.contains("hidden")).toBe(false);
    expect(controller.submitButtonTarget.disabled).toBe(true);
  });

  it("enables the sample selector after reading the first worksheet", async () => {
    const controller = await mount();
    const xlsx = await vi.importMock("xlsx");
    xlsx.read.mockReturnValue({
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: { worksheet: true } },
    });
    xlsx.utils.sheet_to_json.mockReturnValue([["sample", "Age"]]);
    const file = { type: "text/csv" };

    controller.readFile({ target: { files: [file] } });
    const reader = FileReaderStub.instances[0];
    reader.load("file contents");

    expect(reader.file).toBe(file);
    expect(xlsx.read).toHaveBeenCalledWith("file contents", { sheetRows: 1 });
    expect(controller.headers).toEqual(["sample", "Age"]);
    expect(controller.sampleIdColumnTarget.value).toBe("sample");
    expect(controller.sampleIdColumnTarget.disabled).toBe(false);
  });

  it("clears existing selector options and returns when no file is selected", async () => {
    const controller = await mount();
    controller.sampleIdColumnTarget.append(new Option("Old", "Old"));
    controller.errorTarget.classList.remove("hidden");
    controller.submitButtonTarget.disabled = false;

    controller.readFile({ target: { files: [] } });

    expect(controller.sampleIdColumnTarget.options).toHaveLength(1);
    expect(controller.sampleIdColumnTarget.disabled).toBe(true);
    expect(controller.errorTarget.classList.contains("hidden")).toBe(true);
    expect(FileReaderStub.instances).toHaveLength(0);
  });

  it("supports forms without the optional metadata columns target", async () => {
    const controller = await mount({ includeMetadataColumns: false });
    controller.headers = ["sample_id"];
    controller.sampleIdColumnTarget.value = "sample_id";

    controller.changeSampleIDInput({ target: { value: "sample_id" } });
    controller.readFile({ target: { files: [] } });

    expect(controller.submitButtonTarget.disabled).toBe(true);
    expect(controller.errorTarget.getAttribute("aria-disabled")).toBeNull();
  });

  it("notifies refresh outlets when submitted", async () => {
    const controller = await mount({ refreshOutlet: true });
    const refresh = application.getControllerForElementAndIdentifier(
      document.getElementById("refresh"),
      "refresh",
    );

    controller.handleSubmit();

    expect(refresh.ignoredRefreshes).toBe(1);
  });
});
