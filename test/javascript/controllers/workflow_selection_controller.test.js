import { Application, Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import WorkflowSelectionController from "../../../app/javascript/controllers/workflow_selection_controller.js";

class SelectionOutletStubController extends Controller {
  clear() {
    this.element.dataset.cleared = "true";
  }
}

async function startController(options = {}) {
  document.body.innerHTML = renderFixture(options);

  const application = Application.start();
  application.register("workflow-selection", WorkflowSelectionController);
  application.register("selection", SelectionOutletStubController);

  await Promise.resolve();
  await new Promise((resolve) => requestAnimationFrame(resolve));

  return application;
}

function renderFixture({
  includeOutlet = true,
  workflowDisabled = false,
} = {}) {
  const outletAttribute = includeOutlet
    ? 'data-workflow-selection-selection-outlet="#samples-table"'
    : "";

  return `
    <button class="dialog--close">Close</button>

    <div id="samples-table" data-controller="selection"></div>

    <div
      id="workflow-selection-root"
      data-controller="workflow-selection"
      ${outletAttribute}
    >
      <form data-workflow-selection-target="form">
        <input
          type="hidden"
          name="pipeline_id"
          value=""
          data-workflow-selection-target="pipelineId"
        />
        <input
          type="hidden"
          name="workflow_version"
          value=""
          data-workflow-selection-target="workflowVersion"
        />
        <ul id="workflow-list">
          <li>
            <button
              type="button"
              data-workflow-id="workflow-a"
              data-workflow-selection-target="workflow"
              data-action="click->workflow-selection#selectWorkflow"
              aria-disabled="${workflowDisabled ? "true" : "false"}"
            >
              workflow-a
            </button>
          </li>
        </ul>
      </form>
    </div>
  `;
}

function controllerFor(application) {
  return application.getControllerForElementAndIdentifier(
    document.getElementById("workflow-selection-root"),
    "workflow-selection",
  );
}

function workflowButton(id) {
  return document.querySelector(`[data-workflow-id="${id}"]`);
}

function dispatchBeforeFetch(form, resume = vi.fn()) {
  const event = new CustomEvent("turbo:before-fetch-request", {
    bubbles: true,
    detail: {
      fetchOptions: {
        headers: {},
      },
      resume,
    },
  });

  form.dispatchEvent(event);
  return event;
}

function dispatchKeydown(key) {
  const event = new KeyboardEvent("keydown", {
    key,
    bubbles: true,
    cancelable: true,
  });
  document.dispatchEvent(event);
  return event;
}

describe("workflow selection controller", () => {
  let application;

  afterEach(() => {
    application?.stop();
    document.body.innerHTML = "";
  });

  it("converts form data to JSON and resumes the Turbo request", async () => {
    application = await startController();

    document.querySelector(
      '[data-workflow-selection-target="pipelineId"]',
    ).value = "pipeline-json";
    document.querySelector(
      '[data-workflow-selection-target="workflowVersion"]',
    ).value = "3.2.1";

    const resume = vi.fn();
    const event = dispatchBeforeFetch(document.querySelector("form"), resume);
    const payload = JSON.parse(event.detail.fetchOptions.body);

    expect(payload.pipeline_id).toBe("pipeline-json");
    expect(payload.workflow_version).toBe("3.2.1");
    expect(event.detail.fetchOptions.headers["Content-Type"]).toBe(
      "application/json",
    );
    expect(resume).toHaveBeenCalledOnce();
  });

  it("clears the selection outlet only on a successful submit when clearing is enabled", async () => {
    application = await startController();
    const controller = controllerFor(application);
    const form = document.querySelector("form");
    const selectionOutlet = document.getElementById("samples-table");

    const submitEnd = (success) =>
      form.dispatchEvent(
        new CustomEvent("turbo:submit-end", {
          bubbles: true,
          detail: { success },
        }),
      );

    // Success without clearing enabled leaves the outlet untouched.
    submitEnd(true);
    expect(selectionOutlet.dataset.cleared).toBeUndefined();

    controller.clearSelectionValue = true;

    // Failure with clearing enabled still leaves the outlet untouched.
    submitEnd(false);
    expect(selectionOutlet.dataset.cleared).toBeUndefined();

    // Success with clearing enabled clears the outlet.
    submitEnd(true);
    expect(selectionOutlet.dataset.cleared).toBe("true");
  });

  it("submits the selected workflow, writes hidden fields, and blocks escape while locked", async () => {
    application = await startController();
    const controller = controllerFor(application);
    const form = document.querySelector("form");

    form.requestSubmit = vi.fn();

    controller.selectWorkflow({
      currentTarget: workflowButton("workflow-a"),
      params: {
        pipelineid: "pipeline-selected",
        workflowversion: "2.0.0",
      },
    });

    expect(
      document.querySelector(".dialog--close").classList.contains("hidden"),
    ).toBe(true);
    expect(
      document.querySelector('[data-workflow-selection-target="pipelineId"]')
        .value,
    ).toBe("pipeline-selected");
    expect(
      document.querySelector(
        '[data-workflow-selection-target="workflowVersion"]',
      ).value,
    ).toBe("2.0.0");
    expect(form.requestSubmit).toHaveBeenCalledOnce();

    // Escape is swallowed while the dialog is locked; other keys pass through.
    expect(dispatchKeydown("Escape").defaultPrevented).toBe(true);
    expect(dispatchKeydown("Enter").defaultPrevented).toBe(false);

    controller.removeEscapeListener();

    expect(dispatchKeydown("Escape").defaultPrevented).toBe(false);
  });

  it("does not submit when the selected workflow is disabled", async () => {
    application = await startController({ workflowDisabled: true });
    const controller = controllerFor(application);
    const form = document.querySelector("form");

    form.requestSubmit = vi.fn();

    controller.selectWorkflow({
      currentTarget: workflowButton("workflow-a"),
      params: {
        pipelineid: "should-not-set",
        workflowversion: "9.9.9",
      },
    });

    expect(
      document.querySelector(".dialog--close").classList.contains("hidden"),
    ).toBe(false);
    expect(
      document.querySelector('[data-workflow-selection-target="pipelineId"]')
        .value,
    ).toBe("");
    expect(form.requestSubmit).not.toHaveBeenCalled();
  });

  it("removes form and escape listeners on disconnect", async () => {
    application = await startController();
    const controller = controllerFor(application);
    const form = document.querySelector("form");

    controller.preventClosingDialog();
    expect(dispatchKeydown("Escape").defaultPrevented).toBe(true);

    controller.disconnect();

    // Escape handling stops and the form is no longer amended after disconnect.
    expect(dispatchKeydown("Escape").defaultPrevented).toBe(false);

    const resume = vi.fn();
    const event = dispatchBeforeFetch(form, resume);
    expect(event.detail.fetchOptions.body).toBeUndefined();
    expect(resume).not.toHaveBeenCalled();

    application = undefined;
  });
});
