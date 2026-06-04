import { Application } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import ExperimentalFeatureToggleController from "../../../app/javascript/controllers/experimental_feature_toggle_controller.js";

function renderFixture({
  status = "",
  featureKey = "data_grid_samples_table",
} = {}) {
  document.body.innerHTML = `
    <div
      id="experimental-features-live-announcer"
      role="status"
      aria-live="polite"
      aria-atomic="true"
    ></div>
    <div
      id="experimental-feature-${featureKey}"
      data-controller="experimental-feature-toggle"
      data-experimental-feature-toggle-saving-text-value="Saving..."
      data-experimental-feature-toggle-success-text-value="Saved"
      data-experimental-feature-toggle-feature-key-value="${featureKey}"
      data-experimental-feature-toggle-minimum-saving-ms-value="900"
      data-experimental-feature-toggle-clear-delay-value="3000"
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

    expect(
      document.getElementById("experimental-feature-data_grid_samples_table"),
    ).toHaveAttribute("aria-busy", "true");
    expect(switchControl()).toHaveAttribute("aria-disabled", "true");
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
});
