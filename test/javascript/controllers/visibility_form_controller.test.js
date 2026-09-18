import { afterEach, describe, expect, it } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import VisibilityFormController from "../../../app/javascript/controllers/visibility_form_controller.js";

describe("visibility form controller", () => {
  let application, form, submit;
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount({ current = "false", selected = current } = {}) {
    document.body.innerHTML = `<form data-controller="visibility-form" data-visibility-form-current-value="${current}" data-action="submit->visibility-form#updateConfirmationWarning">
      <input type="radio" name="group[public]" value="false" data-visibility-form-target="visibility" data-action="change->visibility-form#update">
      <input type="radio" name="group[public]" value="true" data-visibility-form-target="visibility" data-action="change->visibility-form#update">
      <span data-visibility-form-target="publicWarning">Public warning</span>
      <span class="hidden" data-visibility-form-target="privateWarning">Private warning</span>
      <button type="submit" disabled data-visibility-form-target="submit">Save</button>
    </form>`;
    form = document.querySelector("form");
    submit = form.querySelector("button");
    if (selected !== null)
      form.querySelector(`[value="${selected}"]`).checked = true;
    application = startApplication();
    application.register("visibility-form", VisibilityFormController);
    await Promise.resolve();
  }
  function expectPublicWarning(publicSelected) {
    expect(
      form
        .querySelector('[data-visibility-form-target="publicWarning"]')
        .classList.contains("hidden"),
    ).toBe(!publicSelected);
    expect(
      form
        .querySelector('[data-visibility-form-target="privateWarning"]')
        .classList.contains("hidden"),
    ).toBe(publicSelected);
  }
  function change(value) {
    const radio = form.querySelector(`[value="${value}"]`);
    radio.checked = true;
    radio.dispatchEvent(new Event("change", { bubbles: true }));
  }
  it.each(["true", "false"])(
    "shows the warning matching initial visibility %s",
    async (current) => {
      await mount({ current });
      expectPublicWarning(current === "true");
      expect(submit.disabled).toBe(true);
    },
  );
  it.each([
    ["true", "false"],
    ["false", "true"],
  ])(
    "enables changes from %s to %s and disables reverting",
    async (current, other) => {
      await mount({ current });
      change(other);
      expect(submit.disabled).toBe(false);
      expectPublicWarning(other === "true");
      change(current);
      expect(submit.disabled).toBe(true);
      expectPublicWarning(current === "true");
    },
  );
  it("falls back to the private warning when no radio is selected", async () => {
    await mount({ selected: null });
    expectPublicWarning(false);
  });
  it("refreshes confirmation text from the current selection at submission", async () => {
    await mount();
    form.querySelector('[value="true"]').checked = true;
    form.dispatchEvent(
      new Event("submit", { bubbles: true, cancelable: true }),
    );
    expectPublicWarning(true);
  });
  it("restores warning state on reconnect and resumes handling changes", async () => {
    await mount();
    form.remove();
    await Promise.resolve();
    form.querySelector('[value="true"]').checked = true;
    document.body.append(form);
    await Promise.resolve();
    expectPublicWarning(true);
    change("false");
    expectPublicWarning(false);
    expect(submit.disabled).toBe(true);
  });
});
