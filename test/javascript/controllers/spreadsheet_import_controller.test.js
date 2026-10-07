import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Controller } from "@hotwired/stimulus";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import SpreadsheetImportController from "../../../app/javascript/controllers/spreadsheet_import_controller.js";

// Replace the CDN-only `xlsx` library with controllable mocks so a test can
// decide which header row a file yields.
const { mockRead, mockSheetToJson } = vi.hoisted(() => ({
  mockRead: vi.fn(),
  mockSheetToJson: vi.fn(),
}));

vi.mock("xlsx", () => ({
  read: mockRead,
  utils: { sheet_to_json: mockSheetToJson },
}));

class RefreshStub extends Controller {
  ignoreNextRefresh() {}
}

// onload is assigned after readAsArrayBuffer in the controller, so defer it.
class FakeFileReader {
  readAsArrayBuffer() {
    this.result = new ArrayBuffer(0);
    queueMicrotask(() => this.onload?.());
  }
}

const fileObj = (name = "data.csv") => ({ name });

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

const optionValues = (select) =>
  Array.from(select.options).map((option) => option.value);

function buildHTML({ fileInput, project, refresh }) {
  const controllers = ["spreadsheet-import"];
  if (refresh) controllers.push("refresh");

  const hostAttrs = [
    `data-controller="${controllers.join(" ")}"`,
    'id="host"',
    'data-spreadsheet-import-select-sample-value="Select sample"',
    'data-spreadsheet-import-select-description-value="Select description"',
    'data-spreadsheet-import-select-project-value="Select project"',
  ];
  if (refresh) {
    hostAttrs.push('data-spreadsheet-import-refresh-outlet="#host"');
  }

  const fileInputHTML = fileInput
    ? `<input type="file" data-spreadsheet-import-target="fileInput" data-action="change->spreadsheet-import#readFile" />`
    : "";
  const projectHTML = project
    ? `<select id="spreadsheet_import_project_puid_column"
         data-spreadsheet-import-target="projectPUIDColumn"
         data-action="change->spreadsheet-import#changeInputValue"></select>
       <input type="hidden" id="spreadsheet_import_static_project_id_hidden" />`
    : "";

  return `
    <div ${hostAttrs.join(" ")}>
      ${fileInputHTML}
      <select id="spreadsheet_import_sample_name_column"
        data-spreadsheet-import-target="sampleNameColumn"
        data-action="change->spreadsheet-import#changeInputValue"></select>
      ${projectHTML}
      <select id="spreadsheet_import_sample_description_column"
        data-spreadsheet-import-target="sampleDescriptionColumn"
        data-action="change->spreadsheet-import#changeInputValue"></select>
      <div data-spreadsheet-import-target="metadata" class="hidden"></div>
      <button type="submit" data-spreadsheet-import-target="submitButton" disabled>Submit</button>
    </div>
  `;
}

