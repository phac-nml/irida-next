import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  clearProgressWindowDismissTimeout,
  dismissProgressWindow,
  scheduleProgressWindowDismiss,
  showProgressWindow,
  updateProgressWindow,
} from "../../../app/javascript/utilities/progress_window.js";

function buildController(overrides = {}) {
  return {
    identifier: "samples",
    progressWindowDismissed: false,
    _operationId: "abc",
    _progressWindowOpenedAt: null,
    _dismissProgressWindowTimeout: null,
    _progressMsgEl: null,
    _progressBarEl: null,
    _progressPctEl: null,
    minimumVisibleDurationMsValue: 3000,
    hasProgressTemplateTarget: false,
    progressTemplateTarget: null,
    ...overrides,
  };
}

function makeProgressRefs(controller) {
  const card = document.createElement("div");
  card.id = `${controller.identifier}-card-${controller._operationId}`;

  const message = document.createElement("div");
  message.dataset[`${controller.identifier}ProgressMessage`] = "true";
  card.appendChild(message);

  const bar = document.createElement("div");
  bar.dataset[`${controller.identifier}ProgressBar`] = "true";
  card.appendChild(bar);

  const percent = document.createElement("div");
  percent.dataset[`${controller.identifier}ProgressPercent`] = "true";
  card.appendChild(percent);

  controller._progressMsgEl = message;
  controller._progressBarEl = bar;
  controller._progressPctEl = percent;

  const container = document.createElement("div");
  container.id = `${controller.identifier}-progress-window`;
  container.appendChild(card);
  document.body.appendChild(container);

  return { card, container, message, bar, percent };
}

