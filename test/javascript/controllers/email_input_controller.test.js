import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import EmailInputController from "../../../app/javascript/controllers/email_input_controller.js";
import { focusWhenVisible } from "utilities/focus";

vi.mock("utilities/focus", () => ({ focusWhenVisible: vi.fn() }));

describe("email input", () => {
  let application, root, controller;
  const target = (name) =>
    root.querySelector(`[data-email-input-target="${name}"]`);
  async function mount({ summary = true, link = true, omit = "" } = {}) {
    document.body.innerHTML = `<div data-controller="email-input"
      ${omit !== "missing" ? 'data-email-input-email-missing-value="Email is required"' : ""}
      ${omit !== "format" ? 'data-email-input-email-format-value="Email is invalid"' : ""}>
      <form novalidate data-email-input-target="form" data-action="submit->email-input#submit">
        <input type="email" data-email-input-target="emailField" data-action="input->email-input#handleInput">
        <div id="email-error" class="hidden" data-email-input-target="errorContainer"><span class="grow"></span></div>
        ${summary ? `<div class="hidden" data-email-input-target="summary"><div data-controller="form-error-summary" tabindex="-1">${link ? '<a href="#email">Error</a>' : ""}</div></div>` : ""}
      </form>
    </div>`;
    root = document.body.firstElementChild;
    application = startApplication();
    if (omit) vi.spyOn(application, "handleError");
    application.register("email-input", EmailInputController);
    await Promise.resolve();
    controller = application.getControllerForElementAndIdentifier(
      root,
      "email-input",
    );
  }
  function input(value) {
    target("emailField").value = value;
    target("emailField").dispatchEvent(new Event("input", { bubbles: true }));
  }
  function submit() {
    const event = new Event("submit", { bubbles: true, cancelable: true });
    target("form").dispatchEvent(event);
    expect(event.defaultPrevented).toBe(true);
  }
  beforeEach(() => vi.useFakeTimers());
  afterEach(async () => {
    await stopApplication(application);
  });

  it("shows required errors and requests focus on submission", async () => {
    await mount();
    const send = vi
      .spyOn(target("form"), "submit")
      .mockImplementation(() => {});
    submit();
    expect(target("errorContainer")).toHaveTextContent("Email is required");
    expect(target("errorContainer")).not.toHaveClass("hidden");
    expect(target("emailField")).toHaveAttribute("aria-invalid", "true");
    expect(target("emailField")).toHaveAttribute(
      "aria-describedby",
      "email-error",
    );
    expect(target("emailField").validationMessage).toBe("Email is required");
    expect(target("summary")).not.toHaveClass("hidden");
    expect(target("summary").querySelector("a")).toHaveTextContent(
      "Email is required",
    );
    expect(focusWhenVisible).toHaveBeenCalledWith(
      target("summary").firstElementChild,
    );
    expect(send).not.toHaveBeenCalled();
  });
  it("debounces typing, uses the latest input and avoids stealing focus", async () => {
    await mount();
    input("wrong");
    vi.advanceTimersByTime(200);
    input("still-wrong");
    vi.advanceTimersByTime(299);
    expect(target("errorContainer")).toHaveClass("hidden");
    vi.advanceTimersByTime(1);
    expect(target("errorContainer")).toHaveTextContent("Email is invalid");
    expect(target("summary")).toHaveClass("hidden");
    expect(focusWhenVisible).not.toHaveBeenCalled();
    input("");
    vi.advanceTimersByTime(300);
    expect(target("errorContainer")).toHaveClass("hidden");
    expect(target("emailField")).toHaveAttribute("aria-invalid", "false");
  });
  it("clears previous errors and submits a valid email on the next frame", async () => {
    await mount();
    submit();
    const send = vi
      .spyOn(target("form"), "submit")
      .mockImplementation(() => {});
    input("person@example.com");
    submit();
    expect(target("emailField").validationMessage).toBe("");
    expect(target("emailField")).not.toHaveAttribute("aria-describedby");
    expect(target("errorContainer")).toHaveClass("hidden");
    expect(target("summary")).toHaveClass("hidden");
    expect(send).not.toHaveBeenCalled();
    vi.advanceTimersByTime(20);
    expect(send).toHaveBeenCalledOnce();
  });
  it("cancels debounced validation when removed and reconnects normally", async () => {
    await mount();
    input("invalid");
    root.remove();
    await Promise.resolve();
    await Promise.resolve();
    vi.advanceTimersByTime(300);
    expect(target("errorContainer")).toHaveClass("hidden");
    document.body.append(root);
    await Promise.resolve();
    input("invalid-again");
    vi.advanceTimersByTime(300);
    expect(target("errorContainer")).not.toHaveClass("hidden");
  });
  it("cancels a queued form submission when disconnected", async () => {
    await mount();
    const send = vi
      .spyOn(target("form"), "submit")
      .mockImplementation(() => {});
    input("person@example.com");
    submit();
    root.remove();
    await Promise.resolve();
    await Promise.resolve();
    vi.advanceTimersByTime(20);
    expect(send).not.toHaveBeenCalled();
  });
  it("does not queue duplicate submissions before the next frame", async () => {
    await mount();
    const send = vi
      .spyOn(target("form"), "submit")
      .mockImplementation(() => {});
    input("person@example.com");
    submit();
    submit();
    vi.advanceTimersByTime(20);
    expect(send).toHaveBeenCalledOnce();
  });
  it.each([{ summary: false }, { link: false }])(
    "handles optional summary markup %j",
    async (options) => {
      await mount(options);
      expect(() => controller.showError("Invalid")).not.toThrow();
      expect(() => controller.clearError()).not.toThrow();
    },
  );
  it.each(["missing", "format"])(
    "reports an absent %s message",
    async (omit) => {
      await mount({ omit });
      expect(application.handleError).toHaveBeenCalledWith(
        expect.objectContaining({ message: `email-${omit} value is required` }),
        expect.any(String),
        expect.any(Object),
      );
      const stopped = stopApplication(application);
      application = undefined;
      await expect(stopped).rejects.toThrow();
    },
  );
  it.each([
    ["person@example.com", true],
    ["first.last+tag@sub.example.org", true],
    ["", false],
    ["missing-at.example.com", false],
    ["person@localhost", false],
    ["a".repeat(64) + "@example.com", true],
    ["a".repeat(65) + "@example.com", false],
    ["p@" + "a".repeat(251) + ".com", true],
    ["p@" + "a".repeat(252) + ".com", false],
    ['"a@@b"@example.com', false],
    ['"a@b"@example.com', false],
    ['"a@b.c"@example.com', true],
  ])("applies the current email format rules to %s", async (email, valid) => {
    await mount();
    expect(controller.isValidEmailFormat(email)).toBe(valid);
  });
});
