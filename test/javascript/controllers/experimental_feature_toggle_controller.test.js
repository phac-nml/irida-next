import { Application } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import ExperimentalFeatureToggleController from "../../../app/javascript/controllers/experimental_feature_toggle_controller.js";

function renderFixture({
  status = "",
  featureKey = "data_grid_samples_table",
  includeMinimumSavingMs = true,
  includeClearDelay = true,
  includeValidationError = true,
  includeAnnouncer = true,
} = {}) {
  const announcerHtml = includeAnnouncer
    ? `<div
      id="experimental-features-live-announcer"
      role="status"
      aria-live="polite"
      aria-atomic="true"
    ></div>`
    : "";
  const minimumSavingMsAttr = includeMinimumSavingMs
    ? `data-experimental-feature-toggle-minimum-saving-ms-value="900"`
    : "";
  const clearDelayAttr = includeClearDelay
    ? `data-experimental-feature-toggle-clear-delay-value="3000"`
    : "";
  const validationErrorAttr = includeValidationError
    ? `data-experimental-feature-toggle-validation-error-text-value="The feature setting could not be updated. Please refresh the page and try again."`
    : "";
  document.body.innerHTML = `
    ${announcerHtml}
    <div
      id="experimental-feature-${featureKey}"
      data-controller="experimental-feature-toggle"
      data-experimental-feature-toggle-saving-text-value="Saving..."
      data-experimental-feature-toggle-success-text-value="Saved"
      ${validationErrorAttr}
      data-experimental-feature-toggle-feature-key-value="${featureKey}"
      ${minimumSavingMsAttr}
      ${clearDelayAttr}
    >
      <form data-experimental-feature-toggle-target="form">
        <p
          id="experimental-feature-${featureKey}-status"
          data-experimental-feature-toggle-target="status"
        >${status}</p>
        <input
          id="experimental-feature-${featureKey}-switch"
          type="checkbox"
          role="switch"
          data-experimental-feature-toggle-target="switch"
          data-action="change->experimental-feature-toggle#submit"
        />
      </form>
    </div>
  `;
}

async function startController() {
  const application = Application.start();
  application.register(
    "experimental-feature-toggle",
    ExperimentalFeatureToggleController,
  );
  await Promise.resolve();
  return application;
}

function switchControl() {
  return document.getElementById(
    "experimental-feature-data_grid_samples_table-switch",
  );
}

function status() {
  return document.getElementById(
    "experimental-feature-data_grid_samples_table-status",
  );
}

function announcer() {
  return document.getElementById("experimental-features-live-announcer");
}

function controllerFor(application) {
  return application.getControllerForElementAndIdentifier(
    document.querySelector('[data-controller~="experimental-feature-toggle"]'),
    "experimental-feature-toggle",
  );
}

