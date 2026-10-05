import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import AttachmentUploadController from "../../../app/javascript/controllers/attachment_upload_controller.js";

// jsdom lacks DataTransfer; the controller uses it to rebuild the file input's
// FileList when pruning already-uploaded files after a batch error.
class FakeDataTransfer {
  constructor() {
    this._files = [];
    this.items = { add: (file) => this._files.push(file) };
  }
  get files() {
    return this._files;
  }
}

const FIELD = "attachment[files][]";

// Plain file-like objects give full control over the metadata the controller
// reads (name/size/lastModified/type) without jsdom's read-only File fields.
function fileObj(name, overrides = {}) {
  return { name, size: 100, lastModified: 5, type: "text/plain", ...overrides };
}

describe("AttachmentUploadController", () => {
  let application;

  beforeEach(() => {
    vi.stubGlobal("DataTransfer", FakeDataTransfer);
  });

  afterEach(async () => {
    await stopApplication(application);
  });

  async function mount({
    withForm = true,
    submitType = "button",
    alerts = true,
    values = true,
    existingRows = false,
    detachedInput = false,
  } = {}) {
    const vals = values
      ? `data-attachment-upload-uploading-text-value="Uploading…"
         data-attachment-upload-success-text-value="Done"
         data-attachment-upload-error-fallback-text-value="Failed"`
      : "";
    const uploadAlert = alerts
      ? `<div data-attachment-upload-target="uploadErrorAlert" class="hidden"></div>`
      : "";
    const formAlert = alerts
      ? `<div data-attachment-upload-target="formErrorAlert" class="hidden"></div>`
      : "";
    const submitHtml =
      submitType === "submit"
        ? `<input type="submit" value="Save" data-attachment-upload-target="submitButton">`
        : `<button type="submit" data-attachment-upload-target="submitButton">Save</button>`;
    const rows = existingRows
      ? `<div data-attachment-upload-role="upload-rows"></div>`
      : "";
    const inputAttrs = detachedInput ? ` form="missing-form"` : "";
    const inputHtml = `<input type="file" name="${FIELD}"${inputAttrs} data-attachment-upload-target="attachmentsInput">`;
    const controllerBlock = `<div data-controller="attachment-upload" ${vals}>${uploadAlert}${formAlert}${rows}${inputHtml}${submitHtml}</div>`;
    const inner = withForm
      ? `<form id="real-form">${controllerBlock}</form>`
      : controllerBlock;

    document.body.innerHTML = inner;
    application = startApplication();
    application.register("attachment-upload", AttachmentUploadController);
    await Promise.resolve();

    const controllerEl = document.querySelector(
      "[data-controller='attachment-upload']",
    );
    return {
      controllerEl,
      input: controllerEl.querySelector(
        "[data-attachment-upload-target='attachmentsInput']",
      ),
      submitButton: controllerEl.querySelector(
        "[data-attachment-upload-target='submitButton']",
      ),
      uploadErrorAlert: controllerEl.querySelector(
        "[data-attachment-upload-target='uploadErrorAlert']",
      ),
      formErrorAlert: controllerEl.querySelector(
        "[data-attachment-upload-target='formErrorAlert']",
      ),
      form: document.querySelector("form"),
    };
  }

  function setInputFiles(input, files) {
    Object.defineProperty(input, "files", {
      configurable: true,
      writable: true,
      value: files,
    });
  }

  function addHidden(form) {
    const hidden = document.createElement("input");
    hidden.type = "hidden";
    hidden.name = FIELD;
    form.append(hidden);
    return hidden;
  }

  const fire = (target, type, detail, cancelable = false) =>
    target.dispatchEvent(
      new CustomEvent(type, { bubbles: true, cancelable, detail }),
    );

  const init = (input, id, file) =>
    fire(input, "direct-upload:initialize", { id, file });
  const start = (input, id) => fire(input, "direct-upload:start", { id });
  const progress = (input, id, value) =>
    fire(input, "direct-upload:progress", { id, progress: value });
  const uploadErr = (input, id, error) =>
    fire(input, "direct-upload:error", { id, error }, true);
  const uploadEnd = (input, id) => fire(input, "direct-upload:end", { id });
  const batchStart = (form) => fire(form, "direct-uploads:start", {});
  const batchEnd = (form) => fire(form, "direct-uploads:end", {});

  it("drives a successful upload batch to completion", async () => {
    const { input, submitButton, form } = await mount();

    init(input, 1, fileObj("a.fastq"));
    init(input, 2, fileObj("b.fastq"));

    batchStart(form);
    expect(input.disabled).toBe(true);
    expect(submitButton.disabled).toBe(true);
    expect(submitButton.textContent).toBe("Uploading…");

    start(input, 1);
    progress(input, 1, 40);
    progress(input, 1, 20); // lower value is ignored
    expect(
      document.querySelector("#direct-upload-progress-1").style.width,
    ).toBe("40%");
    progress(input, 1, 100);
    expect(document.querySelector("#upload-progress-1").textContent).toBe(
      "Done",
    );

    const h1 = addHidden(form);
    uploadEnd(input, 1);
    const h2 = addHidden(form);
    uploadEnd(input, 2);

    batchEnd(form);

    expect(input.disabled).toBe(false);
    expect(input.getAttribute("aria-invalid")).toBe("false");
    expect(submitButton.textContent).toBe("Save");
    expect(h1.isConnected).toBe(true);
    expect(h2.isConnected).toBe(true);
    expect(
      document
        .querySelector("#direct-upload-1")
        .classList.contains("direct-upload--complete"),
    ).toBe(true);
  });

  it("prunes completed files and flags errors on a failed batch", async () => {
    const { input, uploadErrorAlert, form } = await mount({
      submitType: "submit",
    });

    const hPre = addHidden(form); // survives from a prior successful upload

    init(input, 1, fileObj("keep.fastq"));
    init(
      input,
      2,
      fileObj("nulls.fastq", { size: NaN, lastModified: NaN, type: "" }),
    );
    init(input, 3, fileObj("bad.fastq"));
    init(input, 4, fileObj("pending.fastq"));
    init(input, 5, fileObj("")); // completes but has no descriptor name

    setInputFiles(input, [
      fileObj("keep.fastq", { size: 200 }), // size mismatch -> retried
      fileObj("keep.fastq", { lastModified: 999 }), // lastModified mismatch -> retried
      fileObj("keep.fastq", { type: "" }), // empty type mismatch -> retried
      fileObj(""), // empty name -> retried
      fileObj("keep.fastq"), // exact match -> pruned
      fileObj("nulls.fastq", { size: 7, lastModified: 8, type: "x" }), // matches null descriptor
      fileObj("other.fastq"), // no descriptor -> retried
    ]);

    batchStart(form);
    start(input, 1);
    start(input, 3);

    const h1 = addHidden(form);
    uploadEnd(input, 1);
    const h2 = addHidden(form);
    uploadEnd(input, 2);
    uploadErr(input, 3, "network");
    uploadEnd(input, 5);
    const hOrphan = addHidden(form); // never claimed -> removed on error

    batchEnd(form);

    expect(uploadErrorAlert.classList.contains("hidden")).toBe(false);
    expect(input.files.map((file) => file.name)).toEqual([
      "keep.fastq",
      "keep.fastq",
      "keep.fastq",
      "",
      "other.fastq",
    ]);
    expect(hPre.isConnected).toBe(true);
    expect(h1.isConnected).toBe(true);
    expect(h2.isConnected).toBe(true);
    expect(hOrphan.isConnected).toBe(false);
    expect(input.disabled).toBe(false);
    expect(
      document
        .querySelector("#direct-upload-4")
        .classList.contains("direct-upload--error"),
    ).toBe(true);
  });

  it("ignores direct-upload events from other elements and unknown ids", async () => {
    const { input, controllerEl, form } = await mount();

    // Events whose target is not the attachments input are ignored.
    fire(controllerEl, "direct-upload:initialize", {
      id: 99,
      file: fileObj("x"),
    });
    fire(controllerEl, "direct-upload:start", { id: 99 });
    fire(controllerEl, "direct-upload:progress", { id: 99, progress: 10 });
    fire(controllerEl, "direct-upload:error", { id: 99, error: "e" });
    fire(controllerEl, "direct-upload:end", { id: 99 });
    // Batch events whose target is not the form are ignored.
    fire(controllerEl, "direct-uploads:start", {});
    fire(controllerEl, "direct-uploads:end", {});
    fire(controllerEl, "turbo:submit-end", { success: false });
    fire(controllerEl, "ajax:error", {});

    expect(controllerEl.querySelector("[id^='direct-upload-']")).toBeNull();

    // Unknown ids on real targets are no-ops.
    start(input, 123);
    progress(input, 123, 50);
    uploadErr(input, 123, "e");
    uploadEnd(input, 123);
    expect(controllerEl.querySelector("[id^='direct-upload-']")).toBeNull();

    // uploadEnd is skipped once an upload has errored.
    init(input, 7, fileObj("g.fastq"));
    start(input, 7);
    uploadErr(input, 7, "boom");
    uploadEnd(input, 7);
    expect(
      document
        .querySelector("#direct-upload-7")
        .classList.contains("direct-upload--complete"),
    ).toBe(false);

    // Re-initializing the same id replaces the previous row.
    init(input, 8, fileObj("h.fastq"));
    const firstRow = document.querySelector("#direct-upload-8");
    init(input, 8, fileObj("h2.fastq"));
    expect(firstRow.isConnected).toBe(false);
    expect(document.querySelectorAll("#direct-upload-8").length).toBe(1);

    // Files initialized during an active batch are added to the batch.
    batchStart(form);
    init(input, 9, fileObj("i.fastq"));
    uploadEnd(input, 9);
    expect(
      document
        .querySelector("#direct-upload-9")
        .classList.contains("direct-upload--complete"),
    ).toBe(true);
    batchEnd(form);
  });

  it("handles turbo submit results and form errors", async () => {
    const { controllerEl, uploadErrorAlert, formErrorAlert, form } =
      await mount();

    // Show an upload error first so we can watch it get hidden.
    uploadErrorAlert.classList.remove("hidden");
    fire(form, "turbo:submit-end", { success: false });
    expect(uploadErrorAlert.classList.contains("hidden")).toBe(true);
    expect(formErrorAlert.classList.contains("hidden")).toBe(false);

    fire(form, "turbo:submit-end", { success: true });
    expect(formErrorAlert.classList.contains("hidden")).toBe(true);

    formErrorAlert.classList.remove("hidden");
    fire(form, "turbo:submit-end", undefined); // no detail -> treated as success
    expect(formErrorAlert.classList.contains("hidden")).toBe(true);

    fire(form, "ajax:error", {});
    expect(formErrorAlert.classList.contains("hidden")).toBe(false);

    // Guard: turbo/ajax events from a non-form target are ignored.
    formErrorAlert.classList.add("hidden");
    fire(controllerEl, "ajax:error", {});
    expect(formErrorAlert.classList.contains("hidden")).toBe(true);
  });

  it("falls back to defaults without alert targets or text values", async () => {
    const { input, form } = await mount({ alerts: false, values: false });

    init(input, 1, fileObj("a.fastq"));
    expect(
      document
        .querySelector("#direct-upload-progress-1")
        .getAttribute("aria-label"),
    ).toBe("Uploading a.fastq");

    init(input, 2, fileObj("b.fastq"));
    batchStart(form);
    start(input, 2);
    uploadEnd(input, 2);
    expect(document.querySelector("#upload-progress-2").textContent).toContain(
      "Uploaded successfully",
    );

    uploadErr(input, 1, "network");
    batchEnd(form); // showUploadErrorAlert is a no-op without the target
    fire(form, "ajax:error", {}); // form error alert is a no-op without the target

    expect(document.querySelector("#upload-progress-1")?.textContent).toContain(
      "Upload failed",
    );
  });

  it("reuses an existing upload rows container", async () => {
    const { input, controllerEl } = await mount({ existingRows: true });

    init(input, 1, fileObj("a.fastq"));

    const rows = controllerEl.querySelector(
      "[data-attachment-upload-role='upload-rows']",
    );
    expect(rows.querySelector("#direct-upload-1")).not.toBeNull();
    expect(
      controllerEl.querySelectorAll(
        "[data-attachment-upload-role='upload-rows']",
      ).length,
    ).toBe(1);
  });

  it("works without a wrapping form", async () => {
    const { input } = await mount({ withForm: false });

    init(input, 1, fileObj("a.fastq"));
    uploadEnd(input, 1);

    expect(
      document
        .querySelector("#direct-upload-1")
        .classList.contains("direct-upload--complete"),
    ).toBe(true);
  });

  it("resolves the form from the closest ancestor when the input is detached", async () => {
    const { input, form } = await mount({ detachedInput: true });

    expect(input.form).toBeNull();

    init(input, 1, fileObj("a.fastq"));
    batchStart(form);
    expect(input.disabled).toBe(true);
    batchEnd(form);
  });

  it("skips file pruning when DataTransfer is unavailable", async () => {
    vi.stubGlobal("DataTransfer", undefined);
    const { input, form } = await mount();

    init(input, 1, fileObj("keep.fastq"));
    init(input, 2, fileObj("bad.fastq"));
    setInputFiles(input, [fileObj("keep.fastq")]);

    batchStart(form);
    uploadEnd(input, 1);
    uploadErr(input, 2, "network");
    batchEnd(form);

    expect(input.files.map((file) => file.name)).toEqual(["keep.fastq"]);
  });

  it("skips file pruning when there are no completed files or no selection", async () => {
    // No completed uploads: every active upload errored or stayed pending.
    const noComplete = await mount();
    init(noComplete.input, 1, fileObj("bad.fastq"));
    init(noComplete.input, 2, fileObj("pending.fastq"));
    setInputFiles(noComplete.input, [fileObj("bad.fastq")]);
    batchStart(noComplete.form);
    uploadErr(noComplete.input, 1, "network");
    batchEnd(noComplete.form);
    expect(noComplete.input.files.map((file) => file.name)).toEqual([
      "bad.fastq",
    ]);
    await stopApplication(application);

    // Completed upload but no files remain selected on the input.
    const noSelection = await mount();
    init(noSelection.input, 1, fileObj("keep.fastq"));
    init(noSelection.input, 2, fileObj("bad.fastq"));
    batchStart(noSelection.form);
    uploadEnd(noSelection.input, 1);
    uploadErr(noSelection.input, 2, "network");
    batchEnd(noSelection.form);
    expect(
      noSelection.controllerEl
        .querySelector("#direct-upload-2")
        .classList.contains("direct-upload--error"),
    ).toBe(true);
  });

  it("ends an empty batch without touching the submit button", async () => {
    const { submitButton, form } = await mount();

    const originalDisabled = submitButton.disabled;
    batchStart(form); // no pending uploads
    batchEnd(form);

    expect(submitButton.disabled).toBe(originalDisabled);
    expect(submitButton.textContent).toBe("Save");
  });
});
