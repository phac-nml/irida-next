import { startApplication, stopApplication } from "../helpers/stimulus.js";
import { Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import SelectionController from "../../../app/javascript/controllers/selection_controller.js";

const SELECTION_STORAGE_KEY = "selection-test-key";

class ActionButtonStubController extends Controller {
  setDisabled(count) {
    if (this.element.dataset.throwOnDisable === "true") {
      throw new Error("setDisabled failed");
    }

    this.element.dataset.disabledCount = String(count);
  }
}

async function startController(options = {}) {
  document.body.innerHTML = renderFixtureHtml(options);
  const application = startApplication();
  application.register("selection", SelectionController);
  application.register("action-button", ActionButtonStubController);
  await Promise.resolve();
  await new Promise((resolve) => requestAnimationFrame(resolve));
  return application;
}

function renderFixtureHtml({
  maxSelection = 2,
  limitMessage = "You cannot select more than %{max} items.",
  storageLimitMessage = "Browser storage is full.",
  countMessage = null,
  total = null,
  selectPageSome = null,
  includeStorageKey = true,
  includeSelectPageTarget = true,
  includeSelectPageStatusTarget = false,
  includeSelectedTarget = true,
  includeStatusTarget = true,
  includeLimitAlert = true,
  includeLimitAlertMessageTarget = true,
  includeLimitAlertStatusTarget = true,
  includeActionButtonOutlet = false,
  actionButtonThrows = false,
} = {}) {
  const rootAttributes = [
    'id="selection-table"',
    'data-controller="selection"',
    `data-selection-max-selection-value="${maxSelection}"`,
    `data-selection-limit-message-value="${limitMessage}"`,
    `data-selection-storage-limit-message-value="${storageLimitMessage}"`,
  ];

  if (includeStorageKey) {
    rootAttributes.push(
      `data-selection-storage-key-value="${SELECTION_STORAGE_KEY}"`,
    );
  }

  if (countMessage !== null) {
    rootAttributes.push(`data-selection-count-message-value="${countMessage}"`);
  }

  if (total !== null) {
    rootAttributes.push(`data-selection-total-value="${total}"`);
  }

  if (selectPageSome !== null) {
    rootAttributes.push(
      `data-selection-select-page-some-value="${selectPageSome}"`,
    );
  }

  if (includeActionButtonOutlet) {
    rootAttributes.push(
      'data-selection-action-button-outlet=".action-button-outlet"',
    );
  }

  const alertHtml = includeLimitAlert
    ? `
      <div
        id="selection-limit-alert"
        class="hidden"
        data-selection-target="limitAlert"
      >
        <div data-controller="viral--alert">
          ${
            includeLimitAlertMessageTarget
              ? '<span data-selection-target="limitAlertMessage">Alert</span>'
              : "<span>Alert</span>"
          }
        </div>
      </div>`
    : "";

  const statusHtml = includeStatusTarget
    ? '<span data-selection-target="status" class="sr-only" aria-live="polite"></span>'
    : "";

  const selectPageHtml = includeSelectPageTarget
    ? '<input type="checkbox" data-selection-target="selectPage" />'
    : "";

  const selectPageStatusHtml = includeSelectPageStatusTarget
    ? '<span id="select-page-status" data-selection-target="selectPageStatus"></span>'
    : "";

  const selectedHtml = includeSelectedTarget
    ? '<strong data-selection-target="selected">0</strong>'
    : "";

  const limitAlertStatusHtml = includeLimitAlertStatusTarget
    ? '<span data-selection-target="limitAlertStatus" class="sr-only" role="status" aria-live="assertive"></span>'
    : "";

  const actionButtonOutletHtml = includeActionButtonOutlet
    ? `<button
         type="button"
         class="action-button-outlet"
         data-controller="action-button"
         data-throw-on-disable="${actionButtonThrows ? "true" : "false"}"
       >
         Action
       </button>`
    : "";

  return `
    <div ${rootAttributes.join(" ")}>
      ${alertHtml}
      ${limitAlertStatusHtml}
      ${statusHtml}
      ${selectPageStatusHtml}
      ${selectPageHtml}
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
      ${selectedHtml}
      ${actionButtonOutletHtml}
    </div>
  `;
}

function controllerFor(application) {
  return application.getControllerForElementAndIdentifier(
    document.getElementById("selection-table"),
    "selection",
  );
}

async function nextFrame() {
  await new Promise((resolve) => requestAnimationFrame(resolve));
}

describe("selection controller", () => {
  let application;

  afterEach(async () => {
    await stopApplication(application);
    sessionStorage.clear();
  });

  it("rejects updates above the configured max selection", async () => {
    application = await startController();
    const controller = controllerFor(application);

    expect(controller).toBeDefined();
    expect(controller.hasSelectedTarget).toBe(true);
    expect(controller.maxSelectionValue).toBe(2);

    controller.update(["1", "2"], false);
    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe('["1","2"]');

    controller.update(["1", "2", "3"], false);

    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe('["1","2"]');
    expect(controller.hasLimitAlertTarget).toBe(true);
    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(
      false,
    );
  });

  it("clears a persisted selection above the configured max", async () => {
    sessionStorage.setItem(SELECTION_STORAGE_KEY, '["1","2","3"]');

    application = await startController();
    const controller = controllerFor(application);

    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe("[]");
    expect(controller.selectedTarget.textContent).toBe("0");
    expect(controller.rowSelectionTargets.every((row) => !row.checked)).toBe(
      true,
    );
    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(
      false,
    );
    await nextFrame();
    expect(
      document.querySelector('[data-selection-target="limitAlertStatus"]')
        .textContent,
    ).toBe("You cannot select more than 2 items.");
  });

  it("announces a rejected update only in the assertive limit region", async () => {
    application = await startController();
    const controller = controllerFor(application);

    controller.update(["1", "2", "3"]);
    await nextFrame();

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
    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe('["1","2","3"]');

    controller.togglePage({ target: { checked: false } });

    expect(controller.rowSelectionTargets.some((row) => row.checked)).toBe(
      false,
    );
    expect(controller.selectedTarget.textContent).toBe("0");
    expect(controller.selectPageTarget.checked).toBe(false);
    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe("[]");
  });

  it("restores the persisted selection after a Turbo morph", async () => {
    sessionStorage.setItem(SELECTION_STORAGE_KEY, '["2"]');

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
    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe('["1","2","3"]');
  });

  it("shift-click without an anchor toggles only the clicked row", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);
    const [, , row3] = controller.rowSelectionTargets;

    // No prior selection, so there is no stored anchor to build a range from
    row3.checked = true;
    controller.toggle({ target: row3, shiftKey: true });

    expect(controller.selectedTarget.textContent).toBe("1");
    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe('["3"]');
  });

  it("removes exact and paired values and supports helper methods", async () => {
    sessionStorage.setItem(
      SELECTION_STORAGE_KEY,
      '["abc-1","[\\"2\\",\\"3\\"]","{\\"nested\\":true}"]',
    );

    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);

    expect(controller.getStoredItemsCount()).toBe(3);

    controller.remove({ params: { id: "2" } });
    expect(JSON.parse(sessionStorage.getItem(SELECTION_STORAGE_KEY))).toEqual([
      "abc-1",
      '{"nested":true}',
    ]);

    controller.remove({ params: { id: "abc-1" } });
    expect(JSON.parse(sessionStorage.getItem(SELECTION_STORAGE_KEY))).toEqual([
      '{"nested":true}',
    ]);

    controller.clear();
    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe("[]");
    expect(controller.getStoredItemsCount()).toBe(0);
  });

  it("warns and ignores non-array update payloads", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);
    const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});

    controller.update("not-an-array");

    expect(warnSpy).toHaveBeenCalledWith(
      "SelectionController: ids must be an array",
    );
    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe("[]");
  });

  it("initializes storage when getOrCreateStoredItems cannot read an array", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);
    const storagePrototype = Object.getPrototypeOf(window.sessionStorage);
    const getItemSpy = vi
      .spyOn(storagePrototype, "getItem")
      .mockReturnValue('{"ids":["1"]}');
    const updateSpy = vi.spyOn(controller, "update");

    expect(controller.getOrCreateStoredItems()).toEqual([]);
    expect(updateSpy).toHaveBeenCalledWith([], false);

    getItemSpy.mockRestore();
  });

  it("falls back to a single-row toggle when shift anchor is stale", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);
    const [row1, , row3] = controller.rowSelectionTargets;

    row1.checked = true;
    controller.toggle({ target: row1, shiftKey: false });

    row1.id = "renamed-anchor";
    row3.checked = true;
    controller.toggle({ target: row3, shiftKey: true });

    expect(controller.selectedTarget.textContent).toBe("2");
    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe('["1","3"]');
  });

  it("defensively handles an empty calculated shift range", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);
    const [row1, , row3] = controller.rowSelectionTargets;
    const minSpy = vi.spyOn(Math, "min").mockReturnValue(2);
    const maxSpy = vi.spyOn(Math, "max").mockReturnValue(1);

    row1.checked = true;
    controller.toggle({ target: row1, shiftKey: false });

    row3.checked = true;
    controller.toggle({ target: row3, shiftKey: true });

    expect(controller.selectedTarget.textContent).toBe("1");
    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe('["1"]');

    minSpy.mockRestore();
    maxSpy.mockRestore();
  });

  it("unregisters the turbo:morph listener on disconnect", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);
    const removeSpy = vi.spyOn(document, "removeEventListener");

    controller.disconnect();

    expect(removeSpy).toHaveBeenCalledWith(
      "turbo:morph",
      controller.boundOnMorph,
    );
  });

  it("passes selected counts to action-button outlets", async () => {
    application = await startController({
      maxSelection: 5,
      includeActionButtonOutlet: true,
    });
    const controller = controllerFor(application);

    controller.update(["1", "2"], false);

    expect(
      document.querySelector(".action-button-outlet").dataset.disabledCount,
    ).toBe("2");
  });

  it("skips outlet updates when outlets are not available", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);

    Object.defineProperty(controller, "actionButtonOutlets", {
      configurable: true,
      value: undefined,
    });

    controller.update(["1"], false);

    expect(controller.selectedTarget.textContent).toBe("1");
  });

  it("logs update failures instead of crashing when outlet work throws", async () => {
    application = await startController({
      maxSelection: 5,
      includeActionButtonOutlet: true,
      actionButtonThrows: true,
    });
    const controller = controllerFor(application);
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    controller.update(["1"], false);

    expect(errorSpy).toHaveBeenCalledWith(
      "selectionController: Failed to update UI",
      expect.any(Error),
    );
  });

  it("updates select-page status text and mixed-state description", async () => {
    application = await startController({
      maxSelection: 5,
      includeSelectPageStatusTarget: true,
      selectPageSome: "%{selected} of %{total} selected",
    });
    const controller = controllerFor(application);

    controller.update(["1"], false);

    expect(controller.selectPageStatusTarget.textContent).toBe(
      "1 of 3 selected",
    );
    expect(controller.selectPageTarget.getAttribute("aria-describedby")).toBe(
      "select-page-status",
    );

    controller.update(["1", "2", "3"], false);

    expect(controller.selectPageTarget.checked).toBe(true);
    expect(controller.selectPageStatusTarget.textContent).toBe("");
    expect(
      controller.selectPageTarget.getAttribute("aria-describedby"),
    ).toBeNull();
  });

  it("handles updates when select-page and selected targets are absent", async () => {
    application = await startController({
      maxSelection: 5,
      includeSelectPageTarget: false,
      includeSelectedTarget: false,
    });
    const controller = controllerFor(application);

    controller.update(["1"], false);

    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe('["1"]');
  });

  it("announces selection status in local and global live regions", async () => {
    application = await startController({
      maxSelection: 5,
      countMessage: "Selected %{selected} of %{total}",
      total: 3,
    });
    const controller = controllerFor(application);

    controller.update(["1"], true);
    await nextFrame();

    expect(controller.statusTarget.textContent).toBe("Selected 1 of 3");

    await stopApplication(application);
    application = await startController({
      maxSelection: 5,
      countMessage: "Selected %{selected} of %{total}",
      includeStatusTarget: false,
    });

    controllerFor(application).update(["1"], true);
    await nextFrame();

    expect(document.getElementById("sr-status").textContent).toBe(
      "Selected 1 of 0",
    );
  });

  it("warns on malformed stored JSON and resets persisted state", async () => {
    sessionStorage.setItem(SELECTION_STORAGE_KEY, "not-json");
    const warnSpy = vi.spyOn(console, "warn").mockImplementation(() => {});

    application = await startController({ maxSelection: 5 });

    expect(warnSpy).toHaveBeenCalledWith(
      "Failed to parse stored selection items:",
      expect.anything(),
    );
    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe("[]");
  });

  it("rethrows non-quota storage errors", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);
    const storagePrototype = Object.getPrototypeOf(window.sessionStorage);
    const setItemSpy = vi
      .spyOn(storagePrototype, "setItem")
      .mockImplementation(() => {
        throw new Error("write failed");
      });

    expect(() => controller.update(["1"], false)).toThrow("write failed");

    setItemSpy.mockRestore();
  });

  it("treats numeric and string quota codes as quota exceeded", async () => {
    application = await startController({ maxSelection: 5 });
    const controller = controllerFor(application);
    const storagePrototype = Object.getPrototypeOf(window.sessionStorage);
    const setItemSpy = vi
      .spyOn(storagePrototype, "setItem")
      .mockImplementationOnce(() => {
        throw { code: 22 };
      })
      .mockImplementationOnce(() => {
        throw { code: "QuotaExceededError" };
      });

    controller.update(["1"], false);
    expect(controller.limitAlertMessageTarget.textContent).toBe(
      "Browser storage is full.",
    );

    controller.update(["2"], false);
    expect(controller.limitAlertMessageTarget.textContent).toBe(
      "Browser storage is full.",
    );

    setItemSpy.mockRestore();
  });

  it("uses fallback key and fallback storage-limit message", async () => {
    application = await startController({
      maxSelection: 5,
      includeStorageKey: false,
      limitMessage: "Max %{max}",
      storageLimitMessage: "",
    });
    const controller = controllerFor(application);
    const fallbackKey = `${location.protocol}//${location.host}${location.pathname}`;

    controller.update(["1"], false);
    expect(sessionStorage.getItem(fallbackKey)).toBe('["1"]');

    const storagePrototype = Object.getPrototypeOf(window.sessionStorage);
    const setItemSpy = vi
      .spyOn(storagePrototype, "setItem")
      .mockImplementation(() => {
        throw { code: 22 };
      });

    controller.update(["2"], false);

    expect(controller.limitAlertMessageTarget.textContent).toBe("Max 5");

    setItemSpy.mockRestore();
  });

  it("returns early when no storage-limit message is available", async () => {
    application = await startController({
      maxSelection: 5,
      limitMessage: "",
      storageLimitMessage: "",
    });
    const controller = controllerFor(application);
    const storagePrototype = Object.getPrototypeOf(window.sessionStorage);
    const setItemSpy = vi
      .spyOn(storagePrototype, "setItem")
      .mockImplementation(() => {
        throw { code: 22 };
      });

    controller.update(["1"], false);

    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(true);

    setItemSpy.mockRestore();
  });

  it("refreshes UI from empty storage when limit rejection reads a non-array", async () => {
    application = await startController({ maxSelection: 1 });
    const controller = controllerFor(application);
    const storagePrototype = Object.getPrototypeOf(window.sessionStorage);

    controller.update(["1"], false);
    expect(controller.selectedTarget.textContent).toBe("1");

    const getItemSpy = vi
      .spyOn(storagePrototype, "getItem")
      .mockReturnValue('{"ids":["1"]}');

    controller.update(["1", "2"], false);

    expect(controller.selectedTarget.textContent).toBe("0");
    expect(controller.rowSelectionTargets.every((row) => !row.checked)).toBe(
      true,
    );

    getItemSpy.mockRestore();
  });

  it("handles missing limit alert targets without throwing", async () => {
    application = await startController({
      maxSelection: 1,
      includeLimitAlert: false,
      includeLimitAlertStatusTarget: false,
    });
    const controller = controllerFor(application);

    controller.update(["1", "2"], false);
    controller.update(["1"], false);

    expect(sessionStorage.getItem(SELECTION_STORAGE_KEY)).toBe('["1"]');
  });

  it("does not announce when limit messages are blank", async () => {
    application = await startController({
      maxSelection: 1,
      limitMessage: "",
      storageLimitMessage: "",
      includeLimitAlertStatusTarget: false,
    });
    const controller = controllerFor(application);

    controller.update(["1", "2"], false);
    await nextFrame();

    expect(document.getElementById("sr-status")).toBeNull();
  });

  it("falls back to assertive global live region when alert status target is missing", async () => {
    application = await startController({
      maxSelection: 1,
      includeLimitAlertStatusTarget: false,
    });
    const controller = controllerFor(application);

    controller.update(["1", "2"], false);
    await nextFrame();

    const globalRegion = document.getElementById("sr-status");
    expect(globalRegion.textContent).toBe(
      "You cannot select more than 1 items.",
    );
    expect(globalRegion.getAttribute("aria-live")).toBe("assertive");
  });
});
