import { afterEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import FormErrorSummaryController from "../../../app/javascript/controllers/form_error_summary_controller.js";
import { focusWhenVisible } from "utilities/focus";

vi.mock("utilities/focus", () => ({ focusWhenVisible: vi.fn() }));

describe("form error summary", () => {
  let application, controller;
  async function mount(fields = "", targetId = "field") {
    document.body.innerHTML = `<div id="summary" data-controller="form-error-summary" tabindex="-1">
      <a href="#field" data-action="form-error-summary#focusField">Error</a>
    </div>${fields}`;
    document
      .querySelector("a")
      .setAttribute("data-form-error-summary-target-id-param", targetId);
    application = startApplication();
    application.register("form-error-summary", FormErrorSummaryController);
    await Promise.resolve();
    controller = application.getControllerForElementAndIdentifier(
      document.querySelector("#summary"),
      "form-error-summary",
    );
  }
  afterEach(async () => {
    await stopApplication(application);
  });

  it("requests focus on connection", async () => {
    await mount();
    expect(focusWhenVisible).toHaveBeenCalledWith(
      document.querySelector("#summary"),
    );
  });
  it.each([
    ['<input id="field">', "field"],
    ['<input id="field-input">', "field-input"],
    [
      '<input type="checkbox" id="field_first"><input type="checkbox" id="field_second">',
      "field_first",
    ],
    [
      '<div id="field"><label>Choice<input id="nested"></label></div>',
      "nested",
    ],
    ['<div id="field">Validation information</div>', "field"],
  ])(
    "routes error links to the matching control: %s",
    async (fields, expectedId) => {
      await mount(fields);
      const target = document.getElementById(expectedId);
      const scroll = vi
        .spyOn(target, "scrollIntoView")
        .mockImplementation(() => {});
      const event = new MouseEvent("click", {
        bubbles: true,
        cancelable: true,
      });
      document.querySelector("a").dispatchEvent(event);
      expect(event.defaultPrevented).toBe(true);
      expect(focusWhenVisible).toHaveBeenLastCalledWith(target, {
        focusOptions: { focusVisible: true },
      });
      expect(scroll).toHaveBeenCalledWith({
        block: "center",
        inline: "nearest",
      });
      if (fields.includes("Validation information"))
        expect(target.tabIndex).toBe(-1);
    },
  );
  it("prefers the direct ID over alternate matches", async () => {
    await mount(
      '<input id="field"><input id="field-input"><input id="field_first">',
    );
    expect(controller.resolveTarget("field")).toBe(
      document.querySelector("#field"),
    );
  });
  it.each([
    undefined,
    {},
    { escape: (value) => value.replaceAll("[", "\\[").replaceAll("]", "\\]") },
  ])("escapes checkbox prefixes with CSS support=%j", async (css) => {
    vi.stubGlobal("CSS", css);
    await mount('<input id="field[value]_first">', "field[value]");
    expect(controller.resolveTarget("field[value]")).toBe(
      document.querySelector("input"),
    );
  });
  it.each(["", "missing"])(
    "leaves focus alone for an unresolved target %j",
    async (targetId) => {
      await mount("", targetId);
      focusWhenVisible.mockClear();
      const event = new MouseEvent("click", {
        bubbles: true,
        cancelable: true,
      });
      document.querySelector("a").dispatchEvent(event);
      expect(event.defaultPrevented).toBe(true);
      expect(focusWhenVisible).not.toHaveBeenCalled();
    },
  );
  it("returns no focus target for null or DOM nodes without focus support", async () => {
    await mount();
    expect(controller.focusableElement(null)).toBeNull();
    expect(
      controller.focusableElement(document.createTextNode("text")),
    ).toBeNull();
    expect(
      controller.focusableElement(document.createElementNS("urn:test", "node")),
    ).toBeNull();
  });
  it("stops handling error-link clicks after removal", async () => {
    await mount('<input id="field">');
    const summary = document.querySelector("#summary");
    const link = summary.querySelector("a");
    summary.remove();
    await Promise.resolve();
    await Promise.resolve();
    focusWhenVisible.mockClear();
    link.dispatchEvent(
      new MouseEvent("click", { bubbles: true, cancelable: true }),
    );
    expect(focusWhenVisible).not.toHaveBeenCalled();
  });
});
