import { afterEach, describe, expect, it } from "vitest";
import {
  startApplication,
  stopApplication,
} from "../../../../helpers/stimulus.js";
import DestroyController from "../../../../../../app/javascript/controllers/projects/samples/metadata/destroy_controller.js";

const IDENTIFIER = "projects--samples--metadata--destroy";
const STORAGE_KEY = "destroy-key";

describe("projects/samples/metadata DestroyController", () => {
  let application;

  afterEach(async () => {
    await stopApplication(application);
  });

  async function mount() {
    document.body.innerHTML = `
      <div data-controller="${IDENTIFIER}"
           data-${IDENTIFIER}-storage-key-value="${STORAGE_KEY}">
        <span data-${IDENTIFIER}-target="field"></span>
      </div>`;
    application = startApplication();
    application.register(IDENTIFIER, DestroyController);
    await Promise.resolve();
    const element = document.querySelector(`[data-controller='${IDENTIFIER}']`);
    return {
      field: element.querySelector(`[data-${IDENTIFIER}-target='field']`),
      controller: application.getControllerForElementAndIdentifier(
        element,
        IDENTIFIER,
      ),
    };
  }

  it("adds a hidden input for each stored metadata field and clears storage", async () => {
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(["field-a", "field-b"]));

    const { field, controller } = await mount();

    const inputs = field.querySelectorAll("input[type='hidden']");
    expect(Array.from(inputs).map((input) => input.name)).toEqual([
      "sample[metadata][field-a]",
      "sample[metadata][field-b]",
    ]);
    expect(inputs[0].value).toBe("");

    controller.clear();
    expect(sessionStorage.getItem(STORAGE_KEY)).toBeNull();
  });

  it("adds no hidden inputs when there is nothing in storage", async () => {
    const { field } = await mount();

    expect(field.querySelectorAll("input[type='hidden']").length).toBe(0);
  });
});
