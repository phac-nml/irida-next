import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  clearProgressWindowDismissTimeout,
  dismissProgressWindow,
  scheduleProgressWindowDismiss,
  showProgressWindow,
  updateProgressWindow,
} from "../../../app/javascript/utilities/progress_window.js";

const buildController = (overrides = {}) => ({
  identifier: "samples",
  _operationId: "abc123",
  minimumVisibleDurationMsValue: 1000,
  progressWindowDismissed: false,
  _progressWindowOpenedAt: null,
  hasProgressTemplateTarget: false,
  ...overrides,
});

beforeEach(() => {
  document.body.innerHTML = "";
  vi.useFakeTimers();
});

afterEach(() => {
  vi.runOnlyPendingTimers();
  vi.useRealTimers();
  document.body.innerHTML = "";
});

describe("progress window utilities", () => {
  it("returns early when the progress window has already been dismissed", () => {
    const controller = buildController({ progressWindowDismissed: true });

    expect(() => updateProgressWindow(controller, "Done", 50)).not.toThrow();
    expect(clearProgressWindowDismissTimeout(controller)).toBeUndefined();
  });

  it("clamps the progress value and updates the message, bar, and percentage", () => {
    const controller = buildController();
    controller._progressMsgEl = document.createElement("div");
    controller._progressBarEl = document.createElement("div");
    controller._progressPctEl = document.createElement("span");

    updateProgressWindow(controller, "Uploading", 150, true);

    expect(controller._progressMsgEl.textContent).toBe("Uploading");
    expect(controller._progressMsgEl.getAttribute("role")).toBe("alert");
    expect(controller._progressMsgEl.hasAttribute("aria-live")).toBe(false);
    expect(controller._progressBarEl.style.width).toBe("100%");
    expect(controller._progressBarEl.getAttribute("aria-valuenow")).toBe("100");
    expect(controller._progressBarEl.getAttribute("aria-label")).toBe(
      "Uploading",
    );
    expect(controller._progressBarEl.classList.contains("bg-red-600")).toBe(
      true,
    );
    expect(controller._progressBarEl.classList.contains("bg-primary-600")).toBe(
      false,
    );
    expect(controller._progressPctEl.textContent).toBe("100%");
  });

  it("creates a progress card when needed and tracks the open timestamp", () => {
    const template = document.createElement("template");
    template.innerHTML = `
      <div>
        <span data-samples-progress-message>Initial</span>
        <div data-samples-progress-bar></div>
        <span data-samples-progress-percent></span>
      </div>
    `;

    const controller = buildController({
      hasProgressTemplateTarget: true,
      progressTemplateTarget: template,
    });

    showProgressWindow(controller, "Starting");

    expect(controller._progressWindowOpenedAt).not.toBeNull();
    expect(controller._progressMsgEl.textContent).toBe("Starting");
    expect(controller._progressBarEl.style.width).toBe("0%");
    expect(document.getElementById("samples-progress-window")).not.toBeNull();
    expect(document.getElementById("samples-card-abc123")).not.toBeNull();
  });

  it("reuses an existing card and restores refs after a Turbo reconnect", () => {
    const card = document.createElement("div");
    card.id = "samples-card-abc123";
    card.innerHTML = `
      <span data-samples-progress-message></span>
      <div data-samples-progress-bar></div>
      <span data-samples-progress-percent></span>
    `;
    document.body.appendChild(card);

    const controller = buildController({
      _progressMsgEl: null,
      _progressBarEl: null,
      _progressPctEl: null,
    });

    updateProgressWindow(controller, "Recovered", 40);

    expect(controller._progressMsgEl).toBe(
      card.querySelector("[data-samples-progress-message]"),
    );
    expect(controller._progressBarEl).toBe(
      card.querySelector("[data-samples-progress-bar]"),
    );
    expect(controller._progressPctEl).toBe(
      card.querySelector("[data-samples-progress-percent]"),
    );
  });

  it("ignores unrelated clicks but dismisses on the dismiss target", () => {
    const template = document.createElement("template");
    template.innerHTML = `
      <div>
        <span data-samples-progress-message>Working</span>
        <div data-samples-progress-bar></div>
        <span data-samples-progress-percent></span>
        <button type="button" data-samples-dismiss="true">Dismiss</button>
      </div>
    `;

    const controller = buildController({
      hasProgressTemplateTarget: true,
      progressTemplateTarget: template,
    });

    showProgressWindow(controller, "Working");
    const otherNode = document.querySelector("[data-samples-progress-message]");
    const dismissButton = document.querySelector(
      '[data-samples-dismiss="true"]',
    );

    otherNode.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(controller.progressWindowDismissed).toBe(false);

    dismissButton.dispatchEvent(new MouseEvent("click", { bubbles: true }));
    expect(controller.progressWindowDismissed).toBe(true);
  });

  it("returns early when no operation id is present", () => {
    const controller = buildController({ _operationId: null });

    expect(() => updateProgressWindow(controller, "No card", 30)).not.toThrow();
  });

  it("preserves an existing open time and dismisses without an operation id", () => {
    const controller = buildController({
      _progressWindowOpenedAt: 12345,
      _operationId: null,
    });
    const container = document.createElement("div");
    container.id = "samples-progress-window";
    document.body.appendChild(container);

    showProgressWindow(controller, "Existing");

    expect(controller._progressWindowOpenedAt).toBe(12345);

    dismissProgressWindow(controller);

    expect(controller.progressWindowDismissed).toBe(true);
    expect(document.getElementById("samples-progress-window")).toBeNull();
  });

  it("schedules and clears the dismissal timeout", () => {
    const controller = buildController({
      _progressWindowOpenedAt: Date.now() - 50,
      _dismissProgressWindowTimeout: null,
    });
    const setTimeoutSpy = vi.spyOn(globalThis, "setTimeout");

    scheduleProgressWindowDismiss(controller);
    expect(setTimeoutSpy).toHaveBeenCalledTimes(1);
    expect(controller._dismissProgressWindowTimeout).not.toBeNull();

    vi.advanceTimersByTime(1000);
    expect(controller.progressWindowDismissed).toBe(true);

    clearProgressWindowDismissTimeout(controller);
    expect(controller._dismissProgressWindowTimeout).toBeNull();

    setTimeoutSpy.mockRestore();
  });

  it("clamps the dismissal timeout to zero after the minimum visible time has elapsed", () => {
    const controller = buildController({
      _progressWindowOpenedAt: Date.now() - 1500,
      _dismissProgressWindowTimeout: null,
    });

    scheduleProgressWindowDismiss(controller);

    expect(controller._dismissProgressWindowTimeout).toBeDefined();
    vi.advanceTimersByTime(0);
    expect(controller.progressWindowDismissed).toBe(true);
  });

  it("removes the progress card and clears controller state when dismissed", () => {
    const controller = buildController({
      _progressMsgEl: document.createElement("div"),
      _progressBarEl: document.createElement("div"),
      _progressPctEl: document.createElement("span"),
      _dismissProgressWindowTimeout: 123,
    });

    const container = document.createElement("div");
    container.id = "samples-progress-window";
    const card = document.createElement("div");
    card.id = "samples-card-abc123";
    container.appendChild(card);
    document.body.appendChild(container);

    dismissProgressWindow(controller);

    expect(document.getElementById("samples-card-abc123")).toBeNull();
    expect(document.getElementById("samples-progress-window")).toBeNull();
    expect(controller.progressWindowDismissed).toBe(true);
    expect(controller._progressMsgEl).toBeNull();
    expect(controller._progressBarEl).toBeNull();
    expect(controller._progressPctEl).toBeNull();
    expect(controller._dismissProgressWindowTimeout).toBeNull();
  });
});
