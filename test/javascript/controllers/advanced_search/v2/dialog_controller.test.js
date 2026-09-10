import { Application } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import DialogController from "../../../../../app/javascript/controllers/advanced_search/v2/dialog_controller.js";

function renderFixture() {
  document.body.innerHTML = `
    <div
      data-controller="advanced-search--v2--dialog"
      data-advanced-search--v2--dialog-status-value="true"
      data-advanced-search--v2--dialog-has-errors-value="false"
      data-advanced-search--v2--dialog-confirm-close-text-value="Discard changes?"
    ></div>
  `;
}

async function startController() {
  const application = Application.start();
  application.register("advanced-search--v2--dialog", DialogController);
  await Promise.resolve();
  return application;
}

describe("advanced-search--v2--dialog", () => {
  let application;

  beforeEach(() => {
    renderFixture();
  });

  afterEach(() => {
    application?.stop();
    document.body.innerHTML = "";
  });

  it("prevents a keyboard close event before dirty-state checks", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller='advanced-search--v2--dialog']"),
      "advanced-search--v2--dialog",
    );

    const event = new KeyboardEvent("keydown", {
      bubbles: true,
      cancelable: true,
    });
    controller.close(event);

    expect(event.defaultPrevented).toBe(true);
  });
});
