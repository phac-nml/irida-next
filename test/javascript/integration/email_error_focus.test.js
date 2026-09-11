import { afterEach, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import EmailInputController from "../../../app/javascript/controllers/email_input_controller.js";
import FormErrorSummaryController from "../../../app/javascript/controllers/form_error_summary_controller.js";

let application;
afterEach(async () => {
  await stopApplication(application);
});

it("moves focus from invalid submission to the summary and then to its email field", async () => {
  vi.useFakeTimers();
  document.body.innerHTML = `<div data-controller="email-input" data-email-input-email-missing-value="Email is required" data-email-input-email-format-value="Email is invalid">
    <form novalidate data-email-input-target="form" data-action="submit->email-input#submit">
      <div class="hidden" data-email-input-target="summary">
        <div id="summary" tabindex="-1" data-controller="form-error-summary">
          <a href="#email" data-action="form-error-summary#focusField" data-form-error-summary-target-id-param="email">Error</a>
        </div>
      </div>
      <input id="email" type="email" data-email-input-target="emailField">
      <div id="email-error" class="hidden" data-email-input-target="errorContainer"><span class="grow"></span></div>
    </form>
  </div>`;
  const summary = document.getElementById("summary");
  const email = document.getElementById("email");
  // Supply layout measurements only; the real focus helper and focus() run.
  for (const element of [summary, email]) {
    Object.defineProperty(element, "offsetParent", {
      get: () => (element.closest(".hidden") ? null : document.body),
    });
    vi.spyOn(element, "getClientRects").mockReturnValue([
      { width: 100, height: 20 },
    ]);
  }
  const scroll = vi.spyOn(email, "scrollIntoView").mockImplementation(() => {});
  application = startApplication();
  application.register("email-input", EmailInputController);
  application.register("form-error-summary", FormErrorSummaryController);
  await Promise.resolve();
  document
    .querySelector("form")
    .dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }));
  await vi.advanceTimersByTimeAsync(20);
  expect(document.activeElement).toBe(summary);
  expect(email).toHaveAttribute("aria-describedby", "email-error");
  expect(summary.querySelector("a")).toHaveTextContent("Email is required");
  summary.querySelector("a").click();
  await vi.advanceTimersByTimeAsync(20);
  expect(document.activeElement).toBe(email);
  expect(scroll).toHaveBeenCalledWith({ block: "center", inline: "nearest" });
});
