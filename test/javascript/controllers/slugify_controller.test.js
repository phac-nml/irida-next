import { afterEach, describe, expect, it } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import SlugifyController from "../../../app/javascript/controllers/slugify_controller.js";

describe("slugify controller", () => {
  let application, element, name, path;
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount() {
    document.body.innerHTML = `<div data-controller="slugify">
      <input data-slugify-target="name" data-action="input->slugify#nameChanged" placeholder="My Project" value="Existing name">
      <input data-slugify-target="path" value="custom-path">
    </div>`;
    element = document.body.firstElementChild;
    name = element.querySelector('[data-slugify-target="name"]');
    path = element.querySelector('[data-slugify-target="path"]');
    application = startApplication();
    application.register("slugify", SlugifyController);
    await Promise.resolve();
  }
  it("initializes the placeholder without overwriting an existing path", async () => {
    await mount();
    expect(path.placeholder).toBe("my-project");
    expect(path.value).toBe("custom-path");
    expect(element.dataset.controllerConnected).toBe("true");
  });
  it.each([
    ["  My New Project!  ", "my-new-project"],
    ["camelCase IRIDAProject", "camelcase-iridaproject"],
    ["Québec & Montréal", "quebec-and-montreal"],
    ["", ""],
    ["!!!", ""],
  ])("generates a path for %j", async (value, expected) => {
    await mount();
    name.value = value;
    name.dispatchEvent(new Event("input", { bubbles: true }));
    expect(path.value).toBe(expected);
  });
  it("preserves manual path edits across disconnect and reconnect", async () => {
    await mount();
    path.value = "my-manual-path";
    element.remove();
    await Promise.resolve();
    document.body.append(element);
    await Promise.resolve();
    expect(path.value).toBe("my-manual-path");
    name.value = "Changed name";
    name.dispatchEvent(new Event("input", { bubbles: true }));
    expect(path.value).toBe("changed-name");
  });
});
