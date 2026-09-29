import { afterEach, describe, expect, it } from "vitest";
import {
  startApplication,
  stopApplication,
} from "../../../../helpers/stimulus.js";
import SelectedAttachmentsController from "../../../../../../app/javascript/controllers/projects/samples/attachments/selected_attachments_controller.js";

const IDENTIFIER = "projects--samples--attachments--selected-attachments";
const STORAGE_KEY = "selected-attachments-key";
const FIELD_NAME = "attachment";

describe("projects/samples/attachments SelectedAttachmentsController", () => {
  let application;

  afterEach(async () => {
    await stopApplication(application);
  });

  async function mount() {
    document.body.innerHTML = `
      <form data-controller="${IDENTIFIER}"
            data-${IDENTIFIER}-field-name-value="${FIELD_NAME}"
            data-${IDENTIFIER}-storage-key-value="${STORAGE_KEY}">
        <span data-${IDENTIFIER}-target="field"></span>
      </form>`;
    application = startApplication();
    application.register(IDENTIFIER, SelectedAttachmentsController);
    await Promise.resolve();
    const element = document.querySelector(`[data-controller='${IDENTIFIER}']`);
    return {
      element,
      field: element.querySelector(`[data-${IDENTIFIER}-target='field']`),
      controller: application.getControllerForElementAndIdentifier(
        element,
        IDENTIFIER,
      ),
    };
  }

  it("builds hidden inputs for array, string, and non-array JSON values", async () => {
    sessionStorage.setItem(
      STORAGE_KEY,
      JSON.stringify(['["a","b"]', "plain", "42"]),
    );

    const { field } = await mount();

    const inputs = Array.from(field.querySelectorAll("input[type='hidden']"));
    expect(inputs.map((input) => [input.name, input.value])).toEqual([
      ["attachment[0][]", "a"],
      ["attachment[0][]", "b"],
      ["attachment[1]", "plain"],
      ["attachment[2]", "42"],
    ]);
  });

  it("adds no hidden inputs when there is nothing in storage", async () => {
    const { field } = await mount();

    expect(field.querySelectorAll("input[type='hidden']").length).toBe(0);
  });

  it("clears storage only on a successful submission", async () => {
    sessionStorage.setItem(STORAGE_KEY, JSON.stringify(["plain"]));
    const { controller } = await mount();

    controller.clear({ detail: { success: false } });
    expect(sessionStorage.getItem(STORAGE_KEY)).not.toBeNull();

    controller.clear({ detail: { success: true } });
    expect(sessionStorage.getItem(STORAGE_KEY)).toBeNull();
  });
});
