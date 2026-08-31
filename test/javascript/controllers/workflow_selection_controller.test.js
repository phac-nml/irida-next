import { Application, Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import WorkflowSelectionController from "../../../app/javascript/controllers/workflow_selection_controller.js";

class SelectionOutletStubController extends Controller {
  getStoredItemsCount() {
    return Number.parseInt(this.element.dataset.storedItemsCount ?? "0", 10);
  }

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
  sampleCount = 0,
  fieldName = "sample_count",
  unavailableLabel = "Unavailable",
  workflows = [
    {
      id: "workflow-a",
      pipelineId: "pipeline-a",
      workflowVersion: "1.0.0",
      minSamplesConfigured: false,
      maxSamplesConfigured: false,
      minSamples: "",
      maxSamples: "",
      minMessage: "",
      maxMessage: "",
      includeLimitMessage: true,
    },
  ],
} = {}) {
  const outletAttribute = includeOutlet
    ? 'data-workflow-selection-selection-outlet="#samples-table"'
    : "";

  const workflowsHtml = workflows
    .map((workflow) => {
      const minConfigured = workflow.minSamplesConfigured ? "true" : "false";
      const maxConfigured = workflow.maxSamplesConfigured ? "true" : "false";
      const minAttribute = workflow.minSamplesConfigured
        ? `data-workflow-selection-min-samples="${workflow.minSamples}"`
        : "";
      const maxAttribute = workflow.maxSamplesConfigured
        ? `data-workflow-selection-max-samples="${workflow.maxSamples}"`
        : "";
      const limitMessage = workflow.includeLimitMessage
        ? '<span data-workflow-selection-limit-message class="hidden">initial</span>'
        : "";

      return `
        <li data-workflow-row="${workflow.id}">
          <button
            type="button"
            class="button button-default"
            data-workflow-id="${workflow.id}"
            data-workflow-selection-target="workflow"
            data-workflow-selection-min-samples-configured="${minConfigured}"
            data-workflow-selection-max-samples-configured="${maxConfigured}"
            ${minAttribute}
            ${maxAttribute}
            data-workflow-selection-min-samples-message="${workflow.minMessage}"
            data-workflow-selection-max-samples-message="${workflow.maxMessage}"
            data-action="click->workflow-selection#selectWorkflow"
            aria-disabled="false"
          >
            ${workflow.id}
            ${limitMessage}
          </button>
        </li>
      `;
    })
    .join("");

  return `
    <button class="dialog--close">Close</button>

    <div
      id="samples-table"
      data-controller="selection"
      data-stored-items-count="${sampleCount}"
    ></div>

    <div
      id="workflow-selection-root"
      data-controller="workflow-selection"
      ${outletAttribute}
      data-workflow-selection-field-name-value="${fieldName}"
      data-workflow-selection-unavailable-label-value="${unavailableLabel}"
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
          ${workflowsHtml}
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

function limitMessageFor(id) {
  return workflowButton(id).querySelector(
    "[data-workflow-selection-limit-message]",
  );
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

describe("workflow selection controller", () => {
  let application;

  afterEach(() => {
    application?.stop();
    document.body.innerHTML = "";
    sessionStorage.clear();
  });

  it("disables out-of-range workflows, shows messages, and groups them under one divider", async () => {
    application = await startController({
      sampleCount: 1,
      workflows: [
        {
          id: "disabled-min",
          pipelineId: "pipeline-a",
          workflowVersion: "1.0.0",
          minSamplesConfigured: true,
          maxSamplesConfigured: false,
          minSamples: 2,
          maxSamples: "",
          minMessage: "Need at least 2",
          maxMessage: "",
          includeLimitMessage: true,
        },
        {
          id: "enabled",
          pipelineId: "pipeline-b",
          workflowVersion: "1.0.1",
          minSamplesConfigured: false,
          maxSamplesConfigured: false,
          minSamples: "",
          maxSamples: "",
          minMessage: "",
          maxMessage: "",
          includeLimitMessage: false,
        },
      ],
    });

    const controller = controllerFor(application);

    expect(workflowButton("disabled-min").getAttribute("aria-disabled")).toBe(
      "true",
    );
    expect(limitMessageFor("disabled-min").classList.contains("hidden")).toBe(
      false,
    );
    expect(limitMessageFor("disabled-min").textContent).toBe("Need at least 2");

    const order = [...document.querySelectorAll("#workflow-list > li")].map(
      (li) => {
        if (li.dataset.workflowSelectionDivider === "true") {
          return "divider";
        }

        return li.dataset.workflowRow;
      },
    );

    expect(order).toEqual(["enabled", "divider", "disabled-min"]);

    controller.updateWorkflowAvailability();
    expect(
      document.querySelectorAll("[data-workflow-selection-divider]").length,
    ).toBe(1);
    expect(
      document.querySelector("[data-workflow-selection-divider]"),
    ).toHaveTextContent("Unavailable");
  });

  it("applies maximum sample limit messages when sample count exceeds configured max", async () => {
    application = await startController({
      sampleCount: 3,
      workflows: [
        {
          id: "enabled",
          pipelineId: "pipeline-b",
          workflowVersion: "1.0.1",
          minSamplesConfigured: false,
          maxSamplesConfigured: false,
          minSamples: "",
          maxSamples: "",
          minMessage: "",
          maxMessage: "",
          includeLimitMessage: true,
        },
        {
          id: "disabled-max",
          pipelineId: "pipeline-c",
          workflowVersion: "1.0.2",
          minSamplesConfigured: false,
          maxSamplesConfigured: true,
          minSamples: "",
          maxSamples: 1,
          minMessage: "",
          maxMessage: "At most 1",
          includeLimitMessage: true,
        },
      ],
    });

    expect(workflowButton("disabled-max").getAttribute("aria-disabled")).toBe(
      "true",
    );
    expect(limitMessageFor("disabled-max").textContent).toBe("At most 1");
  });

  it("keeps all workflows enabled and hides limit notices when all constraints pass", async () => {
    application = await startController({
      sampleCount: 2,
      workflows: [
        {
          id: "enabled-a",
          pipelineId: "pipeline-a",
          workflowVersion: "1.0.0",
          minSamplesConfigured: true,
          maxSamplesConfigured: true,
          minSamples: 1,
          maxSamples: 3,
          minMessage: "Need at least 1",
          maxMessage: "At most 3",
          includeLimitMessage: true,
        },
        {
          id: "enabled-b",
          pipelineId: "pipeline-b",
          workflowVersion: "1.0.1",
          minSamplesConfigured: false,
          maxSamplesConfigured: false,
          minSamples: "",
          maxSamples: "",
          minMessage: "",
          maxMessage: "",
          includeLimitMessage: true,
        },
      ],
    });

    expect(workflowButton("enabled-a").getAttribute("aria-disabled")).toBe(
      "false",
    );
    expect(limitMessageFor("enabled-a").classList.contains("hidden")).toBe(
      true,
    );
    expect(
      document.querySelector("[data-workflow-selection-divider]"),
    ).toBeNull();
  });

  it("treats sample count as zero when no selection outlet is configured", async () => {
    application = await startController({
      includeOutlet: false,
      workflows: [
        {
          id: "disabled-without-outlet",
          pipelineId: "pipeline-a",
          workflowVersion: "1.0.0",
          minSamplesConfigured: true,
          maxSamplesConfigured: false,
          minSamples: 1,
          maxSamples: "",
          minMessage: "Need at least 1",
          maxMessage: "",
          includeLimitMessage: true,
        },
      ],
    });

    expect(
      workflowButton("disabled-without-outlet").getAttribute("aria-disabled"),
    ).toBe("true");
    expect(limitMessageFor("disabled-without-outlet").textContent).toBe(
      "Need at least 1",
    );
  });

  it("submits selected workflow, writes hidden fields, and blocks escape while dialog is locked", async () => {
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

    const preventedEscape = new KeyboardEvent("keydown", {
      key: "Escape",
      bubbles: true,
      cancelable: true,
    });

    document.dispatchEvent(preventedEscape);
    expect(preventedEscape.defaultPrevented).toBe(true);

    controller.removeEscapeListener();

    const allowedEscape = new KeyboardEvent("keydown", {
      key: "Escape",
      bubbles: true,
      cancelable: true,
    });

    document.dispatchEvent(allowedEscape);
    expect(allowedEscape.defaultPrevented).toBe(false);
  });

  it("does not submit when selecting a disabled workflow", async () => {
    application = await startController({
      includeOutlet: false,
      workflows: [
        {
          id: "disabled",
          pipelineId: "pipeline-disabled",
          workflowVersion: "1.0.0",
          minSamplesConfigured: true,
          maxSamplesConfigured: false,
          minSamples: 2,
          maxSamples: "",
          minMessage: "Need at least 2",
          maxMessage: "",
          includeLimitMessage: true,
        },
      ],
    });

    const controller = controllerFor(application);
    const form = document.querySelector("form");

    form.requestSubmit = vi.fn();

    controller.selectWorkflow({
      currentTarget: workflowButton("disabled"),
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

  it("converts form data to JSON and resumes the Turbo request", async () => {
    application = await startController({ sampleCount: 4 });

    const form = document.querySelector("form");
    document.querySelector(
      '[data-workflow-selection-target="pipelineId"]',
    ).value = "pipeline-json";
    document.querySelector(
      '[data-workflow-selection-target="workflowVersion"]',
    ).value = "3.2.1";

    const resume = vi.fn();
    const event = dispatchBeforeFetch(form, resume);
    const payload = JSON.parse(event.detail.fetchOptions.body);

    expect(payload.pipeline_id).toBe("pipeline-json");
    expect(payload.workflow_version).toBe("3.2.1");
    expect(payload.sample_count).toBe(4);
    expect(event.detail.fetchOptions.headers["Content-Type"]).toBe(
      "application/json",
    );
    expect(resume).toHaveBeenCalledOnce();
  });

  it("clears the selection outlet only after a successful submit when clearSelectionValue is true", async () => {
    application = await startController({ sampleCount: 2 });
    const controller = controllerFor(application);
    const form = document.querySelector("form");
    const selectionOutlet = document.getElementById("samples-table");

    controller.clearSelectionValue = true;
    form.dispatchEvent(
      new CustomEvent("turbo:submit-end", {
        bubbles: true,
        detail: { success: true },
      }),
    );

    expect(selectionOutlet.dataset.cleared).toBe("true");

    selectionOutlet.removeAttribute("data-cleared");

    form.dispatchEvent(
      new CustomEvent("turbo:submit-end", {
        bubbles: true,
        detail: { success: false },
      }),
    );

    expect(selectionOutlet.dataset.cleared).toBeUndefined();
  });

  it("handles reorder edge cases without a list context", async () => {
    application = await startController();
    const controller = controllerFor(application);

    expect(() => controller.reorderWorkflows([])).not.toThrow();

    const detachedWorkflow = document.createElement("button");
    expect(() =>
      controller.reorderWorkflows([
        { workflow: detachedWorkflow, isDisabled: false },
      ]),
    ).not.toThrow();

    const list = document.createElement("ul");
    const row = document.createElement("div");
    const workflow = document.createElement("button");
    row.appendChild(workflow);
    list.appendChild(row);
    document.body.appendChild(list);

    expect(() =>
      controller.reorderWorkflows([{ workflow, isDisabled: false }]),
    ).not.toThrow();
  });

  it("disconnect removes event listeners for form submissions and escape handling", async () => {
    application = await startController();
    const controller = controllerFor(application);
    const form = document.querySelector("form");

    controller.preventClosingDialog();

    const escapeBeforeStop = new KeyboardEvent("keydown", {
      key: "Escape",
      bubbles: true,
      cancelable: true,
    });
    document.dispatchEvent(escapeBeforeStop);
    expect(escapeBeforeStop.defaultPrevented).toBe(true);

    controller.disconnect();

    const escapeAfterDisconnect = new KeyboardEvent("keydown", {
      key: "Escape",
      bubbles: true,
      cancelable: true,
    });
    document.dispatchEvent(escapeAfterDisconnect);
    expect(escapeAfterDisconnect.defaultPrevented).toBe(false);

    const resumeAfterDisconnect = vi.fn();
    const event = dispatchBeforeFetch(form, resumeAfterDisconnect);
    expect(event.detail.fetchOptions.body).toBeUndefined();
    expect(resumeAfterDisconnect).not.toHaveBeenCalled();

    application = undefined;
  });
});
