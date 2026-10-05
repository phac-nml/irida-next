import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import FileUploadController from "../../../app/javascript/controllers/file_upload_controller.js";

// jsdom lacks DataTransfer; the controller uses it to rebuild the input's
// FileList after filtering out ignored files.
class FakeDataTransfer {
  constructor() {
    this._files = [];
    this.items = { add: (file) => this._files.push(file) };
  }
  get files() {
    return this._files;
  }
}

describe("FileUploadController", () => {
  let application;

  beforeEach(() => {
    vi.stubGlobal("DataTransfer", FakeDataTransfer);
  });

  afterEach(async () => {
    await stopApplication(application);
  });

  async function mount({
    ignore = [".txt"],
    alert = true,
    presetTabindex = false,
    form = true,
    submit = true,
  } = {}) {
    const submitHtml = submit
      ? `<button type="submit" data-attachment-upload-target="submitButton"></button>`
      : "";
    const inputHtml = `<input type="file" data-action="change->file-upload#handleFileChange">`;
    const alertHtml = alert
      ? `<div data-file-upload-target="alert" class="hidden"${
          presetTabindex ? ' tabindex="-1"' : ""
        }><ul data-file-upload-target="error"></ul></div>`
      : "";

    document.body.innerHTML = `
      <div data-controller="file-upload" data-file-upload-ignore-value='${JSON.stringify(
        ignore,
      )}'>
        ${form ? `<form>${inputHtml}${submitHtml}</form>` : inputHtml}
        ${alertHtml}
      </div>`;

    application = startApplication();
    application.register("file-upload", FileUploadController);
    await Promise.resolve();

    return {
      input: document.querySelector("input[type=file]"),
      alert: document.querySelector("[data-file-upload-target='alert']"),
      submitButton: document.querySelector(
        "[data-attachment-upload-target='submitButton']",
      ),
    };
  }

  function selectFiles(input, names) {
    Object.defineProperty(input, "files", {
      configurable: true,
      writable: true,
      value: names.map((name) => new File(["x"], name)),
    });
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }

  it("keeps allowed files, reports ignored ones, and enables submit", async () => {
    const { input, alert, submitButton } = await mount();

    selectFiles(input, ["keep.csv", "drop.txt"]);

    expect(Array.from(input.files).map((file) => file.name)).toEqual([
      "keep.csv",
    ]);
    expect(alert.classList.contains("hidden")).toBe(false);
    expect(alert.querySelector("ul").innerHTML).toBe("<li>drop.txt</li>");
    expect(input.getAttribute("aria-invalid")).toBe("true");
    expect(alert.getAttribute("tabindex")).toBe("-1");
    expect(submitButton.disabled).toBe(false);
  });

  it("disables submit when every file is ignored and keeps an existing tabindex", async () => {
    const { input, alert, submitButton } = await mount({
      presetTabindex: true,
    });

    selectFiles(input, ["a.txt", "b.txt"]);

    expect(input.files.length).toBe(0);
    expect(alert.querySelector("ul").innerHTML).toBe(
      "<li>a.txt</li><li>b.txt</li>",
    );
    expect(alert.getAttribute("tabindex")).toBe("-1");
    expect(submitButton.disabled).toBe(true);
  });

  it("clears the alert and enables submit when nothing is ignored", async () => {
    const { input, alert, submitButton } = await mount();

    selectFiles(input, ["keep.csv"]);

    expect(Array.from(input.files).map((file) => file.name)).toEqual([
      "keep.csv",
    ]);
    expect(alert.classList.contains("hidden")).toBe(true);
    expect(input.getAttribute("aria-invalid")).toBe("false");
    expect(submitButton.disabled).toBe(false);
  });

  it("enables submit without touching an alert when no alert target exists", async () => {
    const { input, submitButton } = await mount({ alert: false });

    selectFiles(input, ["keep.csv", "drop.txt"]);

    expect(input.getAttribute("aria-invalid")).toBe("false");
    expect(submitButton.disabled).toBe(false);
  });

  it("does nothing when the form has no submit button", async () => {
    const { input } = await mount({ submit: false });

    selectFiles(input, ["keep.csv", "drop.txt"]);

    // No submit button means the handler returns before filtering runs.
    expect(Array.from(input.files).map((file) => file.name)).toEqual([
      "keep.csv",
      "drop.txt",
    ]);
  });

  it("does nothing when the input has no form", async () => {
    const { input } = await mount({ form: false, submit: false });

    selectFiles(input, ["keep.csv", "drop.txt"]);

    expect(Array.from(input.files).map((file) => file.name)).toEqual([
      "keep.csv",
      "drop.txt",
    ]);
  });
});
