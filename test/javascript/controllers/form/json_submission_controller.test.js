import { Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";
import JsonSubmissionController from "../../../../app/javascript/controllers/form/json_submission_controller.js";

describe("JSON form submission", () => {
  let application, form, clearSelection, selectedItems;
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount({
    selection = false,
    fieldName,
    clear = false,
    ids = ["1", "2"],
  } = {}) {
    document.body.innerHTML = `<div id="selected-samples" data-controller="selection"></div>
      <form data-controller="form--json-submission" data-form--json-submission-target="form" data-form--json-submission-clear-selection-value="${clear}"
        ${selection ? 'data-form--json-submission-selection-outlet="#selected-samples"' : ""}>
        <input name="authenticity_token" value="csrf-token">
        <input name="transfer[destination]" value="42">
        <input name="tags[]" value="alpha"><input name="tags[]" value="beta">
        <input name="ignored" value="disabled" disabled>
      </form>`;
    form = document.querySelector("form");
    if (fieldName !== undefined)
      form.setAttribute(
        "data-form--json-submission-field-name-value",
        fieldName,
      );
    clearSelection = vi.fn();
    selectedItems = vi.fn().mockReturnValue(ids);
    class SelectionOutlet extends Controller {
      clear() {
        clearSelection();
      }
      getOrCreateStoredItems() {
        return selectedItems();
      }
    }
    application = startApplication();
    application.register("selection", SelectionOutlet);
    application.register("form--json-submission", JsonSubmissionController);
    await Promise.resolve();
    await Promise.resolve();
  }
  function request() {
    const detail = {
      fetchOptions: {
        body: new FormData(form),
        headers: {
          Accept: "text/vnd.turbo-stream.html",
          "X-CSRF-Token": "csrf-token",
        },
      },
      resume: vi.fn(),
    };
    form.dispatchEvent(
      new CustomEvent("turbo:before-fetch-request", {
        bubbles: true,
        cancelable: true,
        detail,
      }),
    );
    return detail;
  }
  function finish(success) {
    form.dispatchEvent(
      new CustomEvent("turbo:submit-end", {
        bubbles: true,
        detail: { success },
      }),
    );
  }
  it("serializes real form fields into nested JSON while preserving other headers", async () => {
    await mount();
    const detail = request();
    expect(form.dataset.connected).toBe("true");
    expect(JSON.parse(detail.fetchOptions.body)).toEqual({
      authenticity_token: "csrf-token",
      transfer: { destination: "42" },
      tags: ["alpha", "beta"],
    });
    expect(detail.fetchOptions.headers).toEqual({
      Accept: "text/vnd.turbo-stream.html",
      "X-CSRF-Token": "csrf-token",
      "Content-Type": "application/json",
    });
    expect(detail.resume).toHaveBeenCalledOnce();
  });
  it("adds the selected IDs under the configured nested field", async () => {
    await mount({ selection: true, fieldName: "transfer[sample_ids][]" });
    const detail = request();
    expect(JSON.parse(detail.fetchOptions.body).transfer).toEqual({
      destination: "42",
      sample_ids: ["1", "2"],
    });
    expect(selectedItems).toHaveBeenCalledOnce();
  });
  it("represents an empty selection as an empty array", async () => {
    await mount({
      selection: true,
      fieldName: "transfer[sample_ids][]",
      ids: [],
    });
    expect(JSON.parse(request().fetchOptions.body).transfer.sample_ids).toEqual(
      [],
    );
  });
  it.each([{ selection: true }, { fieldName: "transfer[sample_ids][]" }])(
    "omits selection data when configuration is incomplete: %j",
    async (options) => {
      await mount(options);
      expect(JSON.parse(request().fetchOptions.body).transfer).toEqual({
        destination: "42",
      });
      expect(selectedItems).not.toHaveBeenCalled();
    },
  );
  it.each([
    [true, true, 1],
    [false, true, 0],
    [true, false, 0],
  ])(
    "clears selection after success=%s with clear=%s",
    async (success, clear, calls) => {
      await mount({ selection: true, clear });
      finish(success);
      expect(clearSelection).toHaveBeenCalledTimes(calls);
    },
  );
  it("removes Turbo listeners while disconnected and registers them once on reconnect", async () => {
    await mount({ selection: true, clear: true });
    form.remove();
    await Promise.resolve();
    const disconnected = request();
    finish(true);
    expect(disconnected.resume).not.toHaveBeenCalled();
    expect(disconnected.fetchOptions.body).toBeInstanceOf(FormData);
    expect(clearSelection).not.toHaveBeenCalled();
    document.body.append(form);
    await Promise.resolve();
    expect(request().resume).toHaveBeenCalledOnce();
    finish(true);
    expect(clearSelection).toHaveBeenCalledOnce();
  });
});
