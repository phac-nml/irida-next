import { afterEach, describe, expect, it } from "vitest";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";
import ExtendedDetailsController from "../../../../app/javascript/controllers/activities/extended_details_controller.js";

const P = "activities--extended-details";
const ARIA = {
  previous: { disabled: "prev-off", enabled: "prev-on" },
  next: { disabled: "next-off", enabled: "next-on" },
};

const TEMPLATES = `
  <template data-${P}-target="sampleCloneTableRow"><tr>
    <td><span data-${P}-target="sampleName"></span><span></span></td>
    <td><span data-${P}-target="sampleName"></span><span></span></td>
  </tr></template>
  <template data-${P}-target="workflowTableRow"><tr>
    <td><span data-${P}-target="workflowName"></span></td>
    <td><span data-${P}-target="workflowId"></span></td>
  </tr></template>
  <template data-${P}-target="importSampleTableRow"><tr>
    <td><span data-${P}-target="sampleName"></span><span></span></td>
    <td><span data-${P}-target="projectId"></span></td>
  </tr></template>
  <template data-${P}-target="groupSampleTransferTableRow"><tr>
    <td><span data-${P}-target="sampleName"></span><span></span></td>
    <td><span data-${P}-target="transferredFrom"></span><span></span></td>
    <td><span data-${P}-target="transferredTo"></span><span></span></td>
  </tr></template>
  <template data-${P}-target="destroySampleTableRow"><tr>
    <td><span data-${P}-target="sampleName"></span><span></span></td>
    <td><span data-${P}-target="projectName"></span><span></span></td>
  </tr></template>
  <template data-${P}-target="groupSampleCloneTableRow"><tr>
    <td><span data-${P}-target="projectId"></span><span></span></td>
    <td><span data-${P}-target="sampleName"></span><span></span></td>
    <td><span data-${P}-target="projectId"></span><span></span></td>
    <td><span data-${P}-target="sampleName"></span><span></span></td>
  </tr></template>
  <template data-${P}-target="listRow"><li>
    <span data-${P}-target="itemName"></span>
    <p><span></span><span></span></p>
  </li></template>`;

