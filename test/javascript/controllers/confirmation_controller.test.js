import { afterEach, describe, expect, it } from "vitest";
import userEvent from "@testing-library/user-event";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import ConfirmationController from "../../../app/javascript/controllers/confirmation_controller.js";

describe("confirmation", () => {
  let application;
  afterEach(async () => {
    await stopApplication(application);
  });
  it("requires an exact match and reads the current confirmation value", async () => {
    document.body.innerHTML = `<form data-controller="confirmation" data-confirmation-input-value="Delete">
      <input aria-label="Confirmation" data-action="input->confirmation#inputChange">
      <button disabled data-confirmation-target="confirmButton">Confirm</button>
    </form>`;
    application = startApplication();
    application.register("confirmation", ConfirmationController);
    await Promise.resolve();
    const user = userEvent.setup();
    const input = document.querySelector("input");
    const button = document.querySelector("button");
    await user.type(input, "delete");
    expect(button).toBeDisabled();
    await user.clear(input);
    await user.type(input, "Delete");
    expect(button).toBeEnabled();
    await user.type(input, " ");
    expect(button).toBeDisabled();
    document.querySelector("form").dataset.confirmationInputValue = "Changed";
    await user.clear(input);
    await user.type(input, "Changed");
    expect(button).toBeEnabled();
    await user.clear(input);
    expect(button).toBeDisabled();
  });
});
