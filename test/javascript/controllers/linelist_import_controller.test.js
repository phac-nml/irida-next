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
  readAsArrayBuffer() {
    this.result = new ArrayBuffer(0);
    queueMicrotask(() => this.onload?.());
  }
}

describe("LinelistImportController", () => {
  let application;

  beforeEach(() => {
    vi.stubGlobal("FileReader", FakeFileReader);
  });

  afterEach(async () => {
    await stopApplication(application);
    application = undefined;
  });

  it("parses a file selected before connect, keeping the worksheet and file type", async () => {
    const sheet = { marker: "worksheet" };
    mockRead.mockReturnValue({
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: sheet },
    });
    mockSheetToJson.mockReturnValue([["sample_name", "country"]]);

    document.body.innerHTML = `
      <div data-controller="linelist-import" id="host">
        <input type="file" data-linelist-import-target="fileInput"
          data-action="change->linelist-import#readFile" />
        <select data-linelist-import-target="sampleIdColumn" disabled>
          <option value="">Select…</option>
        </select>
        <div data-linelist-import-target="metadataColumns" class="hidden" aria-hidden="true"></div>
        <div data-linelist-import-target="error" class="hidden" aria-hidden="true"></div>
        <button type="submit" data-linelist-import-target="submitButton" disabled>Submit</button>
      </div>
    `;

    const fileInput = document.querySelector(
      "[data-linelist-import-target='fileInput']",
    );
    Object.defineProperty(fileInput, "files", {
      configurable: true,
      writable: true,
      value: [{ name: "data.csv", type: "text/csv" }],
    });

    application = startApplication();
    application.register("linelist-import", LinelistImportController);
    await Promise.resolve();
    await vi.waitFor(() => expect(mockSheetToJson).toHaveBeenCalled());

    const controller = application.getControllerForElementAndIdentifier(
      document.querySelector("#host"),
      "linelist-import",
    );

    // The subclass's own readFile ran on connect (not the parent's #processFile),
    // and connect's init did not clobber the captured worksheet/file type.
    expect(controller._worksheet).toBe(sheet);
    expect(controller._fileType).toBe("text/csv");

    const select = document.querySelector(
      "[data-linelist-import-target='sampleIdColumn']",
    );
    expect(select.value).toBe("sample_name");
    expect(
      document.querySelector("[data-linelist-import-target='submitButton']")
        .disabled,
    ).toBe(false);
  });
});
