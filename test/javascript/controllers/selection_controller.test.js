import { Application } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import SelectionController from "../../../app/javascript/controllers/selection_controller.js";

async function startController() {
  document.body.innerHTML = renderFixtureHtml();
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
  proactiveAlert = false,
} = {}) {
  const alertHtml = `
      <div
        id="selection-limit-alert"
        class="${proactiveAlert ? "" : "hidden"}"
        data-selection-target="limitAlert"
        ${proactiveAlert ? 'data-selection-limit-proactive="true"' : ""}
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
      <span data-selection-target="status" class="sr-only" aria-live="polite"></span>
      <input
        type="checkbox"
        value="1"
        data-selection-target="rowSelection"
      />
      <input
        type="checkbox"
        value="2"
        data-selection-target="rowSelection"
      />
      <input
        type="checkbox"
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

  it("keeps a proactive alert visible after a successful update", async () => {
    document.body.innerHTML = renderFixtureHtml({ proactiveAlert: true });
    application = Application.start();
    application.register("selection", SelectionController);
    await Promise.resolve();
    await new Promise((resolve) => requestAnimationFrame(resolve));
    const controller = controllerFor(application);

    controller.update(["1"], false);

    expect(
      document
        .getElementById("selection-limit-alert")
        .classList.contains("hidden"),
    ).toBe(false);
  });

  it("does not re-show a dismissed alert after pagination morph", async () => {
    application = await startController();
    const controller = controllerFor(application);

    controller.update(["1", "2", "3"], false);
    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(
      false,
    );

    controller.limitAlertTarget
      .querySelector("[data-controller='viral--alert']")
      .dispatchEvent(
        new CustomEvent("viral--alert:dismissed", { bubbles: true }),
      );

    expect(
      sessionStorage.getItem(
        "selection-test-key:selection-limit-alert-dismissed",
      ),
    ).toBe("true");
    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(true);

    controller.onMorph();

    expect(controller.limitAlertTarget.classList.contains("hidden")).toBe(true);
  });

  it("keeps a dismissed proactive alert hidden after pagination morph", async () => {
    document.body.innerHTML = renderFixtureHtml({ proactiveAlert: true });
    application = Application.start();
    application.register("selection", SelectionController);
    await Promise.resolve();
    await new Promise((resolve) => requestAnimationFrame(resolve));
    const controller = controllerFor(application);
    const alert = document.getElementById("selection-limit-alert");

    expect(alert.classList.contains("hidden")).toBe(false);

    alert
      .querySelector("[data-controller='viral--alert']")
      .dispatchEvent(
        new CustomEvent("viral--alert:dismissed", { bubbles: true }),
      );

    expect(
      sessionStorage.getItem(
        "selection-test-key:selection-limit-alert-dismissed",
      ),
    ).toBe("true");
    expect(alert.classList.contains("hidden")).toBe(true);

    // Turbo morph replaces server-rendered alert markup without the dismissed class.
    alert.outerHTML = `
      <div
        id="selection-limit-alert"
        class="mb-4"
        role="alert"
        data-selection-target="limitAlert"
        data-selection-limit-proactive="true"
      >
        <div data-controller="viral--alert">
          <span data-selection-target="limitAlertMessage">Alert</span>
        </div>
      </div>`;

    controller.onMorph();

    expect(
      document
        .getElementById("selection-limit-alert")
        .classList.contains("hidden"),
    ).toBe(true);
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
});
