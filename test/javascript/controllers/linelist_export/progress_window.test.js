import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  dismissProgressWindow,
  showProgressWindow,
  updateProgressWindow,
} from "controllers/linelist_export/progress_window";

const buildController = () => {
  const template = document.createElement("template");
  template.innerHTML = `
    <div>
      <p data-linelist-export-progress-message></p>
      <div
        data-linelist-export-progress-bar
        class="bg-primary-600"
        role="progressbar"
        aria-valuenow="0"
      ></div>
      <span data-linelist-export-progress-percent></span>
    </div>
  `;

  return {
    _exportId: "export-1",
    _progressWindowOpenedAt: null,
    _dismissProgressWindowTimeout: null,
    _progressMsgEl: null,
    _progressBarEl: null,
    _progressPctEl: null,
    progressWindowDismissed: false,
    progressWindowActionsEnabled: true,
    progressWindowClickHandler: vi.fn(),
    hasProgressTemplateTarget: true,
    progressTemplateTarget: template,
    minimumVisibleDurationMsValue: 3500,
  };
};

describe("linelist_export/progress_window", () => {
  beforeEach(() => {
    vi.useRealTimers();
  });

  it("creates a progress card and updates status text, percent, and progressbar state", () => {
    const controller = buildController();

    showProgressWindow(controller, "Preparing rows");
    updateProgressWindow(controller, "Created 5 of 10 records", 50);

    const container = document.getElementById(
      "linelist-export-progress-window",
    );
    const card = document.getElementById("linelist-export-card-export-1");

    expect(container).toBeInTheDocument();
    expect(container).toHaveAttribute("data-turbo-permanent");
    expect(card).toBeInTheDocument();
    expect(controller._progressMsgEl.textContent).toBe(
      "Created 5 of 10 records",
    );
    expect(controller._progressMsgEl).toHaveAttribute("aria-live", "polite");
    expect(controller._progressBarEl.style.width).toBe("50%");
    expect(controller._progressBarEl).toHaveAttribute("aria-valuenow", "50");
    expect(controller._progressPctEl.textContent).toBe("50%");
  });

  it("marks error progress as an alert and uses error styling", () => {
    const controller = buildController();

    updateProgressWindow(controller, "Upload failed", 100, true);

    expect(controller._progressMsgEl).toHaveAttribute("role", "alert");
    expect(controller._progressMsgEl).not.toHaveAttribute("aria-live");
    expect(controller._progressBarEl).toHaveClass("bg-red-600");
    expect(controller._progressBarEl).not.toHaveClass("bg-primary-600");
  });

  it("dismisses the active card and clears controller progress references", () => {
    const controller = buildController();
    showProgressWindow(controller, "Preparing rows");

    dismissProgressWindow(controller);

    expect(
      document.getElementById("linelist-export-card-export-1"),
    ).not.toBeInTheDocument();
    expect(
      document.getElementById("linelist-export-progress-window"),
    ).not.toBeInTheDocument();
    expect(controller.progressWindowDismissed).toBe(true);
    expect(controller._exportId).toBeNull();
    expect(controller._progressMsgEl).toBeNull();
    expect(controller._progressBarEl).toBeNull();
    expect(controller._progressPctEl).toBeNull();
  });
});
