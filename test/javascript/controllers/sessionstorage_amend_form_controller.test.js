import { afterEach, beforeEach, describe, expect, it } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import StorageFormController from "../../../app/javascript/controllers/sessionstorage_amend_form_controller.js";

describe("session storage form amendment", () => {
  let application, form, originalUrl;
  beforeEach(() => {
    originalUrl = location.href;
  });
  afterEach(async () => {
    await stopApplication(application);
    history.replaceState(null, "", originalUrl);
  });
  async function mount({ key, values, name = "sample_ids[]" } = {}) {
    const storageKey = key ?? `${location.origin}${location.pathname}`;
    if (values !== undefined)
      sessionStorage.setItem(storageKey, JSON.stringify(values));
    document.body.innerHTML = `<form data-controller="sessionstorage-amend-form" data-sessionstorage-amend-form-field-name-value="${name}" data-sessionstorage-amend-form-target="field">
      <input type="hidden" name="authenticity_token" value="csrf-token">
      <button type="button" data-action="sessionstorage-amend-form#clear">Clear stored selection</button>
    </form>`;
    form = document.querySelector("form");
    if (key !== undefined)
      form.setAttribute(
        "data-sessionstorage-amend-form-storage-key-value",
        key,
      );
    application = startApplication();
    application.register("sessionstorage-amend-form", StorageFormController);
    await Promise.resolve();
  }
  it("appends named hidden fields from an explicit storage key", async () => {
    await mount({ key: "selected-samples", values: ["1", "2"] });
    expect(new FormData(form).getAll("sample_ids[]")).toEqual(["1", "2"]);
    expect(new FormData(form).get("authenticity_token")).toBe("csrf-token");
    expect(
      [...form.querySelectorAll('[name="sample_ids[]"]')].every(
        (field) => field.type === "hidden",
      ),
    ).toBe(true);
  });
  it.each([undefined, null, []])(
    "does not add fields when storage contains %j",
    async (values) => {
      await mount({ key: "selected-samples", values });
      expect(new FormData(form).getAll("sample_ids[]")).toEqual([]);
    },
  );
  it("uses the current page path after navigation, excluding query and fragment", async () => {
    history.replaceState(null, "", "/projects/42/samples?page=2#selection");
    await mount({ values: ["42"] });
    expect(new FormData(form).getAll("sample_ids[]")).toEqual(["42"]);
    form.querySelector("button").click();
    expect(
      sessionStorage.getItem(`${location.origin}/projects/42/samples`),
    ).toBeNull();
  });
  it("clears only the configured storage key", async () => {
    sessionStorage.setItem("other-selection", '["9"]');
    await mount({ key: "selected-samples", values: ["1"] });
    form.querySelector("button").click();
    expect(sessionStorage.getItem("selected-samples")).toBeNull();
    expect(sessionStorage.getItem("other-selection")).toBe('["9"]');
    expect(new FormData(form).getAll("sample_ids[]")).toEqual(["1"]);
  });
  it("preserves fields it did not create when reconnecting", async () => {
    await mount({ key: "selected-samples", values: ["1"] });
    const existing = document.createElement("input");
    existing.name = "sample_ids[]";
    existing.value = "server-value";
    form.prepend(existing);
    form.remove();
    await Promise.resolve();
    document.body.append(form);
    await Promise.resolve();
    expect(new FormData(form).getAll("sample_ids[]")).toEqual([
      "server-value",
      "1",
    ]);
  });
  it("rebuilds its fields without duplicating them after reconnect", async () => {
    await mount({ key: "selected-samples", values: ["1", "2"] });
    form.remove();
    await Promise.resolve();
    sessionStorage.setItem("selected-samples", '["3"]');
    document.body.append(form);
    await Promise.resolve();
    expect(new FormData(form).getAll("sample_ids[]")).toEqual(["3"]);
    expect(new FormData(form).get("authenticity_token")).toBe("csrf-token");
  });
});
