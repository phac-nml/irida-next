import { afterEach, describe, expect, it } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import ActionButtonController from "../../../app/javascript/controllers/action_button_controller.js";

describe("action button", () => {
  let application;
  async function mount(attributes = "") {
    document.body.innerHTML = `<button data-controller="action-button" ${attributes}>Act</button>`;
    application = startApplication();
    application.register("action-button", ActionButtonController);
    await Promise.resolve();
    const button = document.querySelector("button");
    return [
      button,
      application.getControllerForElementAndIdentifier(button, "action-button"),
    ];
  }
  afterEach(async () => {
    await stopApplication(application);
  });

  it.each(["button-primary", "button-default"])(
    "updates native state and styling at the selection threshold (%s)",
    async (style) => {
      const [button, controller] = await mount(
        `class="${style}" data-action-button-required-value="2"`,
      );
      const disabledColour =
        style === "button-primary" ? "bg-primary-200" : "bg-slate-100";
      expect(button).toBeDisabled();
      expect(button).toHaveClass(
        "pointer-events-none",
        "cursor-not-allowed",
        disabledColour,
      );
      controller.setDisabled(1);
      expect(button).toBeDisabled();
      controller.setDisabled(2);
      expect(button).toBeEnabled();
      expect(button).not.toHaveClass(disabledColour);
      expect(button).not.toHaveClass("pointer-events-none");
      controller.setDisabled(3);
      expect(button).toBeEnabled();
      document.dispatchEvent(new Event("turbo:morph"));
      expect(button).toBeDisabled();
    },
  );

  it("enables buttons with no selection requirement", async () => {
    const [button] = await mount();
    expect(button).toBeEnabled();
  });

  it("releases its morph listener while detached and restores it on reconnect", async () => {
    const [button, controller] = await mount(
      'data-action-button-required-value="1"',
    );
    button.remove();
    await Promise.resolve();
    await Promise.resolve();
    controller.setDisabled(1);
    document.dispatchEvent(new Event("turbo:morph"));
    expect(button).toBeEnabled();
    document.body.append(button);
    await Promise.resolve();
    expect(button).toBeDisabled();
    controller.setDisabled(1);
    document.dispatchEvent(new Event("turbo:morph"));
    expect(button).toBeDisabled();
  });
});
