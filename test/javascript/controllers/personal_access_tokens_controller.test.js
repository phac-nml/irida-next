import { afterEach, describe, expect, it } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import PersonalAccessTokensController from "../../../app/javascript/controllers/personal_access_tokens_controller.js";

const IDENTIFIER = "personal-access-tokens";

describe("PersonalAccessTokensController", () => {
  let application;

  afterEach(async () => {
    await stopApplication(application);
  });

  it("empties the new-token form parent while keeping the element", async () => {
    document.body.innerHTML = `
      <div data-controller="${IDENTIFIER}">
        <div data-${IDENTIFIER}-target="newTokenFormParent">
          <form id="new-token-form"></form>
        </div>
      </div>`;

    application = startApplication();
    application.register(IDENTIFIER, PersonalAccessTokensController);
    await Promise.resolve();

    const element = document.querySelector(`[data-controller='${IDENTIFIER}']`);
    const parent = element.querySelector(
      `[data-${IDENTIFIER}-target='newTokenFormParent']`,
    );
    application
      .getControllerForElementAndIdentifier(element, IDENTIFIER)
      .removeAddNewTokenForm();

    expect(parent.isConnected).toBe(true);
    expect(parent.innerHTML).toBe("");
    expect(document.getElementById("new-token-form")).toBeNull();
  });
});
