import { afterEach, describe, expect, it } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import PasswordVisibilityController from "../../../app/javascript/controllers/password_visibility_controller.js";

describe("password visibility", () => {
  let application;

  async function mount() {
    document.body.innerHTML = `
      <form>
        <div
          data-controller="password-visibility"
          data-password-visibility-show-label-value="Show password"
          data-password-visibility-hide-label-value="Hide password"
        >
          <input type="password" data-password-visibility-target="input" />
          <button
            type="button"
            class="hidden"
            data-password-visibility-target="toggle"
            data-action="password-visibility#toggle"
          >
            <span data-password-visibility-target="showIcon"></span>
            <span class="hidden" data-password-visibility-target="hideIcon"></span>
          </button>
        </div>
      </form>
    `;
    application = startApplication();
    application.register("password-visibility", PasswordVisibilityController);
    await Promise.resolve();
    return {
      form: document.querySelector("form"),
      input: document.querySelector("input"),
      button: document.querySelector("button"),
    };
  }

  afterEach(async () => {
    await stopApplication(application);
  });

  it("reveals the toggle only once connected", async () => {
    const { button } = await mount();

    expect(button).not.toHaveClass("hidden");
    expect(button).toHaveAttribute("aria-label", "Show password");
    expect(button).toHaveAttribute("aria-pressed", "false");
  });

  it("switches the field, name, and state together", async () => {
    const { input, button } = await mount();

    button.click();
    expect(input).toHaveAttribute("type", "text");
    expect(button).toHaveAttribute("aria-label", "Hide password");
    expect(button).toHaveAttribute("aria-pressed", "true");

    button.click();
    expect(input).toHaveAttribute("type", "password");
    expect(button).toHaveAttribute("aria-label", "Show password");
  });

  it("conceals the password again on submit", async () => {
    const { form, input, button } = await mount();

    button.click();
    form.dispatchEvent(new Event("submit"));

    expect(input).toHaveAttribute("type", "password");
  });
});
