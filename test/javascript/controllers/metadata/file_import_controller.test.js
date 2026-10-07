import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Controller } from "@hotwired/stimulus";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";
import FileImportController from "../../../../app/javascript/controllers/metadata/file_import_controller.js";

// The controller imports `xlsx` (CDN-only in production). Replace it with
// controllable mocks so a test can decide which header row a file yields.
const { mockRead, mockSheetToJson } = vi.hoisted(() => ({
  mockRead: vi.fn(),
  mockSheetToJson: vi.fn(),
}));

vi.mock("xlsx", () => ({
  read: mockRead,
  utils: { sheet_to_json: mockSheetToJson },
}));

const IDENTIFIER = "metadata--file-import";
const SORTABLE_IDENTIFIER = "sortable-lists--v1--two-lists-selection";
const OUTLET_ATTR =
  "data-metadata--file-import-sortable-lists--v1--two-lists-selection-outlet";
const SEND_METADATA_ACTION =
  "metadata--file-import:sendMetadata->sortable-lists--v1--two-lists-selection#updateMetadataListing";

// Minimal stand-ins for the controllers metadata--file-import talks to via
// outlets/dispatch, so tests can assert the cross-controller calls happen.
class SortableListsStub extends Controller {
  idempotentConnect() {}
  updateMetadataListing() {}
}

class RefreshStub extends Controller {
  ignoreNextRefresh() {}
}

// jsdom's FileReader timing is incidental to this controller; a fake makes the
// async onload deterministic and can also complete reads out of order.
class FakeFileReader {
  static instances = [];
  static autoComplete = true;

  constructor() {
    FakeFileReader.instances.push(this);
  }

  readAsArrayBuffer(file) {
    this.file = file;
    if (FakeFileReader.autoComplete) {
      queueMicrotask(() => this.complete());
    }
  }

  complete() {
    this.result = this.file.name;
    this.onload?.();
  }
}

const fileObj = (name = "metadata.csv") => ({ name });

// Drive XLSX.read/sheet_to_json so a processed file yields `headers`.
function stubWorkbook(headers) {
  mockRead.mockReturnValue({ SheetNames: ["Sheet1"], Sheets: { Sheet1: {} } });
  mockSheetToJson.mockReturnValue([headers]);
}

function setFiles(input, files) {
  Object.defineProperty(input, "files", {
    configurable: true,
    writable: true,
    value: files,
  });
}

function buildHTML({ fileInput, metadataColumns, outlet, refresh }) {
  const controllers = [IDENTIFIER];
  if (outlet) controllers.push(SORTABLE_IDENTIFIER);
  if (refresh) controllers.push("refresh");

  const hostAttrs = [`data-controller="${controllers.join(" ")}"`, 'id="host"'];
  if (outlet) {
    hostAttrs.push(`${OUTLET_ATTR}="#host"`);
    hostAttrs.push(`data-action="${SEND_METADATA_ACTION}"`);
  }
  if (refresh)
    hostAttrs.push('data-metadata--file-import-refresh-outlet="#host"');

  const fileInputHTML = fileInput
    ? `<input type="file"
        data-metadata--file-import-target="fileInput"
        data-action="change->metadata--file-import#readFile" />`
    : "";
  const metadataColumnsHTML = metadataColumns
    ? `<div data-metadata--file-import-target="metadataColumns" class="hidden" aria-hidden="true"></div>`
    : "";

  return `
    <div ${hostAttrs.join(" ")}>
      ${fileInputHTML}
      <select
        data-metadata--file-import-target="sampleIdColumn"
        data-action="change->metadata--file-import#changeSampleIDInput"
        disabled
      >
        <option value="">Select…</option>
      </select>
      ${metadataColumnsHTML}
      <div data-metadata--file-import-target="error" class="hidden" aria-hidden="true"></div>
      <button type="submit" data-metadata--file-import-target="submitButton" disabled>Submit</button>
    </div>
  `;
}