describe("experimental feature toggle controller", () => {
  let application;

  afterEach(() => {
    application?.stop();
    vi.useRealTimers();
  });

  it("sets pending state, announces saving, and submits after the minimum delay", async () => {
    vi.useFakeTimers();
    renderFixture();
    application = await startController();
    const form = document.querySelector("form");
    form.requestSubmit = vi.fn();

    switchControl().checked = true;
    switchControl().dispatchEvent(new Event("change", { bubbles: true }));

    expect(status()).toHaveTextContent("Saving...");
    expect(announcer()).toHaveTextContent("Saving...");
    expect(
      sessionStorage.getItem(
        "experimentalFeatureToggleFocus:data_grid_samples_table",
      ),
    ).toBe("experimental-feature-data_grid_samples_table-switch");
    expect(form.requestSubmit).not.toHaveBeenCalled();

    vi.advanceTimersByTime(900);
    expect(form.requestSubmit).toHaveBeenCalledOnce();
  });

  it("reverts duplicate changes while a submission is pending", async () => {
    vi.useFakeTimers();
    renderFixture();
    application = await startController();
    document.querySelector("form").requestSubmit = vi.fn();

    switchControl().checked = true;
    switchControl().dispatchEvent(new Event("change", { bubbles: true }));
    switchControl().checked = false;
    switchControl().dispatchEvent(new Event("change", { bubbles: true }));

    expect(switchControl().checked).toBe(true);
    vi.advanceTimersByTime(900);
    expect(document.querySelector("form").requestSubmit).toHaveBeenCalledOnce();
  });

  it("restores focus from the per-feature session storage key", async () => {
    renderFixture();
    sessionStorage.setItem(
      "experimentalFeatureToggleFocus:data_grid_samples_table",
      "experimental-feature-data_grid_samples_table-switch",
    );

    application = await startController();

    expect(document.activeElement).toBe(switchControl());
    expect(
      sessionStorage.getItem(
        "experimentalFeatureToggleFocus:data_grid_samples_table",
      ),
    ).toBeNull();
  });

  it("announces rendered non-saving statuses through the page announcer", async () => {
    renderFixture({ status: "Saved" });

    application = await startController();

    expect(announcer()).toHaveTextContent("Saved");
  });

  it("clears rendered success text after the delay", async () => {
    vi.useFakeTimers();
    renderFixture({ status: "Saved" });
    application = await startController();

    vi.advanceTimersByTime(3000);

    expect(status()).toHaveTextContent("");
  });

  it("recovers pending state when turbo submit fails without a stream response", async () => {
    vi.useFakeTimers();
    renderFixture();
    application = await startController();
    const form = document.querySelector("form");
    form.requestSubmit = vi.fn();

    switchControl().checked = true;
    switchControl().dispatchEvent(new Event("change", { bubbles: true }));
    vi.advanceTimersByTime(900);

    form.dispatchEvent(
      new CustomEvent("turbo:submit-end", {
        bubbles: true,
        detail: {
          success: false,
          fetchResponse: { responseHTML: "" },
        },
      }),
    );

    expect(switchControl().checked).toBe(false);
    expect(status()).toHaveTextContent(
      "The feature setting could not be updated. Please refresh the page and try again.",
    );
    expect(announcer()).toHaveTextContent(
      "The feature setting could not be updated. Please refresh the page and try again.",
    );
  });

  it("does not reset pending state when turbo submit returns a stream response", async () => {
    vi.useFakeTimers();
    renderFixture();
    application = await startController();
    const form = document.querySelector("form");
    form.requestSubmit = vi.fn();

    switchControl().checked = true;
    switchControl().dispatchEvent(new Event("change", { bubbles: true }));
    vi.advanceTimersByTime(900);

    form.dispatchEvent(
      new CustomEvent("turbo:submit-end", {
        bubbles: true,
        detail: {
          success: false,
          fetchResponse: {
            responseHTML: '<turbo-stream action="replace"></turbo-stream>',
          },
        },
      }),
    );

    expect(switchControl().checked).toBe(true);
    expect(status()).toHaveTextContent("Saving...");
  });

  it("removes the submit-end listener on disconnect", async () => {
    renderFixture();
    application = await startController();
    const form = document.querySelector("form");
    const removeSpy = vi.spyOn(form, "removeEventListener");

    controllerFor(application).disconnect();

    expect(removeSpy).toHaveBeenCalledWith(
      "turbo:submit-end",
      expect.any(Function),
    );
  });

  it("falls back to the default minimum saving delay when unset", async () => {
    vi.useFakeTimers();
    renderFixture({ includeMinimumSavingMs: false });
    application = await startController();
    const form = document.querySelector("form");
    form.requestSubmit = vi.fn();

    switchControl().dispatchEvent(new Event("change", { bubbles: true }));

    vi.advanceTimersByTime(899);
    expect(form.requestSubmit).not.toHaveBeenCalled();
    vi.advanceTimersByTime(1);
    expect(form.requestSubmit).toHaveBeenCalledOnce();
  });

  it("ignores a successful turbo submit-end", async () => {
    vi.useFakeTimers();
    renderFixture();
    application = await startController();
    const form = document.querySelector("form");
    form.requestSubmit = vi.fn();

    switchControl().checked = true;
    switchControl().dispatchEvent(new Event("change", { bubbles: true }));
    vi.advanceTimersByTime(900);

    form.dispatchEvent(
      new CustomEvent("turbo:submit-end", {
        bubbles: true,
        detail: { success: true },
      }),
    );

    expect(switchControl().checked).toBe(true);
    expect(status()).toHaveTextContent("Saving...");
  });

  it("does nothing when resetting without a pending submission", async () => {
    renderFixture();
    application = await startController();
    const form = document.querySelector("form");

    form.dispatchEvent(
      new CustomEvent("turbo:submit-end", {
        bubbles: true,
        detail: { success: false, fetchResponse: { responseHTML: "" } },
      }),
    );

    expect(status()).toHaveTextContent("");
  });

  it("clears the status without an error message when no validation text is set", async () => {
    vi.useFakeTimers();
    renderFixture({ includeValidationError: false });
    application = await startController();
    const form = document.querySelector("form");
    form.requestSubmit = vi.fn();

    switchControl().checked = true;
    switchControl().dispatchEvent(new Event("change", { bubbles: true }));
    vi.advanceTimersByTime(900);

    form.dispatchEvent(
      new CustomEvent("turbo:submit-end", {
        bubbles: true,
        detail: { success: false, fetchResponse: { responseHTML: "" } },
      }),
    );

    expect(status()).toHaveTextContent("");
  });

  it("leaves the last-submitted state untouched when it was never recorded", async () => {
    renderFixture();
    application = await startController();
    const controller = controllerFor(application);
    controller.pending = true;
    status().textContent = "Idle";

    controller.resetPendingState();

    expect(controller.pending).toBe(false);
    expect(status()).toHaveTextContent("Idle");
  });

  it("uses the default clear delay when unset", async () => {
    vi.useFakeTimers();
    renderFixture({ status: "Saved", includeClearDelay: false });
    application = await startController();

    vi.advanceTimersByTime(3000);

    expect(status()).toHaveTextContent("");
  });

  it("keeps status text that changed before the clear delay elapsed", async () => {
    vi.useFakeTimers();
    renderFixture({ status: "Saved" });
    application = await startController();

    status().textContent = "Something else";
    vi.advanceTimersByTime(3000);

    expect(status()).toHaveTextContent("Something else");
  });

  it("does not announce a rendered saving status on connect", async () => {
    renderFixture({ status: "Saving..." });

    application = await startController();

    expect(announcer()).toHaveTextContent("");
  });

  it("skips announcing when the live announcer is absent", async () => {
    renderFixture({ status: "Saved", includeAnnouncer: false });

    application = await startController();

    expect(announcer()).toBeNull();
  });
});
