import { afterEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import MetadataToggleController from "../../../app/javascript/controllers/metadata_toggle_controller.js";

describe("metadata toggle", () => {
  let application;
  async function mount(markup) {
    document.body.innerHTML = markup;
    application = startApplication();
    application.register("metadata-toggle", MetadataToggleController);
    await Promise.resolve();
    return application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="metadata-toggle"]'),
      "metadata-toggle",
    );
  }
  afterEach(async () => {
    await stopApplication(application);
  });

  it("submits the form and replaces only its own page field", async () => {
    const controller =
      await mount(`<form data-controller="metadata-toggle" data-metadata-toggle-page-value="2">
      <input name="other" value="keep"><input name="page" value="original">
    </form>`);
    const form = document.querySelector("form");
    const submit = vi.spyOn(form, "requestSubmit").mockImplementation(() => {});
    controller.submit();
    controller.pageValue = 3;
    controller.submit();
    expect(submit).toHaveBeenCalledTimes(2);
    expect(
      form.querySelectorAll('[data-metadata-toggle-page="true"]'),
    ).toHaveLength(1);
    expect(new FormData(form).getAll("page")).toEqual(["original", "3"]);
    expect(new FormData(form).get("other")).toBe("keep");
  });

  it("finds the parent form from a control without adding a page", async () => {
    await mount(
      '<form><input type="checkbox" data-controller="metadata-toggle" data-action="change->metadata-toggle#submit"></form>',
    );
    const form = document.querySelector("form");
    const submit = vi.spyOn(form, "requestSubmit").mockImplementation(() => {});
    document
      .querySelector("input")
      .dispatchEvent(new Event("change", { bubbles: true }));
    expect(submit).toHaveBeenCalledOnce();
    expect(new FormData(form).has("page")).toBe(false);
  });

  it("falls back to Turbo when requestSubmit is unavailable", async () => {
    const submitForm = vi.fn();
    vi.stubGlobal("Turbo", { navigator: { submitForm } });
    const controller = await mount(
      '<form data-controller="metadata-toggle"></form>',
    );
    const form = document.querySelector("form");
    Object.defineProperty(form, "requestSubmit", { value: undefined });
    controller.submit();
    expect(submitForm).toHaveBeenCalledWith(form);
  });

  it("does nothing outside a form", async () => {
    const controller = await mount('<input data-controller="metadata-toggle">');
    expect(() => controller.submit()).not.toThrow();
  });
});
