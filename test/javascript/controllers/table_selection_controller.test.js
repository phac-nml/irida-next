import { startApplication, stopApplication } from "../helpers/stimulus.js";
import { Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import TableSelectionController from "../../../app/javascript/controllers/table_selection_controller.js";

class SelectionOutletStubController extends Controller {
  update(ids) {
    this.element.dataset.updatedIds = JSON.stringify(ids);
  }
}

async function startController({ ids = ["sample-1", "sample-2"] } = {}) {
  document.body.innerHTML = `
    <div id="samples-table" data-controller="selection"></div>

    <div
      id="table-selection-root"
      data-controller="table-selection"
      data-table-selection-ids-value='${JSON.stringify(ids)}'
      data-table-selection-selection-outlet="#samples-table"
    ></div>
  `;

  const application = startApplication();
  application.register("table-selection", TableSelectionController);
  application.register("selection", SelectionOutletStubController);

  await Promise.resolve();
  await new Promise((resolve) => requestAnimationFrame(resolve));

  return application;
}

function controllerFor(application) {
  return application.getControllerForElementAndIdentifier(
    document.getElementById("table-selection-root"),
    "table-selection",
  );
}

describe("table selection controller", () => {
  let application;

  afterEach(async () => {
    await stopApplication(application);
  });

  it("pushes ids into the selection outlet on connect", async () => {
    application = await startController({ ids: ["1", "2", "3"] });

    expect(document.getElementById("samples-table").dataset.updatedIds).toBe(
      '["1","2","3"]',
    );
  });

  it("calls selection outlet update with an empty array", async () => {
    application = await startController({ ids: [] });

    expect(document.getElementById("samples-table").dataset.updatedIds).toBe(
      "[]",
    );
  });

  it("passes the exact idsValue reference to outlet update", async () => {
    application = await startController({ ids: ["alpha"] });
    const controller = controllerFor(application);
    const updateSpy = vi.spyOn(controller.selectionOutlet, "update");

    controller.connect();

    expect(updateSpy).toHaveBeenCalledWith(controller.idsValue);
  });
});
