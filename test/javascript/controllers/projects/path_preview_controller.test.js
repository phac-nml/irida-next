import { afterEach, describe, expect, it } from "vitest";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";
import PathPreviewController from "../../../../app/javascript/controllers/projects/path_preview_controller.js";

describe("projects path preview controller", () => {
  let application;

  async function mount(value = "outbreak") {
    document.body.innerHTML = `
      <form data-controller="projects--path-preview">
        <input
          value="${value}"
          data-projects--path-preview-target="input"
          data-action="input->projects--path-preview#update"
        >
        <strong data-projects--path-preview-target="path">server-value</strong>
      </form>`;
    application = startApplication();
    application.register("projects--path-preview", PathPreviewController);
    await new Promise((resolve) => setTimeout(resolve, 0));
  }

  const input = () => document.querySelector("input");
  const preview = () => document.querySelector("strong");

  afterEach(async () => {
    await stopApplication(application);
    document.body.innerHTML = "";
  });

  it("syncs on connect so restored form values are reflected", async () => {
    await mount("restored-path");

    expect(preview().textContent).toBe("restored-path");
  });

  it("updates the preview as the path changes", async () => {
    await mount();

    input().value = "new-path";
    input().dispatchEvent(new Event("input", { bubbles: true }));

    expect(preview().textContent).toBe("new-path");
  });

  it("renders markup in the path as text", async () => {
    await mount();

    input().value = "<img src=x>";
    input().dispatchEvent(new Event("input", { bubbles: true }));

    expect(preview().textContent).toBe("<img src=x>");
    expect(preview().querySelector("img")).toBeNull();
  });
});