describe("progress_window", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    document.body.innerHTML = "";
  });

  it("returns early when the progress window was dismissed", () => {
    const controller = buildController({ progressWindowDismissed: true });
    const message = document.createElement("div");
    const bar = document.createElement("div");
    const percent = document.createElement("div");

    controller._progressMsgEl = message;
    controller._progressBarEl = bar;
    controller._progressPctEl = percent;

    updateProgressWindow(controller, "Done", 80, false);

    expect(message.textContent).toBe("");
    expect(bar.style.width).toBe("");
    expect(percent.textContent).toBe("");
  });

  it("does nothing when there is no operation id to anchor a card", () => {
    const controller = buildController({ _operationId: null });
    const message = document.createElement("div");

    updateProgressWindow(controller, "Missing id", 20, false);

    expect(message.textContent).toBe("");
    expect(
      document.getElementById(`${controller.identifier}-progress-window`),
    ).toBeNull();
  });

  it("updates message, progress bar, and percentage when visible", () => {
    const controller = buildController();
    const { message, bar, percent } = makeProgressRefs(controller);

    updateProgressWindow(controller, "Processing", 42, false);

    expect(message.textContent).toBe("Processing");
    expect(message.getAttribute("aria-live")).toBe("polite");
    expect(message.getAttribute("role")).toBeNull();
    expect(bar.style.width).toBe("42%");
    expect(bar.getAttribute("aria-valuenow")).toBe("42");
    expect(bar.getAttribute("aria-label")).toBe("Processing");
    expect(bar.classList.contains("bg-red-600")).toBe(false);
    expect(bar.classList.contains("bg-primary-600")).toBe(true);
    expect(percent.textContent).toBe("42%");
  });

  it("marks the message as an alert and swaps the bar colors on error", () => {
    const controller = buildController();
    const { message, bar, percent } = makeProgressRefs(controller);

    updateProgressWindow(controller, "Failed", 67, true);

    expect(message.getAttribute("role")).toBe("alert");
    expect(message.getAttribute("aria-live")).toBeNull();
    expect(bar.style.width).toBe("67%");
    expect(bar.getAttribute("aria-valuenow")).toBe("67");
    expect(bar.classList.contains("bg-red-600")).toBe(true);
    expect(bar.classList.contains("bg-primary-600")).toBe(false);
    expect(percent.textContent).toBe("67%");
  });

  it("clamps values into the 0..100 range", () => {
    const controller = buildController();
    const { bar, percent } = makeProgressRefs(controller);

    updateProgressWindow(controller, "Out of range", -25, false);
    expect(bar.getAttribute("aria-valuenow")).toBe("0");
    expect(percent.textContent).toBe("0%");

    updateProgressWindow(controller, "Top end", 250, false);
    expect(bar.getAttribute("aria-valuenow")).toBe("100");
    expect(percent.textContent).toBe("100%");
  });

  it("uses the current timestamp when openedAt is missing and sets the initial progress to zero", () => {
    const controller = buildController();
    const now = new Date("2024-01-01T00:00:00Z").getTime();
    vi.setSystemTime(now);
    const { message, bar, percent } = makeProgressRefs(controller);

    showProgressWindow(controller, "Starting");

    expect(controller._progressWindowOpenedAt).toBe(now);
    expect(message.textContent).toBe("Starting");
    expect(bar.style.width).toBe("0%");
    expect(percent.textContent).toBe("0%");
  });

  it("reuses the existing opened timestamp when the progress window is already active", () => {
    const controller = buildController({
      _progressWindowOpenedAt: 1234,
    });
    const { message, bar, percent } = makeProgressRefs(controller);

    showProgressWindow(controller, "Still active");

    expect(controller._progressWindowOpenedAt).toBe(1234);
    expect(message.textContent).toBe("Still active");
    expect(bar.style.width).toBe("0%");
    expect(percent.textContent).toBe("0%");
  });

  it("schedules a dismissal timeout based on elapsed time and the minimum duration", () => {
    const controller = buildController({
      _progressWindowOpenedAt: Date.now() - 1000,
      minimumVisibleDurationMsValue: 3500,
    });
    const dismissSpy = vi.spyOn(globalThis, "setTimeout");

    scheduleProgressWindowDismiss(controller);

    expect(dismissSpy).toHaveBeenCalledWith(expect.any(Function), 2500);
    expect(controller._dismissProgressWindowTimeout).not.toBeNull();
  });

  it("falls back to Date.now when no progress start timestamp exists", () => {
    const controller = buildController({
      _progressWindowOpenedAt: null,
      minimumVisibleDurationMsValue: 2000,
    });
    const dismissSpy = vi.spyOn(globalThis, "setTimeout");

    scheduleProgressWindowDismiss(controller);

    expect(dismissSpy).toHaveBeenCalledWith(expect.any(Function), 2000);
  });

  it("does nothing when clearing a missing dismiss timeout and removes an existing one", () => {
    const controller = buildController();

    clearProgressWindowDismissTimeout(controller);
    expect(controller._dismissProgressWindowTimeout).toBeNull();

    controller._dismissProgressWindowTimeout = setTimeout(() => {}, 1000);
    clearProgressWindowDismissTimeout(controller);
    expect(controller._dismissProgressWindowTimeout).toBeNull();
  });

  it("does not schedule a new dismissal once the window has already been dismissed", () => {
    const controller = buildController({ progressWindowDismissed: true });
    const setTimeoutSpy = vi.spyOn(globalThis, "setTimeout");

    scheduleProgressWindowDismiss(controller);

    expect(setTimeoutSpy).not.toHaveBeenCalled();
  });

  it("runs the scheduled dismissal callback when the timeout elapses", () => {
    const controller = buildController({
      _progressWindowOpenedAt: Date.now() - 1000,
      minimumVisibleDurationMsValue: 2000,
    });
    const { card } = makeProgressRefs(controller);

    scheduleProgressWindowDismiss(controller);
    vi.advanceTimersByTime(1000);

    expect(controller.progressWindowDismissed).toBe(true);
    expect(card.isConnected).toBe(false);
  });

  it("dismisses the progress card and container, then clears controller references", () => {
    const controller = buildController({
      _operationId: "abc",
      identifier: "samples",
    });
    const { card, container } = makeProgressRefs(controller);
    const dismissTimeout = setTimeout(() => {}, 1000);
    controller._dismissProgressWindowTimeout = dismissTimeout;
    controller.progressWindowDismissed = false;

    dismissProgressWindow(controller);

    expect(card.isConnected).toBe(false);
    expect(container.isConnected).toBe(false);
    expect(controller.progressWindowDismissed).toBe(true);
    expect(controller._progressWindowOpenedAt).toBeNull();
    expect(controller._progressMsgEl).toBeNull();
    expect(controller._progressBarEl).toBeNull();
    expect(controller._progressPctEl).toBeNull();
  });

  it("keeps the container when it still has other content", () => {
    const controller = buildController({ _operationId: "keep" });
    const container = document.createElement("div");
    container.id = "samples-progress-window";
    const stale = document.createElement("div");
    container.appendChild(stale);
    document.body.appendChild(container);

    dismissProgressWindow(controller);

    expect(document.getElementById("samples-progress-window")).not.toBeNull();
    expect(controller.progressWindowDismissed).toBe(true);
  });

  it("skips card removal when no operation id is present", () => {
    const controller = buildController({ _operationId: null });
    const container = document.createElement("div");
    container.id = "samples-progress-window";
    const stale = document.createElement("div");
    container.appendChild(stale);
    document.body.appendChild(container);

    dismissProgressWindow(controller);

    expect(document.getElementById("samples-progress-window")).not.toBeNull();
    expect(controller.progressWindowDismissed).toBe(true);
  });

  it("reuses an existing container instead of creating a duplicate one", () => {
    const controller = buildController({
      _operationId: "reuse",
      hasProgressTemplateTarget: false,
    });
    const container = document.createElement("div");
    container.id = "samples-progress-window";
    document.body.appendChild(container);

    updateProgressWindow(controller, "Reuse container", 5, false);

    expect(document.querySelectorAll("#samples-progress-window")).toHaveLength(
      1,
    );
    expect(document.getElementById("samples-card-reuse")).not.toBeNull();
  });

  it("recovers cached refs when a card already exists after reconnecting", () => {
    const controller = buildController({
      _operationId: "abc",
      identifier: "samples",
    });
    const card = document.createElement("div");
    card.id = "samples-card-abc";
    const message = document.createElement("div");
    message.dataset["samplesProgressMessage"] = "true";
    const bar = document.createElement("div");
    bar.dataset["samplesProgressBar"] = "true";
    const percent = document.createElement("div");
    percent.dataset["samplesProgressPercent"] = "true";
    card.append(message, bar, percent);
    document.body.appendChild(card);

    updateProgressWindow(controller, "Recovered", 10, false);

    expect(controller._progressMsgEl).toBe(message);
    expect(controller._progressBarEl).toBe(bar);
    expect(controller._progressPctEl).toBe(percent);
  });

  it("creates a progress card from the template and removes it when the dismiss button is clicked", () => {
    const controller = buildController({
      _operationId: "xyz",
      hasProgressTemplateTarget: true,
    });
    const template = document.createElement("template");
    template.innerHTML = `
      <div class="card">
        <div data-samples-progress-message>Loading</div>
        <div data-samples-progress-bar></div>
        <div data-samples-progress-percent>0%</div>
        <button type="button" data-samples-dismiss="true">Close</button>
      </div>
    `;
    controller.progressTemplateTarget = template;

    updateProgressWindow(controller, "Loading", 0, false);
    const card = document.getElementById("samples-card-xyz");
    const dismissButton = card.querySelector('[data-samples-dismiss="true"]');

    dismissButton.click();

    expect(document.getElementById("samples-card-xyz")).toBeNull();
    expect(controller.progressWindowDismissed).toBe(true);
  });

  it("ignores clicks on elements that are not the dismiss trigger", () => {
    const controller = buildController({
      _operationId: "xyz",
      hasProgressTemplateTarget: true,
    });
    const template = document.createElement("template");
    template.innerHTML = `
      <div class="card">
        <div data-samples-progress-message>Loading</div>
        <div data-samples-progress-bar></div>
        <div data-samples-progress-percent>0%</div>
        <button type="button" data-samples-dismiss="true">Close</button>
      </div>
    `;
    controller.progressTemplateTarget = template;

    updateProgressWindow(controller, "Loading", 0, false);
    const card = document.getElementById("samples-card-xyz");
    const message = card.querySelector("[data-samples-progress-message]");

    message.click();

    expect(controller.progressWindowDismissed).toBe(false);
    expect(document.getElementById("samples-card-xyz")).not.toBeNull();
  });
});
