import { Application } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import SelectionController from "../../../app/javascript/controllers/selection_controller.js";

async function startController(options = {}) {
  document.body.innerHTML = renderFixtureHtml(options);
  const application = Application.start();
  application.register("selection", SelectionController);
  await Promise.resolve();
  await new Promise((resolve) => requestAnimationFrame(resolve));
  return application;
}

function renderFixtureHtml({
  maxSelection = 2,
  limitMessage = "You cannot select more than %{max} items.",
  storageLimitMessage = "Browser storage is full.",
} = {}) {
  const alertHtml = `
      <div
        id="selection-limit-alert"
        class="hidden"
        data-selection-target="limitAlert"
      >
        <div data-controller="viral--alert">
          <span data-selection-target="limitAlertMessage">Alert</span>
        </div>
      </div>`;

  return `
    <div
      id="selection-table"
      data-controller="selection"
      data-selection-storage-key-value="selection-test-key"
      data-selection-max-selection-value="${maxSelection}"
      data-selection-limit-message-value="${limitMessage}"
      data-selection-storage-limit-message-value="${storageLimitMessage}"
    >
      ${alertHtml}
      <span
        data-selection-target="limitAlertStatus"
        class="sr-only"
        role="status"
        aria-live="assertive"
      ></span>
      <span data-selection-target="status" class="sr-only" aria-live="polite"></span>
      <input
        type="checkbox"
        data-selection-target="selectPage"
      />
      <input
        type="checkbox"
        id="checkbox_1"
        value="1"
        data-selection-target="rowSelection"
      />
      <input
        type="checkbox"
        id="checkbox_2"
        value="2"
        data-selection-target="rowSelection"
      />
      <input
        type="checkbox"
        id="checkbox_3"
        value="3"
        data-selection-target="rowSelection"
      />
      <strong data-selection-target="selected">0</strong>
    </div>
  `;
}

function controllerFor(application) {
  return application.getControllerForElementAndIdentifier(
    document.getElementById("selection-table"),
    "selection",
  );
}

describe("selection controller", () => {
  let application;

  afterEach(() => {
    application?.stop();
    sessionStorage.clear();
  });

  it("rejects updates above the configured max selection", async () => {
    application = await startController();
    const controller = controllerFor(application);

    expect(controller).toBeDefined();
    expect(controller.hasSelectedTarget).toBe(true);
    expect(controller.maxSelectionValue).toBe(2);

    controller.update(["1", "2"], false);
    expect(sessionStorage.getItem("selection-test-key")).toBe('["1","2"]');

    controller.update(["1", "2", "3"], false);

    expect(sessionStorage.getItem("selection-test-key")).toBe('["1","2"]');
    expect(controller.hasLimitAlertTarget).toBe(true);
    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(
      false,
    );
  });

  it("clears a persisted selection above the configured max", async () => {
    sessionStorage.setItem("selection-test-key", '["1","2","3"]');

    application = await startController();
    const controller = controllerFor(application);

    expect(sessionStorage.getItem("selection-test-key")).toBe("[]");
    expect(controller.selectedTarget.textContent).toBe("0");
    expect(controller.rowSelectionTargets.every((row) => !row.checked)).toBe(
      true,
    );
    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(
      false,
    );
    await new Promise((resolve) => requestAnimationFrame(resolve));
    expect(
      document.querySelector('[data-selection-target="limitAlertStatus"]')
        .textContent,
    ).toBe("You cannot select more than 2 items.");
  });

  it("announces a rejected update only in the assertive limit region", async () => {
    application = await startController();
    const controller = controllerFor(application);

    controller.update(["1", "2", "3"]);
    await new Promise((resolve) => requestAnimationFrame(resolve));

    expect(
      document.querySelector('[data-selection-target="limitAlertStatus"]')
        .textContent,
    ).toBe("You cannot select more than 2 items.");
    expect(controller.statusTarget.textContent).toBe("");
  });

  it("hides the reactive limit alert after a successful update", async () => {
    application = await startController();
    const controller = controllerFor(application);

    controller.update(["1", "2", "3"], false);
    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(
      false,
    );

    controller.update(["1"], false);

    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(true);
  });

  it("shows storage-specific feedback when session storage quota is exceeded", async () => {
    application = await startController();
    const controller = controllerFor(application);
    const storagePrototype = Object.getPrototypeOf(window.sessionStorage);
    const setItemSpy = vi
      .spyOn(storagePrototype, "setItem")
      .mockImplementation(() => {
        const error = new DOMException("quota", "QuotaExceededError");
        throw error;
      });

    controller.update(["1"], false);

    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(
      false,
    );
    expect(controller.limitAlertMessageTarget.textContent).toBe(
      "Browser storage is full.",
    );

    setItemSpy.mockRestore();
  });

  it("selects and deselects every row on the page via the page checkbox", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);

    controller.togglePage({ target: { checked: true } });

    expect(controller.rowSelectionTargets.every((row) => row.checked)).toBe(
      true,
    );
    expect(controller.selectedTarget.textContent).toBe("3");
    expect(controller.selectPageTarget.checked).toBe(true);
    expect(sessionStorage.getItem("selection-test-key")).toBe('["1","2","3"]');

    controller.togglePage({ target: { checked: false } });

    expect(controller.rowSelectionTargets.some((row) => row.checked)).toBe(
      false,
    );
    expect(controller.selectedTarget.textContent).toBe("0");
    expect(controller.selectPageTarget.checked).toBe(false);
    expect(sessionStorage.getItem("selection-test-key")).toBe("[]");
  });

  it("restores the persisted selection after a Turbo morph", async () => {
    sessionStorage.setItem("selection-test-key", '["2"]');

    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);

    const persistedRow = controller.rowSelectionTargets.find(
      (row) => row.value === "2",
    );
    expect(persistedRow.checked).toBe(true);

    // Simulate a partial page replacement clearing the checkbox state
    persistedRow.checked = false;
    document.dispatchEvent(new Event("turbo:morph"));

    expect(persistedRow.checked).toBe(true);
    expect(controller.selectedTarget.textContent).toBe("1");
  });

  it("selects a contiguous range on shift-click", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);
    const [row1, , row3] = controller.rowSelectionTargets;

    // First click establishes the range anchor
    row1.checked = true;
    controller.toggle({ target: row1, shiftKey: false });

    // Shift-click the third row selects every row between the anchor and target
    row3.checked = true;
    controller.toggle({ target: row3, shiftKey: true });

    expect(controller.rowSelectionTargets.every((row) => row.checked)).toBe(
      true,
    );
    expect(controller.selectedTarget.textContent).toBe("3");
    expect(sessionStorage.getItem("selection-test-key")).toBe('["1","2","3"]');
  });

  it("shift-click without an anchor toggles only the clicked row", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);
    const [, , row3] = controller.rowSelectionTargets;

    // No prior selection, so there is no stored anchor to build a range from
    row3.checked = true;
    controller.toggle({ target: row3, shiftKey: true });

    expect(controller.selectedTarget.textContent).toBe("1");
    expect(sessionStorage.getItem("selection-test-key")).toBe('["3"]');
  });
});
