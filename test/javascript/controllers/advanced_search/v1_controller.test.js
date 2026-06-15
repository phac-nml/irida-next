import { Application } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import AdvancedSearchController from "../../../../app/javascript/controllers/advanced_search/v1_controller.js";
const closeDialogMock = vi.hoisted(() => vi.fn());

vi.mock("utilities/dialog", () => ({
  closeDialog: closeDialogMock,
}));

function renderFixture({ hasErrors = false, open = true } = {}) {
  document.body.innerHTML = `
    <div
      id="advanced-search"
      data-controller="advanced-search--v1"
      data-advanced-search--v1-has-errors-value="${hasErrors}"
      data-advanced-search--v1-open-value="${open}"
      data-advanced-search--v1-status-value="true"
    >
      <div data-controller="viral--dialog">
        <dialog open>
          <input aria-invalid="true">
        </dialog>
      </div>
      <template data-advanced-search--v1-target="searchGroupsTemplate"></template>
      <div data-advanced-search--v1-target="searchGroupsContainer"></div>
      <template data-advanced-search--v1-target="groupTemplate"></template>
      <template data-advanced-search--v1-target="conditionTemplate"></template>
      <template data-advanced-search--v1-target="emptySearchTemplate"></template>
      <template data-advanced-search--v1-target="listValueTemplate"></template>
      <template data-advanced-search--v1-target="listSelectValueTemplate"></template>
      <template data-advanced-search--v1-target="selectValueTemplate"></template>
      <template data-advanced-search--v1-target="valueTemplate"></template>
    </div>
  `;
}

async function startController() {
  const application = Application.start();
  application.register("advanced-search--v1", AdvancedSearchController);
  await Promise.resolve();
  return application;
}

describe("advanced search v1 controller", () => {
  let application;

  beforeEach(() => {
    vi.clearAllMocks();
    sessionStorage.setItem("advancedSearch:applyFilter", "1");
  });

  afterEach(() => {
    application?.stop();
  });

  it("closes the dialog host after a successful pending apply", async () => {
    renderFixture();
    application = await startController();

    const dialogHost = document.querySelector(
      '[data-controller="viral--dialog"]',
    );

    expect(closeDialogMock).toHaveBeenCalledWith(dialogHost, application);
    expect(sessionStorage.getItem("advancedSearch:applyFilter")).toBeNull();
  });

  it("closes the dialog host after a successful pending apply when open is false", async () => {
    renderFixture({ open: false });
    application = await startController();

    const dialogHost = document.querySelector(
      '[data-controller="viral--dialog"]',
    );

    expect(closeDialogMock).toHaveBeenCalledWith(dialogHost, application);
    expect(sessionStorage.getItem("advancedSearch:applyFilter")).toBeNull();
  });

  it("keeps the dialog open when a pending apply returns errors", async () => {
    renderFixture({ hasErrors: true });
    application = await startController();

    expect(closeDialogMock).not.toHaveBeenCalled();
    expect(sessionStorage.getItem("advancedSearch:applyFilter")).toBeNull();
  });

  it("removes turbo-permanent before submitting an apply filter", async () => {
    sessionStorage.removeItem("advancedSearch:applyFilter");
    renderFixture();
    const dialogHost = document.querySelector(
      '[data-controller="viral--dialog"]',
    );
    dialogHost?.setAttribute("data-turbo-permanent", "");

    application = await startController();

    const controller = application.getControllerForElementAndIdentifier(
      document.getElementById("advanced-search"),
      "advanced-search--v1",
    );

    expect(dialogHost?.hasAttribute("data-turbo-permanent")).toBe(true);

    controller.markApplyFilter();

    expect(dialogHost?.hasAttribute("data-turbo-permanent")).toBe(false);
    expect(dialogHost?.hasAttribute("data-preserve-open-on-disconnect")).toBe(
      true,
    );
    expect(sessionStorage.getItem("advancedSearch:applyFilter")).toBe("1");
  });
});
