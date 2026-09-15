import { afterEach, describe, expect, it } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import SpinnerController from "../../../app/javascript/controllers/spinner_controller.js";

describe("spinner controller", () => {
  let application, form, closeButton, spinner;
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount() {
    document.body.innerHTML = `<form data-controller="spinner" data-action="turbo:submit-start->spinner#submitStart turbo:submit-end->spinner#submitEnd">
      <button type="button" class="dialog--close">Close</button><div id="spinner" class="hidden"></div>
    </form>`;
    form = document.querySelector("form");
    closeButton = document.querySelector("button");
    spinner = document.querySelector("#spinner");
    application = startApplication();
    application.register("spinner", SpinnerController);
    await Promise.resolve();
  }
  function key(key) {
    const event = new KeyboardEvent("keydown", {
      key,
      bubbles: true,
      cancelable: true,
    });
    document.body.dispatchEvent(event);
    return event;
  }
  it("shows progress and blocks only Escape during submission", async () => {
    await mount();
    form.dispatchEvent(new Event("turbo:submit-start"));
    expect(closeButton.classList.contains("hidden")).toBe(true);
    expect(spinner.classList.contains("hidden")).toBe(false);
    expect(key("Escape").defaultPrevented).toBe(true);
    expect(key("Enter").defaultPrevented).toBe(false);
    form.dispatchEvent(new Event("turbo:submit-end"));
    expect(closeButton.classList.contains("hidden")).toBe(false);
    expect(spinner.classList.contains("hidden")).toBe(true);
    expect(key("Escape").defaultPrevented).toBe(false);
  });
  it("restores Escape when a submitting form is removed without submit-end", async () => {
    await mount();
    form.dispatchEvent(new Event("turbo:submit-start"));
    form.remove();
    await Promise.resolve();
    expect(key("Escape").defaultPrevented).toBe(false);
    document.body.append(form);
    await Promise.resolve();
    form.dispatchEvent(new Event("turbo:submit-start"));
    expect(key("Escape").defaultPrevented).toBe(true);
    form.dispatchEvent(new Event("turbo:submit-end"));
  });
});
