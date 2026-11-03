import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import LinelistExportController from "../../../app/javascript/controllers/linelist_export_controller.js";
import { XlsxLibraryLoadError } from "../../../app/javascript/controllers/linelist_export/downloader.js";

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
  <template data-linelist-export-target="progressTemplate">
    <div>
      <p data-linelist-export-progress-message></p>
      <div data-linelist-export-progress-bar></div>
      <span data-linelist-export-progress-percent></span>
    </div>
  </template>`;

const BASENAME_INVALID_MESSAGE =
  "Basename can only contain letters, numbers, '-', and '_'";
const BASENAME_TOO_LONG_MESSAGE =
  "File basename is too long (maximum is 100 characters)";

function markup({
  basename = "",
  withBasename = true,
  withBasenameErrorTargets = true,
  withBasenameErrorMessage = true,
  withFormErrorSummary = true,
  withFormErrorSummaryHeading = true,
  withSampleStatus = true,
} = {}) {
  return `
    <div data-controller="linelist-export"
         data-linelist-export-worker-url-value="worker.js"
         data-linelist-export-graphql-url-value="/graphql"
          data-linelist-export-sample-graphql-id-prefix-value="gid://irida/Sample/"
          data-linelist-export-form-error-summary-title-one-value="There is 1 field with problems preventing submission"
          data-linelist-export-form-error-summary-title-other-value="There are %{count} fields with problems preventing submission"
          data-linelist-export-basename-invalid-message-value="${BASENAME_INVALID_MESSAGE}"
          data-linelist-export-basename-too-long-message-value="${BASENAME_TOO_LONG_MESSAGE}">
      ${withSampleStatus ? '<span data-linelist-export-target="sampleStatus"></span>' : ""}
      ${withFormErrorSummary ? `<div data-linelist-export-target="formErrorSummary" class="hidden">${withFormErrorSummaryHeading ? "<h2></h2>" : ""}<ul><li><a href="#basename"></a></li><li><a href="#basename"></a></li></ul></div>` : ""}
      <input name="data_export[export_parameters][namespace_id]" value="7">
      <input type="radio" name="data_export[export_parameters][linelist_format]" value="csv" checked>
      ${withBasename ? `<div class="form-field" ${withBasenameErrorTargets ? 'data-linelist-export-target="basenameField"' : ""}><label for="basename">File Basename</label><input id="basename" aria-describedby="basename_hint" data-linelist-export-target="basename" maxlength="100" pattern="^[\\w\\-]*$" value="${basename}">${withBasenameErrorTargets ? `<span id="basename_error" data-linelist-export-target="basenameError" class="hidden">${withBasenameErrorMessage ? '<span class="grow"></span>' : ""}</span>` : ""}</div>` : ""}
      <ul id="selected-list"><li><span>x</span><span>age</span></li></ul>
      ${PROGRESS_TEMPLATE}
    </div>`;
}

describe("linelist export controller", () => {
  let application;

  async function mount(options) {
    document.body.innerHTML = markup(options);
    application = startApplication();
    application.register("linelist-export", LinelistExportController);
    await Promise.resolve();
    const element = document.querySelector(
      '[data-controller="linelist-export"]',
    );
    return application.getControllerForElementAndIdentifier(
      element,
      "linelist-export",
    );
  }

  function storeSelection(ids) {
    sessionStorage.setItem(
      `${location.protocol}//${location.host}${location.pathname}`,
      JSON.stringify(ids),
    );
  }

  const messageText = () =>
    document.querySelector("[data-linelist-export-progress-message]")
      ?.textContent;

  // The worker client's onmessage wrapper does not return its promise, so let
  // the async done handler (download + progress update) settle before asserting.
  const flush = async () => {
    for (let i = 0; i < 5; i += 1) await Promise.resolve();
  };

  beforeEach(() => {
    FakeWorker.instances = [];
    vi.stubGlobal("Worker", FakeWorker);
    vi.stubGlobal("URL", {
      ...URL,
      createObjectURL: vi.fn(() => "blob:mock"),
      revokeObjectURL: vi.fn(),
    });
  });

  afterEach(async () => {
    await stopApplication(application);
    vi.unstubAllGlobals();
    vi.restoreAllMocks();
  });

  it("shows the selected sample count on connect", async () => {
    storeSelection(["1", "2", "3"]);
    await mount();
    expect(
      document.querySelector("[data-linelist-export-target='sampleStatus']")
        .textContent,
    ).toBe("Selected samples: 3");
  });

  it("blocks export and warns when no samples are selected", async () => {
    storeSelection([]);
    const controller = await mount();
    const updateProgress = vi.spyOn(controller, "updateProgress");
    controller.startExport();
    expect(updateProgress).toHaveBeenCalledWith(
      "Please select at least 1 sample before exporting.",
      100,
      true,
    );
    expect(FakeWorker.instances).toHaveLength(0);
  });

  it("starts the worker with the assembled payload", async () => {
    storeSelection(["1", "2"]);
    const controller = await mount();
    controller.startExport();

    const worker = FakeWorker.instances.at(-1);
    expect(worker.source).toBe("worker.js");
    expect(worker.posted[0]).toMatchObject({
      sample_ids: ["1", "2"],
      metadata_fields: ["age"],
      namespace_id: "7",
      graphql_url: "/graphql",
      sample_graphql_id_prefix: "gid://irida/Sample/",
      format: "csv",
      total_count: 2,
    });
    expect(worker.posted[0].filename).toMatch(/^linelist-.*\.csv$/);
    controller.terminateWorker();
  });

  it("uses a custom basename for the export filename", async () => {
    storeSelection(["1"]);
    const controller = await mount({ basename: "my-linelist-export" });
    controller.startExport();

    const worker = FakeWorker.instances.at(-1);
    expect(worker.posted[0].filename).toBe("my-linelist-export.csv");
    controller.terminateWorker();
  });

  it("falls back to the timestamped filename when the basename field is absent", async () => {
    storeSelection(["1"]);
    const controller = await mount({ withBasename: false });
    controller.startExport();

    const worker = FakeWorker.instances.at(-1);
    expect(worker.posted[0].filename).toMatch(/^linelist-.*\.csv$/);
    controller.terminateWorker();
  });

  it("submits without optional basename and summary targets", async () => {
    storeSelection(["1"]);
    const controller = await mount({
      withBasename: false,
      withFormErrorSummary: false,
    });
    const start = vi
      .spyOn(controller, "startExport")
      .mockImplementation(() => {});
    const event = new Event("submit", { cancelable: true });

    controller.submit(event);

    expect(event.defaultPrevented).toBe(true);
    expect(start).toHaveBeenCalled();
    expect(() => controller.showBasenameErrorState(["error"])).not.toThrow();
  });

  it("handles invalid input without optional error targets", async () => {
    const controller = await mount({
      basename: "invalid basename",
      withBasenameErrorTargets: false,
      withFormErrorSummary: false,
    });
    const start = vi
      .spyOn(controller, "startExport")
      .mockImplementation(() => {});
    vi.spyOn(controller.basenameTarget, "reportValidity").mockImplementation(
      () => {},
    );
    const event = new Event("submit", { cancelable: true });

    controller.submit(event);

    expect(event.defaultPrevented).toBe(true);
    expect(start).not.toHaveBeenCalled();
    expect(controller.basenameTarget.getAttribute("aria-invalid")).toBe("true");
  });

  it("skips the sample status update when the target is absent", async () => {
    storeSelection(["1"]);
    const controller = await mount({ withSampleStatus: false });
    controller.startExport();
    expect(FakeWorker.instances).toHaveLength(1);
    controller.terminateWorker();
  });

  it("routes worker progress into the progress window", async () => {
    storeSelection(["1", "2"]);
    const controller = await mount();
    controller.startExport();
    const worker = FakeWorker.instances.at(-1);

    await worker.onmessage({
      data: { type: "progress", current: 1, total: 2, percentage: 50 },
    });

    expect(messageText()).toBe("Created 1 of 2 records");
    expect(
      document.querySelector("[data-linelist-export-progress-bar]").style.width,
    ).toBe("50%");
    controller.terminateWorker();
  });

  it("downloads a CSV export when the worker finishes", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    const clickSpy = vi
      .spyOn(HTMLAnchorElement.prototype, "click")
      .mockImplementation(() => {});
    controller.startExport();
    const worker = FakeWorker.instances.at(-1);

    await worker.onmessage({
      data: {
        type: "done",
        filename: "linelist.csv",
        content: "a,b\n1,2",
        format: "csv",
      },
    });
    await flush();

    expect(URL.createObjectURL).toHaveBeenCalledOnce();
    expect(messageText()).toBe("Download started: linelist.csv");
    expect(worker.terminated).toBe(true);
    clickSpy.mockRestore();
  });

  it("reports the XLSX load failure with a friendly message", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    vi.spyOn(controller, "download").mockRejectedValue(
      new XlsxLibraryLoadError(),
    );
    controller.startExport();
    const worker = FakeWorker.instances.at(-1);

    await worker.onmessage({
      data: {
        type: "done",
        filename: "linelist.xlsx",
        content: [["A"]],
        format: "xlsx",
      },
    });
    await flush();

    expect(messageText()).toBe(
      "Unable to load the XLSX export library. Please retry or export as CSV.",
    );
  });

  it("reports unexpected download failures", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    vi.spyOn(controller, "download").mockRejectedValue(new Error("disk full"));
    controller.startExport();
    const worker = FakeWorker.instances.at(-1);

    await worker.onmessage({
      data: { type: "done", filename: "f.csv", content: "x", format: "csv" },
    });
    await flush();

    expect(messageText()).toBe(
      "Unexpected error while generating export: disk full",
    );
  });

  it("surfaces worker error messages", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    controller.startExport();
    const worker = FakeWorker.instances.at(-1);

    await worker.onmessage({
      data: { type: "error", message: "worker exploded" },
    });

    expect(messageText()).toBe("worker exploded");
    expect(worker.terminated).toBe(true);
  });

  it("trims the trailing separator when the error detail is empty", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    controller.startExport();
    const worker = FakeWorker.instances.at(-1);

    worker.onerror({ message: "" });
    await Promise.resolve();

    expect(messageText()).toBe("Unexpected error while generating export");
    controller.terminateWorker();
  });

  it("handles worker start failures", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    controller.workerClient.start = vi.fn(() => {
      throw new Error("cannot boot");
    });

    controller.startExport();

    expect(messageText()).toBe("Unable to start export: cannot boot");
  });

  it("falls back to an unknown-error message when start throws without a message", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    controller.workerClient.start = vi.fn(() => {
      throw {};
    });

    controller.startExport();

    expect(messageText()).toBe("Unable to start export: unknown error");
  });

  it("closes the dialog and starts the export on submit", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    const start = vi
      .spyOn(controller, "startExport")
      .mockImplementation(() => {});
    const event = new Event("submit", { cancelable: true });
    const stop = vi.spyOn(event, "stopPropagation");

    controller.submit(event);

    expect(event.defaultPrevented).toBe(true);
    expect(stop).toHaveBeenCalled();
    expect(start).toHaveBeenCalled();
    expect(controller.basenameFieldTarget.classList).not.toContain("invalid");
    expect(controller.basenameTarget.hasAttribute("aria-invalid")).toBe(false);
    expect(controller.basenameTarget.getAttribute("aria-describedby")).toBe(
      "basename_hint",
    );
    expect(controller.basenameErrorTarget.classList).toContain("hidden");
  });

  it("blocks submission when the basename is invalid", async () => {
    storeSelection(["1"]);
    const controller = await mount({ basename: "invalid basename" });
    const start = vi
      .spyOn(controller, "startExport")
      .mockImplementation(() => {});
    const basename = controller.basenameTarget;
    const reportValidity = vi
      .spyOn(basename, "reportValidity")
      .mockImplementation(() => {});
    const event = new Event("submit", { cancelable: true });
    const stop = vi.spyOn(event, "stopPropagation");

    controller.submit(event);

    expect(event.defaultPrevented).toBe(true);
    expect(stop).toHaveBeenCalled();
    expect(reportValidity).toHaveBeenCalled();
    expect(start).not.toHaveBeenCalled();
    expect(controller.formErrorSummaryTarget.classList).not.toContain("hidden");
    expect(controller.basenameFieldTarget.classList).toContain("invalid");
    expect(controller.basenameTarget.getAttribute("aria-invalid")).toBe("true");
    expect(controller.basenameTarget.getAttribute("aria-describedby")).toBe(
      "basename_hint",
    );
    expect(controller.basenameErrorTarget.classList).not.toContain("hidden");
    expect(controller.basenameErrorTarget.textContent).toContain(
      BASENAME_INVALID_MESSAGE,
    );
    expect(
      controller.formErrorSummaryTarget.querySelector("a").textContent,
    ).toBe(BASENAME_INVALID_MESSAGE);
    expect(
      controller.formErrorSummaryTarget.querySelector("h2").textContent,
    ).toBe("There is 1 field with problems preventing submission");
  });

  it("blocks submission when the basename is over 100 characters", async () => {
    storeSelection(["1"]);
    const controller = await mount({ basename: "a".repeat(101) });
    const start = vi
      .spyOn(controller, "startExport")
      .mockImplementation(() => {});
    const reportValidity = vi
      .spyOn(controller.basenameTarget, "reportValidity")
      .mockImplementation(() => {});
    const event = new Event("submit", { cancelable: true });

    controller.submit(event);

    expect(event.defaultPrevented).toBe(true);
    expect(reportValidity).toHaveBeenCalled();
    expect(start).not.toHaveBeenCalled();
    expect(controller.formErrorSummaryTarget.classList).not.toContain("hidden");
    expect(controller.basenameFieldTarget.classList).toContain("invalid");
    expect(controller.basenameTarget.getAttribute("aria-invalid")).toBe("true");
    expect(controller.basenameErrorTarget.classList).not.toContain("hidden");
    expect(controller.basenameErrorTarget.textContent).toContain(
      BASENAME_TOO_LONG_MESSAGE,
    );
    expect(
      controller.formErrorSummaryTarget.querySelector("a").textContent,
    ).toBe(BASENAME_TOO_LONG_MESSAGE);
    expect(
      controller.formErrorSummaryTarget.querySelector("h2").textContent,
    ).toBe("There is 1 field with problems preventing submission");
  });

  it("displays both errors when the basename violates both constraints", async () => {
    storeSelection(["1"]);
    const controller = await mount({ basename: `${"a".repeat(100)} ` });
    const start = vi
      .spyOn(controller, "startExport")
      .mockImplementation(() => {});
    const reportValidity = vi
      .spyOn(controller.basenameTarget, "reportValidity")
      .mockImplementation(() => {});
    const event = new Event("submit", { cancelable: true });

    controller.submit(event);

    expect(event.defaultPrevented).toBe(true);
    expect(start).not.toHaveBeenCalled();
    expect(controller.basenameErrorTarget.textContent).toContain(
      BASENAME_TOO_LONG_MESSAGE,
    );
    expect(controller.basenameErrorTarget.textContent).toContain(
      BASENAME_INVALID_MESSAGE,
    );
    const summaryLinks =
      controller.formErrorSummaryTarget.querySelectorAll("a");
    expect(summaryLinks).toHaveLength(2);
    expect(summaryLinks[0].textContent).toBe(BASENAME_TOO_LONG_MESSAGE);
    expect(summaryLinks[1].textContent).toBe(BASENAME_INVALID_MESSAGE);
    expect(
      controller.formErrorSummaryTarget.querySelector("h2").textContent,
    ).toBe("There are 2 fields with problems preventing submission");
    expect(reportValidity).toHaveBeenCalled();
  });

  it("renders a basename error when the message child is absent", async () => {
    const controller = await mount({ withBasenameErrorMessage: false });

    controller.showBasenameErrorState(["Basename is invalid"]);

    expect(controller.basenameErrorTarget.textContent).toBe(
      "Basename is invalid",
    );
  });

  it("updates summary links without requiring a heading", async () => {
    const controller = await mount({ withFormErrorSummaryHeading: false });

    controller.showFormErrorSummary(["Basename is invalid"]);

    expect(controller.formErrorSummaryTarget.classList).not.toContain("hidden");
    expect(
      controller.formErrorSummaryTarget.querySelector("a").textContent,
    ).toBe("Basename is invalid");
  });

  it("guards against navigation while an export is in flight", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    controller.startExport();

    const active = new Event("beforeunload", { cancelable: true });
    window.dispatchEvent(active);
    expect(active.defaultPrevented).toBe(true);

    controller.terminateWorker();

    const idle = new Event("beforeunload", { cancelable: true });
    window.dispatchEvent(idle);
    expect(idle.defaultPrevented).toBe(false);
  });

  it("keeps the export running across a disconnect", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    controller.startExport();
    expect(() => controller.disconnect()).not.toThrow();
    controller.terminateWorker();
  });

  it("keeps guarding navigation while a concurrent export is still active", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    controller.startExport();
    controller.startExport();

    controller.terminateWorker();
    const stillActive = new Event("beforeunload", { cancelable: true });
    window.dispatchEvent(stillActive);
    expect(stillActive.defaultPrevented).toBe(true);

    controller.terminateWorker();
    const idle = new Event("beforeunload", { cancelable: true });
    window.dispatchEvent(idle);
    expect(idle.defaultPrevented).toBe(false);
  });

  it("reports a generic message when the download error has no message", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    vi.spyOn(controller, "download").mockRejectedValue(new Error());
    controller.startExport();
    const worker = FakeWorker.instances.at(-1);

    await worker.onmessage({
      data: { type: "done", filename: "f.csv", content: "x", format: "csv" },
    });
    await flush();

    expect(messageText()).toBe("Unexpected error while generating export");
  });

  it("dismisses the progress window on demand", async () => {
    storeSelection(["1"]);
    const controller = await mount();
    controller.startExport();
    expect(messageText()).toBe("Preparing 1 rows");

    controller.dismissProgressWindow();

    expect(messageText()).toBeUndefined();
    expect(controller.progressWindowDismissed).toBe(true);
    controller.terminateWorker();
  });
});