describe("activities ExtendedDetailsController", () => {
  let application;

  afterEach(async () => {
    await stopApplication(application);
  });

  async function mount({
    activityType = "",
    data = [],
    mode = "table",
    withData = true,
  } = {}) {
    const dataTarget = withData
      ? `<pre data-${P}-target="extendedDetailsData"></pre>`
      : "";
    const container =
      mode === "table"
        ? `<table><tbody data-${P}-target="tbody"></tbody></table>`
        : `<ul data-${P}-target="listContainer"></ul>`;

    document.body.innerHTML = `
      <div data-controller="${P}" data-${P}-activity-type-value="${activityType}">
        <button data-${P}-target="previousBtn"></button>
        <button data-${P}-target="nextBtn"></button>
        <div data-${P}-target="paginationContainer"></div>
        <div data-${P}-target="pagination"><span class="pager">pager</span></div>
        <div data-${P}-target="ariaLabels"></div>
        ${dataTarget}
        ${container}
        ${TEMPLATES}
      </div>`;

    const element = document.querySelector(`[data-controller='${P}']`);
    if (withData) {
      // jsdom does not implement innerText; the controller reads it directly.
      Object.defineProperty(
        element.querySelector(`[data-${P}-target='extendedDetailsData']`),
        "innerText",
        { configurable: true, value: JSON.stringify(data) },
      );
      Object.defineProperty(
        element.querySelector(`[data-${P}-target='ariaLabels']`),
        "innerText",
        { configurable: true, value: JSON.stringify(ARIA) },
      );
    }

    application = startApplication();
    application.register(P, ExtendedDetailsController);
    await Promise.resolve();

    return {
      element,
      tbody: element.querySelector(`[data-${P}-target='tbody']`),
      listContainer: element.querySelector(
        `[data-${P}-target='listContainer']`,
      ),
      previousBtn: element.querySelector(`[data-${P}-target='previousBtn']`),
      nextBtn: element.querySelector(`[data-${P}-target='nextBtn']`),
      paginationContainer: element.querySelector(
        `[data-${P}-target='paginationContainer']`,
      ),
      controller: application.getControllerForElementAndIdentifier(element, P),
    };
  }

  function cellText(tbody) {
    return Array.from(tbody.querySelectorAll("td")).map((td) =>
      Array.from(td.querySelectorAll("span")).map((span) => span.textContent),
    );
  }

  it("does nothing without an extended-details data target", async () => {
    const { element, tbody } = await mount({ withData: false });

    expect(element.hasAttribute("data-controller-connected")).toBe(false);
    expect(tbody.rows.length).toBe(0);
  });

  it("renders nothing when the data set is empty", async () => {
    const { element, tbody } = await mount({ data: [] });

    expect(element.getAttribute("data-controller-connected")).toBe("true");
    expect(tbody.rows.length).toBe(0);
  });

  it("renders sample clone rows by default", async () => {
    const { tbody } = await mount({
      data: [{ sample_name: "S1", sample_puid: "P1", clone_puid: "C1" }],
    });

    expect(cellText(tbody)).toEqual([
      ["S1", "P1"],
      ["S1", "C1"],
    ]);
  });

  it("renders workflow rows", async () => {
    const { tbody } = await mount({
      activityType: "workflow_execution_destroy",
      data: [{ workflow_name: "W1", workflow_id: "42" }],
    });

    expect(cellText(tbody)).toEqual([["W1"], ["42"]]);
  });

  it("renders imported sample and project rows", async () => {
    const { tbody } = await mount({
      activityType: "group_import_samples",
      data: [{ sample_name: "S1", sample_puid: "P1", project_puid: "PR1" }],
    });

    expect(cellText(tbody)).toEqual([["S1", "P1"], ["PR1"]]);
  });

  it("renders group sample transfer rows", async () => {
    const { tbody } = await mount({
      activityType: "group_sample_transfer",
      data: [
        {
          sample_name: "S1",
          sample_puid: "P1",
          source_project_name: "SRC",
          source_project_puid: "SP1",
          target_project_name: "TGT",
          target_project_puid: "TP1",
        },
      ],
    });

    expect(cellText(tbody)).toEqual([
      ["S1", "P1"],
      ["SRC", "SP1"],
      ["TGT", "TP1"],
    ]);
  });

  it("renders sample-and-project rows for destroy and bulk metadata update", async () => {
    const destroy = await mount({
      activityType: "group_samples_destroy",
      data: [
        {
          sample_name: "S1",
          sample_puid: "P1",
          project_name: "PROJ",
          project_puid: "PR1",
        },
      ],
    });
    expect(cellText(destroy.tbody)).toEqual([
      ["S1", "P1"],
      ["PROJ", "PR1"],
    ]);
    await stopApplication(application);

    const bulk = await mount({
      activityType: "group_bulk_metadata_update",
      data: [
        {
          sample_name: "S2",
          sample_puid: "P2",
          project_name: "PROJ2",
          project_puid: "PR2",
        },
      ],
    });
    expect(cellText(bulk.tbody)).toEqual([
      ["S2", "P2"],
      ["PROJ2", "PR2"],
    ]);
  });

  it("renders group sample clone rows", async () => {
    const { tbody } = await mount({
      activityType: "group_sample_clone",
      data: [
        {
          source_project_name: "SRC",
          source_project_puid: "SP1",
          sample_name: "S1",
          sample_puid: "P1",
          target_project_name: "TGT",
          target_project_puid: "TP1",
          clone_puid: "C1",
        },
      ],
    });

    expect(cellText(tbody)).toEqual([
      ["SRC", "SP1"],
      ["S1", "P1"],
      ["TGT", "TP1"],
      ["S1", "C1"],
    ]);
  });

  it("renders list items when there is no table body", async () => {
    const { listContainer } = await mount({
      mode: "list",
      data: [{ sample_name: "S1", sample_puid: "P1" }],
    });

    const item = listContainer.querySelector("li");
    expect(
      item.querySelector(`[data-${P}-target='itemName']`).textContent,
    ).toBe("S1");
    expect(item.querySelector("p > span:nth-child(2)").textContent).toBe("P1");
  });

  it("paginates through pages and toggles button states", async () => {
    const data = Array.from({ length: 11 }, (_, index) => ({
      sample_name: `S${index}`,
      sample_puid: `P${index}`,
      clone_puid: `C${index}`,
    }));
    const { tbody, previousBtn, nextBtn, paginationContainer, controller } =
      await mount({ data });

    // Page 1: 5 rows and the pagination markup is inserted. Button states are
    // only applied once the user navigates.
    expect(tbody.rows.length).toBe(5);
    expect(paginationContainer.querySelector(".pager")).not.toBeNull();

    // Page 2: middle page, both buttons enabled.
    controller.nextPage();
    expect(tbody.rows.length).toBe(5);
    expect(previousBtn.disabled).toBe(false);
    expect(nextBtn.disabled).toBe(false);

    // Page 3: last page, one row, next disabled.
    controller.nextPage();
    expect(tbody.rows.length).toBe(1);
    expect(nextBtn.disabled).toBe(true);
    expect(nextBtn.getAttribute("aria-label")).toBe("next-off");
    expect(previousBtn.disabled).toBe(false);
    expect(previousBtn.getAttribute("aria-label")).toBe("prev-on");

    // Back to the middle page.
    controller.previousPage();
    expect(tbody.rows.length).toBe(5);
    expect(previousBtn.disabled).toBe(false);
    expect(nextBtn.disabled).toBe(false);

    // Back to the first page: previous disabled, next enabled.
    controller.previousPage();
    expect(tbody.rows.length).toBe(5);
    expect(previousBtn.disabled).toBe(true);
    expect(previousBtn.getAttribute("aria-label")).toBe("prev-off");
    expect(nextBtn.disabled).toBe(false);
    expect(nextBtn.getAttribute("aria-label")).toBe("next-on");
  });

  it("paginates the list view", async () => {
    const data = Array.from({ length: 6 }, (_, index) => ({
      sample_name: `S${index}`,
      sample_puid: `P${index}`,
    }));
    const { listContainer, controller } = await mount({ mode: "list", data });

    expect(listContainer.querySelectorAll("li").length).toBe(5);

    controller.nextPage();
    expect(listContainer.querySelectorAll("li").length).toBe(1);
  });

  it("navigates a single-page data set without touching button states", async () => {
    const { tbody, previousBtn, controller } = await mount({
      data: [
        { sample_name: "S1", sample_puid: "P1", clone_puid: "C1" },
        { sample_name: "S2", sample_puid: "P2", clone_puid: "C2" },
      ],
    });

    expect(tbody.rows.length).toBe(2);
    expect(previousBtn.hasAttribute("aria-label")).toBe(false);

    controller.nextPage();
    expect(previousBtn.hasAttribute("aria-label")).toBe(false);
  });
});