describe("SpreadsheetImportController", () => {
  let application;

  beforeEach(() => {
    vi.stubGlobal("FileReader", FakeFileReader);
  });

  afterEach(async () => {
    await stopApplication(application);
    application = undefined;
  });

  async function mount({
    preselect = null,
    fileInput = true,
    project = false,
    refresh = false,
  } = {}) {
    document.body.innerHTML = buildHTML({ fileInput, project, refresh });

    const fileInputEl = document.querySelector(
      "[data-spreadsheet-import-target='fileInput']",
    );
    if (preselect) setFiles(fileInputEl, preselect);

    application = startApplication();
    application.register("spreadsheet-import", SpreadsheetImportController);
    if (refresh) application.register("refresh", RefreshStub);
    await Promise.resolve();

    return {
      host: document.querySelector("#host"),
      controller: application.getControllerForElementAndIdentifier(
        document.querySelector("#host"),
        "spreadsheet-import",
      ),
      fileInput: fileInputEl,
      sampleName: document.getElementById(
        "spreadsheet_import_sample_name_column",
      ),
      sampleDescription: document.getElementById(
        "spreadsheet_import_sample_description_column",
      ),
      projectPUID: document.getElementById(
        "spreadsheet_import_project_puid_column",
      ),
      staticProject: document.getElementById(
        "spreadsheet_import_static_project_id_hidden",
      ),
      metadata: document.querySelector(
        "[data-spreadsheet-import-target='metadata']",
      ),
      submitButton: document.querySelector(
        "[data-spreadsheet-import-target='submitButton']",
      ),
    };
  }

  it("processes a file already selected before it connects", async () => {
    stubWorkbook(["sample_name", "description", "country", "age"]);

    const { sampleName, sampleDescription, submitButton, metadata } =
      await mount({ preselect: [fileObj()] });
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    expect(sampleName.value).toBe("sample_name");
    expect(sampleDescription.value).toBe("description");
    expect(submitButton.disabled).toBe(false);
    expect(metadata.classList.contains("hidden")).toBe(false);
  });

  it("reads a file selected after connect and moves sample columns to the top", async () => {
    stubWorkbook(["sample_id", "sample_name", "country"]);

    const { fileInput, sampleName } = await mount();
    setFiles(fileInput, [fileObj()]);
    fileInput.dispatchEvent(new Event("change", { bubbles: true }));
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    // sample_name is auto-selected; the remaining sample-type column (sample_id)
    // is reordered ahead of the plain column (country).
    expect(optionValues(sampleName)).toEqual([
      "",
      "sample_name",
      "sample_id",
      "country",
    ]);
  });

  it("clears the form and disables submit when the selection is empty", async () => {
    const { fileInput, submitButton } = await mount();
    setFiles(fileInput, []);
    fileInput.dispatchEvent(new Event("change", { bubbles: true }));
    await Promise.resolve();

    expect(mockSheetToJson).not.toHaveBeenCalled();
    expect(submitButton.disabled).toBe(true);
  });

  it("ignores a stale file read when a newer file is selected", async () => {
    const { fileInput, sampleName } = await mount();

    stubWorkbook(["old_col"]);
    setFiles(fileInput, [fileObj("old.csv")]);
    fileInput.dispatchEvent(new Event("change", { bubbles: true }));

    stubWorkbook(["sample_name", "country"]);
    setFiles(fileInput, [fileObj("new.csv")]);
    fileInput.dispatchEvent(new Event("change", { bubbles: true }));

    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalledTimes(1));

    // The stale read short-circuits before parsing, so only the newer file lands.
    expect(sampleName.value).toBe("sample_name");
    expect(optionValues(sampleName)).toEqual(["", "sample_name", "country"]);
  });

  it("does nothing on connect when there is no file input target", async () => {
    const { submitButton } = await mount({ fileInput: false });

    expect(mockSheetToJson).not.toHaveBeenCalled();
    expect(submitButton.disabled).toBe(true);
  });

  it("auto-selects the project column and enables submit for project imports", async () => {
    stubWorkbook(["sample_name", "project_puid", "description", "country"]);

    const { projectPUID, submitButton } = await mount({
      preselect: [fileObj()],
      project: true,
    });
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    expect(projectPUID.value).toBe("project_puid");
    expect(submitButton.disabled).toBe(false);
  });

  it("enables submit via a static project when no project column is chosen", async () => {
    stubWorkbook(["sample_name", "country"]);

    const { staticProject, fileInput, submitButton } = await mount({
      project: true,
    });
    staticProject.value = "project-1";
    setFiles(fileInput, [fileObj()]);
    fileInput.dispatchEvent(new Event("change", { bubbles: true }));
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    expect(submitButton.disabled).toBe(false);
  });

  it("keeps submit disabled for project imports with neither a project column nor static project", async () => {
    stubWorkbook(["sample_name", "country"]);

    const { submitButton } = await mount({
      preselect: [fileObj()],
      project: true,
    });
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    expect(submitButton.disabled).toBe(true);
  });

  it("keeps submit disabled when no sample column is recognized", async () => {
    stubWorkbook(["country", "age"]);

    const { sampleName, submitButton } = await mount({
      preselect: [fileObj()],
      project: true,
    });
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    expect(sampleName.value).toBe("");
    expect(submitButton.disabled).toBe(true);
  });

  it("hides the metadata section when every column is used as a selection", async () => {
    stubWorkbook(["sample_name", "description", "project_puid"]);

    const { metadata } = await mount({ preselect: [fileObj()], project: true });
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    expect(metadata.classList.contains("hidden")).toBe(true);
  });

  it("updates the matching select when a column choice changes", async () => {
    stubWorkbook(["sample_name", "description", "project_puid", "country"]);

    const { controller, sampleName, sampleDescription, projectPUID } =
      await mount({ preselect: [fileObj()], project: true });
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    sampleName.value = "country";
    sampleName.dispatchEvent(new Event("change", { bubbles: true }));
    sampleDescription.value = "";
    sampleDescription.dispatchEvent(new Event("change", { bubbles: true }));
    projectPUID.value = "";
    projectPUID.dispatchEvent(new Event("change", { bubbles: true }));
    // An event from an element that is not one of the column selects is ignored.
    controller.changeInputValue({ target: { id: "unrelated", value: "x" } });

    expect(sampleName.value).toBe("country");
  });

  it("notifies refresh controllers on submit", async () => {
    const ignoreNextRefresh = vi.spyOn(
      RefreshStub.prototype,
      "ignoreNextRefresh",
    );
    const { controller } = await mount({ refresh: true });

    controller.handleSubmit();

    expect(ignoreNextRefresh).toHaveBeenCalled();
  });
});
