import { Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import LaunchWorkflowController from "../../../app/javascript/controllers/launch_workflow_controller.js";

const IDENTIFIER = "launch-workflow";

describe("LaunchWorkflowController", () => {
  let application;

  afterEach(async () => {
    await stopApplication(application);
  });

  async function mount(count = 3) {
    const stored = vi.fn().mockReturnValue(Array.from({ length: count }));
    class SelectionController extends Controller {
      getOrCreateStoredItems() {
        return stored();
      }
    }

    document.body.innerHTML = `
      <form>
        <div id="selection" data-controller="selection"></div>
        <div data-controller="${IDENTIFIER}"
             data-${IDENTIFIER}-selection-outlet="#selection"></div>
      </form>`;

    application = startApplication();
    application.register("selection", SelectionController);
    application.register(IDENTIFIER, LaunchWorkflowController);
    await Promise.resolve();

    const element = document.querySelector(`[data-controller='${IDENTIFIER}']`);
    return {
      form: document.querySelector("form"),
      controller: application.getControllerForElementAndIdentifier(
        element,
        IDENTIFIER,
      ),
    };
  }

  it("appends a hidden sample_count input reflecting the selection size", async () => {
    const { form, controller } = await mount(3);

    controller.appendSelectionCount();

    const input = form.querySelector('input[name="sample_count"]');
    expect(input.value).toBe("3");
  });

  it("replaces an existing sample_count input on repeated calls", async () => {
    const { form, controller } = await mount(2);

    controller.appendSelectionCount();
    controller.appendSelectionCount();

    const inputs = form.querySelectorAll('input[name="sample_count"]');
    expect(inputs.length).toBe(1);
    expect(inputs[0].value).toBe("2");
  });
});