describe("MetadataFileImportController", () => {
  let application;

  beforeEach(() => {
    FakeFileReader.instances = [];
    FakeFileReader.autoComplete = true;
    vi.stubGlobal("FileReader", FakeFileReader);
  });

  afterEach(async () => {
    await stopApplication(application);
    application = undefined;
  });

  async function mount({
    preselect = null,
    fileInput = true,
    metadataColumns = true,
    outlet = true,
    refresh = true,
  } = {}) {
    document.body.innerHTML = buildHTML({
      fileInput,
      metadataColumns,
      outlet,
      refresh,
    });

    const fileInputEl = document.querySelector(
      "[data-metadata--file-import-target='fileInput']",
    );
    if (preselect) setFiles(fileInputEl, preselect);

    application = startApplication();
    application.register(IDENTIFIER, FileImportController);
    if (outlet) application.register(SORTABLE_IDENTIFIER, SortableListsStub);
    if (refresh) application.register("refresh", RefreshStub);
    await Promise.resolve();

    return {
      host: document.querySelector("#host"),
      fileInput: fileInputEl,
      select: document.querySelector(
        "[data-metadata--file-import-target='sampleIdColumn']",
      ),
      metadataColumns: document.querySelector(
        "[data-metadata--file-import-target='metadataColumns']",
      ),
      error: document.querySelector(
        "[data-metadata--file-import-target='error']",
      ),
      submitButton: document.querySelector(
        "[data-metadata--file-import-target='submitButton']",
      ),
    };
  }

  it("processes a file already selected before it connects", async () => {
    stubWorkbook(["sample_id", "country", "age"]);

    const { select, submitButton, metadataColumns } = await mount({
      preselect: [fileObj()],
    });
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    // The missed change event is recovered: headers populate the select, the
    // default sample column is auto-selected, and the dialog is enabled.
    expect(Array.from(select.options).map((option) => option.value)).toEqual([
      "",
      "sample_id",
      "country",
      "age",
    ]);
    expect(select.value).toBe("sample_id");
    expect(select.disabled).toBe(false);
    expect(submitButton.disabled).toBe(false);
    expect(metadataColumns.classList.contains("hidden")).toBe(false);
  });

  it("processes a file selected after it connects and drives the sortable lists", async () => {
    stubWorkbook(["sample_id", "country", "age"]);
    const idempotentConnect = vi.spyOn(
      SortableListsStub.prototype,
      "idempotentConnect",
    );
    const updateMetadataListing = vi.spyOn(
      SortableListsStub.prototype,
      "updateMetadataListing",
    );

    const { fileInput, select, submitButton } = await mount();
    setFiles(fileInput, [fileObj()]);
    fileInput.dispatchEvent(new Event("change", { bubbles: true }));
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    expect(select.value).toBe("sample_id");
    expect(submitButton.disabled).toBe(false);
    expect(idempotentConnect).toHaveBeenCalled();
    expect(updateMetadataListing).toHaveBeenCalled();
  });

  it("replaces the previous options when a different file is selected", async () => {
    stubWorkbook(["sample_id", "country"]);

    const { fileInput, select } = await mount({
      preselect: [fileObj("a.csv")],
    });
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalledTimes(1));

    stubWorkbook(["sample_name", "age", "city"]);
    setFiles(fileInput, [fileObj("b.csv")]);
    fileInput.dispatchEvent(new Event("change", { bubbles: true }));
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalledTimes(2));

    // Stale options from the first file are cleared, not appended to.
    expect(Array.from(select.options).map((option) => option.value)).toEqual([
      "",
      "sample_name",
      "age",
      "city",
    ]);
    expect(select.value).toBe("sample_name");
  });

  it("ignores a file read that finishes after a newer selection", async () => {
    FakeFileReader.autoComplete = false;
    mockRead.mockImplementation((result) => ({
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: { headers: result } },
    }));
    mockSheetToJson.mockImplementation((worksheet) => [[worksheet.headers]]);

    const { fileInput, select } = await mount();
    setFiles(fileInput, [fileObj("first.csv")]);
    fileInput.dispatchEvent(new Event("change", { bubbles: true }));
    setFiles(fileInput, [fileObj("second.csv")]);
    fileInput.dispatchEvent(new Event("change", { bubbles: true }));

    expect(FakeFileReader.instances).toHaveLength(2);
    FakeFileReader.instances[1].complete();
    FakeFileReader.instances[0].complete();

    expect(Array.from(select.options).map((option) => option.value)).toEqual([
      "",
      "second.csv",
    ]);
  });

  it("populates the select but keeps submit disabled when no sample column is recognized", async () => {
    stubWorkbook(["country", "age"]);

    const { select, submitButton, metadataColumns } = await mount({
      preselect: [fileObj()],
    });
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    expect(select.disabled).toBe(false);
    expect(select.options).toHaveLength(3);
    expect(select.value).toBe("");
    expect(submitButton.disabled).toBe(true);
    expect(metadataColumns.classList.contains("hidden")).toBe(true);
  });

  it("shows the error state when the file has no metadata columns", async () => {
    stubWorkbook(["sample_id"]);

    const { submitButton, error, metadataColumns } = await mount({
      preselect: [fileObj()],
    });
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    expect(error.classList.contains("hidden")).toBe(false);
    expect(submitButton.disabled).toBe(true);
    expect(metadataColumns.classList.contains("hidden")).toBe(true);
  });

  it("resets the dialog when the file selection is cleared", async () => {
    const { fileInput, submitButton, metadataColumns } = await mount();
    setFiles(fileInput, []);
    fileInput.dispatchEvent(new Event("change", { bubbles: true }));
    await Promise.resolve();

    expect(mockSheetToJson).not.toHaveBeenCalled();
    expect(submitButton.disabled).toBe(true);
    expect(metadataColumns.classList.contains("hidden")).toBe(true);
  });

  it("toggles the dialog as the sample id column selection changes", async () => {
    const idempotentConnect = vi.spyOn(
      SortableListsStub.prototype,
      "idempotentConnect",
    );
    const { select, submitButton } = await mount();
    select.append(new Option("sample_id", "sample_id"));

    select.value = "sample_id";
    select.dispatchEvent(new Event("change", { bubbles: true }));
    expect(idempotentConnect).toHaveBeenCalled();

    select.value = "";
    select.dispatchEvent(new Event("change", { bubbles: true }));
    expect(submitButton.disabled).toBe(true);
  });

  it("notifies refresh controllers on submit", async () => {
    const ignoreNextRefresh = vi.spyOn(
      RefreshStub.prototype,
      "ignoreNextRefresh",
    );
    const { host } = await mount();

    application
      .getControllerForElementAndIdentifier(host, IDENTIFIER)
      .handleSubmit();

    expect(ignoreNextRefresh).toHaveBeenCalled();
  });

  it("only toggles the submit button when the metadata-columns target and outlet are absent", async () => {
    const { select, submitButton } = await mount({
      metadataColumns: false,
      outlet: false,
      refresh: false,
    });
    select.append(new Option("sample_id", "sample_id"));

    select.value = "sample_id";
    select.dispatchEvent(new Event("change", { bubbles: true }));
    expect(submitButton.disabled).toBe(false);

    select.value = "";
    select.dispatchEvent(new Event("change", { bubbles: true }));
    expect(submitButton.disabled).toBe(true);
  });

  it("does nothing on connect when there is no file input target", async () => {
    const { submitButton } = await mount({ fileInput: false });

    expect(mockSheetToJson).not.toHaveBeenCalled();
    expect(submitButton.disabled).toBe(true);
  });
});
