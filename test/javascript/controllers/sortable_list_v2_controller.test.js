import { Application } from "@hotwired/stimulus";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import SortableListsController from "../../../app/javascript/controllers/sortable_list_v2_controller.js";

const translations = JSON.stringify({
  move_down:
    "ITEM_PLACEHOLDER was moved down to position POSITION_PLACEHOLDER in LIST_PLACEHOLDER.",
  move_up:
    "ITEM_PLACEHOLDER was moved up to position POSITION_PLACEHOLDER in LIST_PLACEHOLDER.",
  moved_list_multiple:
    "The following items were moved to LIST_PLACEHOLDER: ITEMS_PLACEHOLDER",
  moved_list_single:
    "The following item was moved to LIST_PLACEHOLDER: ITEMS_PLACEHOLDER",
  words_connector: ", ",
  two_words_connector: " and ",
  last_word_connector: ", and ",
});

function listItem(value, checked = false) {
  return `
    <li>
      <label>
        <input type="checkbox" value="${value}" ${checked ? "checked" : ""}>
        <span>${value}</span>
      </label>
    </li>
  `;
}

function renderFixture({
  available = [listItem("Alpha"), listItem("Beta")],
  selected = [listItem("One"), listItem("Two")],
  withTemplateSelector = true,
  withListTitles = true,
  withLists = true,
  withField = true,
  withAddButton = true,
  withRemoveButton = true,
  withReorderButtons = true,
  withSubmit = true,
  withAriaLive = true,
  withItemTemplate = true,
  emptyItemTemplate = false,
} = {}) {
  const availableTitle = withListTitles ? 'data-title="Available"' : "";
  const selectedTitle = withListTitles ? 'data-title="Selected"' : "";

  const templateSelectorHtml = withTemplateSelector
    ? `<select
        data-sortable-list-v2-target="templateSelector"
        data-action="sortable-list-v2#setTemplate"
      >
        <option value="none">None</option>
        <option value="template-1" data-fields='["Beta", "Template only"]'>Template 1</option>
      </select>`
    : "";

  const availableListHtml = withLists
    ? `<ul
        id="available-list"
        ${availableTitle}
        data-required="false"
        data-action="change->sortable-list-v2#handleSelectionChange"
      >
        ${available.join("")}
      </ul>`
    : "";

  const addButtonHtml = withAddButton
    ? `<button
        type="button"
        data-sortable-list-v2-target="addButton"
        data-action="click->sortable-list-v2#addSelectionByAddButton"
      >Add</button>`
    : "";

  const selectedListHtml = withLists
    ? `<ul
        id="selected-list"
        ${selectedTitle}
        data-required="true"
        data-action="change->sortable-list-v2#handleSelectionChange"
      >
        ${selected.join("")}
      </ul>`
    : "";

  const removeButtonHtml = withRemoveButton
    ? `<button
        type="button"
        data-sortable-list-v2-target="removeButton"
        data-action="click->sortable-list-v2#removeSelectionByRemoveButton"
      >Remove</button>`
    : "";

  const reorderButtonsHtml = withReorderButtons
    ? `<button
        type="button"
        data-sortable-list-v2-target="upButton"
        data-action="click->sortable-list-v2#moveSelection"
      >Up</button>
      <button
        type="button"
        data-sortable-list-v2-target="downButton"
        data-action="click->sortable-list-v2#moveSelection"
      >Down</button>`
    : "";

  const submitButtonHtml = withSubmit
    ? `<button
        type="submit"
        data-sortable-list-v2-target="submitBtn"
      >Submit</button>`
    : "";

  const fieldHtml = withField
    ? `<div data-sortable-list-v2-target="field"></div>`
    : "";

  const ariaLiveHtml = withAriaLive
    ? `<div
        aria-live="polite"
        data-sortable-list-v2-target="ariaLiveUpdate"
        data-translations='${translations}'
      ></div>`
    : "";

  const itemTemplateHtml = withItemTemplate
    ? `<template data-sortable-list-v2-target="itemTemplate">${
        emptyItemTemplate
          ? ""
          : `<li class="border-b border-slate-200 px-4 py-2 last:border-b-0 dark:border-slate-600">
          <label class="flex cursor-pointer items-center gap-3 py-1 text-sm text-slate-900 dark:text-white">
            <input
              type="checkbox"
              class="h-4 w-4 rounded border-slate-300 text-primary-700 focus:ring-primary-600 dark:border-slate-600 dark:bg-slate-700"
            >
            <span></span>
          </label>
        </li>`
      }</template>`
    : "";

  document.body.innerHTML = `
    <div
      data-controller="sortable-list-v2"
      data-sortable-list-v2-selected-list-value="selected-list"
      data-sortable-list-v2-available-list-value="available-list"
      data-sortable-list-v2-field-name-value="fields[]"
    >
      ${templateSelectorHtml}
      ${availableListHtml}
      ${addButtonHtml}
      ${selectedListHtml}
      ${removeButtonHtml}
      ${reorderButtonsHtml}
      ${submitButtonHtml}
      ${fieldHtml}
      ${ariaLiveHtml}
      ${itemTemplateHtml}
    </div>
  `;
}

function checkboxValues(listId) {
  return Array.from(
    document.querySelectorAll(`#${listId} input[type="checkbox"]`),
  ).map((checkbox) => checkbox.value);
}

function check(listId, value) {
  const checkbox = Array.from(
    document.querySelectorAll(`#${listId} input[type="checkbox"]`),
  ).find((item) => item.value === value);

  checkbox.checked = true;
  checkbox.dispatchEvent(new Event("change", { bubbles: true }));
}

function uncheck(listId, value) {
  const checkbox = Array.from(
    document.querySelectorAll(`#${listId} input[type="checkbox"]`),
  ).find((item) => item.value === value);

  checkbox.checked = false;
  checkbox.dispatchEvent(new Event("change", { bubbles: true }));
}

async function startController() {
  const application = Application.start();
  application.register("sortable-list-v2", SortableListsController);
  await Promise.resolve();
  return application;
}

function getController(application) {
  const root = document.querySelector('[data-controller="sortable-list-v2"]');

  return application.getControllerForElementAndIdentifier(
    root,
    "sortable-list-v2",
  );
}

function expectAriaDisabled(element) {
  expect(element).toHaveAttribute("aria-disabled", "true");
}

function expectAriaEnabled(element) {
  expect(element).toHaveAttribute("aria-disabled", "false");
}

describe("sortable lists v2 two-lists selection controller", () => {
  let application;

  beforeEach(() => {
    window.requestAnimationFrame = (callback) => callback();
  });

  afterEach(() => {
    application?.stop();
  });

  it("initializes button states and required submit state", async () => {
    renderFixture();
    application = await startController();

    expectAriaDisabled(
      document.querySelector('[data-sortable-list-v2-target="addButton"]'),
    );
    expectAriaDisabled(
      document.querySelector('[data-sortable-list-v2-target="removeButton"]'),
    );
    expectAriaDisabled(
      document.querySelector('[data-sortable-list-v2-target="upButton"]'),
    );
    expectAriaDisabled(
      document.querySelector('[data-sortable-list-v2-target="downButton"]'),
    );
    expect(
      document.querySelector('[data-sortable-list-v2-target="submitBtn"]'),
    ).not.toBeDisabled();
  });

  it("moves checked available values into selected list", async () => {
    renderFixture();
    application = await startController();

    check("available-list", "Alpha");
    document
      .querySelector('[data-sortable-list-v2-target="addButton"]')
      .click();

    expect(checkboxValues("available-list")).toEqual(["Beta"]);
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Alpha"]);
    expect(
      document.querySelector('[data-sortable-list-v2-target="ariaLiveUpdate"]'),
    ).toHaveTextContent("The following item was moved to Selected: Alpha");
  });

  it("moves checked selected values back to available list", async () => {
    renderFixture();
    application = await startController();

    check("selected-list", "One");
    document
      .querySelector('[data-sortable-list-v2-target="removeButton"]')
      .click();

    expect(checkboxValues("available-list")).toEqual(["Alpha", "Beta", "One"]);
    expect(checkboxValues("selected-list")).toEqual(["Two"]);
  });

  it("reorders one checked selected value with up and down controls", async () => {
    renderFixture({
      selected: [listItem("One"), listItem("Two"), listItem("Three")],
    });
    application = await startController();

    check("selected-list", "Two");
    const upButton = document.querySelector(
      '[data-sortable-list-v2-target="upButton"]',
    );
    const downButton = document.querySelector(
      '[data-sortable-list-v2-target="downButton"]',
    );

    upButton.click();
    expect(checkboxValues("selected-list")).toEqual(["Two", "One", "Three"]);

    downButton.click();
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Three"]);
  });

  it("applies templates and syncs selector when list content changes", async () => {
    renderFixture();
    application = await startController();

    const selector = document.querySelector(
      '[data-sortable-list-v2-target="templateSelector"]',
    );

    selector.value = "template-1";
    selector.dispatchEvent(new Event("change", { bubbles: true }));

    expect(checkboxValues("selected-list")).toEqual(["Beta", "Template only"]);
    expect(checkboxValues("available-list")).toEqual(["Alpha", "One", "Two"]);

    const templateOnlyCheckbox = document.querySelector(
      '#selected-list input[type="checkbox"][value="Template only"]',
    );
    const templateOnlyLabel = templateOnlyCheckbox.closest("label");

    expect(templateOnlyCheckbox).toHaveAttribute("id");
    expect(templateOnlyLabel).toHaveAttribute("for", templateOnlyCheckbox.id);

    check("selected-list", "Template only");
    document
      .querySelector('[data-sortable-list-v2-target="removeButton"]')
      .click();

    expect(selector.value).toBe("none");
  });

  it("constructs hidden params from selected list and updates metadata listing", async () => {
    renderFixture({ withTemplateSelector: false });
    application = await startController();

    const controller = getController(application);
    controller.updateMetadataListing({
      detail: { content: { metadata: ["Beta", "Gamma", "Two"] } },
    });
    controller.constructParams();

    const hiddenValues = Array.from(
      document.querySelectorAll(
        '[data-sortable-list-v2-target="field"] input[type="hidden"]',
      ),
    ).map((input) => input.value);

    expect(checkboxValues("available-list")).toEqual(["Beta"]);
    expect(checkboxValues("selected-list")).toEqual(["Two", "Gamma"]);
    expect(hiddenValues).toEqual(["Two", "Gamma"]);
  });

  it("supports keyboard-only checkbox selection and button activation", async () => {
    renderFixture({ withTemplateSelector: false });
    application = await startController();

    const user = userEvent.setup();
    const availableCheckbox = document.querySelector(
      '#available-list input[type="checkbox"][value="Alpha"]',
    );
    const addButton = document.querySelector(
      '[data-sortable-list-v2-target="addButton"]',
    );
    const removeButton = document.querySelector(
      '[data-sortable-list-v2-target="removeButton"]',
    );

    availableCheckbox.focus();
    await user.keyboard("[Space]");
    expectAriaEnabled(addButton);

    addButton.focus();
    await user.keyboard("[Enter]");
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Alpha"]);

    const movedCheckbox = document.querySelector(
      '#selected-list input[type="checkbox"][value="Alpha"]',
    );
    movedCheckbox.focus();
    await user.keyboard("[Space]");
    expectAriaEnabled(removeButton);

    removeButton.focus();
    await user.keyboard("[Space]");
    expect(checkboxValues("available-list")).toEqual(["Beta", "Alpha"]);
  });

  it("moves focus to the transferred item after a move", async () => {
    renderFixture({ withTemplateSelector: false });
    application = await startController();

    check("available-list", "Alpha");
    document
      .querySelector('[data-sortable-list-v2-target="addButton"]')
      .click();

    const movedCheckbox = document.querySelector(
      '#selected-list input[type="checkbox"][value="Alpha"]',
    );

    expect(document.activeElement).toBe(movedCheckbox);
  });

  it("moves focus to the reordered item when the control becomes unavailable", async () => {
    renderFixture({
      selected: [listItem("One"), listItem("Two"), listItem("Three")],
      withTemplateSelector: false,
    });
    application = await startController();

    check("selected-list", "Two");
    const upButton = document.querySelector(
      '[data-sortable-list-v2-target="upButton"]',
    );

    upButton.click();

    expect(checkboxValues("selected-list")).toEqual(["Two", "One", "Three"]);
    expectAriaDisabled(upButton);

    const movedCheckbox = document.querySelector(
      '#selected-list input[type="checkbox"][value="Two"]',
    );

    expect(document.activeElement).toBe(movedCheckbox);
  });

  it("restores original values when the none template is selected", async () => {
    renderFixture();
    application = await startController();

    const selector = document.querySelector(
      '[data-sortable-list-v2-target="templateSelector"]',
    );

    selector.value = "template-1";
    selector.dispatchEvent(new Event("change", { bubbles: true }));
    expect(checkboxValues("selected-list")).toEqual(["Beta", "Template only"]);

    selector.value = "none";
    selector.dispatchEvent(new Event("change", { bubbles: true }));

    expect(checkboxValues("available-list")).toEqual([
      "Alpha",
      "Beta",
      "One",
      "Two",
    ]);
    expect(checkboxValues("selected-list")).toEqual([]);
    expect(selector.value).toBe("none");
  });

  it("does not reorder unless exactly one interior selected value is checked", async () => {
    renderFixture({
      selected: [listItem("One"), listItem("Two"), listItem("Three")],
    });
    application = await startController();

    const upButton = document.querySelector(
      '[data-sortable-list-v2-target="upButton"]',
    );
    const downButton = document.querySelector(
      '[data-sortable-list-v2-target="downButton"]',
    );
    const controller = getController(application);

    controller.moveSelection({ target: upButton });
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Three"]);
    expectAriaDisabled(upButton);
    expectAriaDisabled(downButton);

    check("selected-list", "One");
    check("selected-list", "Three");
    expectAriaDisabled(upButton);
    expectAriaDisabled(downButton);
    controller.moveSelection({ target: upButton });
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Three"]);
  });

  it("does not move the first selected value up or the last selected value down", async () => {
    renderFixture({
      selected: [listItem("One"), listItem("Two"), listItem("Three")],
    });
    application = await startController();

    const upButton = document.querySelector(
      '[data-sortable-list-v2-target="upButton"]',
    );
    const downButton = document.querySelector(
      '[data-sortable-list-v2-target="downButton"]',
    );
    const controller = getController(application);

    check("selected-list", "One");
    expectAriaDisabled(upButton);
    expectAriaEnabled(downButton);
    controller.moveSelection({ target: upButton });
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Three"]);

    uncheck("selected-list", "One");
    check("selected-list", "Three");
    expectAriaEnabled(upButton);
    expectAriaDisabled(downButton);
    controller.moveSelection({ target: downButton });
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Three"]);
  });

  it("does not move values when add or remove is invoked with no checked items", async () => {
    renderFixture();
    application = await startController();

    const controller = getController(application);
    controller.addSelectionByAddButton();
    controller.removeSelectionByRemoveButton();

    expect(checkboxValues("available-list")).toEqual(["Alpha", "Beta"]);
    expect(checkboxValues("selected-list")).toEqual(["One", "Two"]);
  });

  it("ignores metadata listing updates that are not an array", async () => {
    renderFixture({ withTemplateSelector: false });
    application = await startController();

    const controller = getController(application);
    controller.updateMetadataListing({ detail: { content: {} } });
    controller.updateMetadataListing({
      detail: { content: { metadata: "Beta" } },
    });

    expect(checkboxValues("available-list")).toEqual(["Alpha", "Beta"]);
    expect(checkboxValues("selected-list")).toEqual(["One", "Two"]);
  });

  it("disables required submit and resets the template when the selected list is empty", async () => {
    renderFixture({ selected: [] });
    application = await startController();

    expect(
      document.querySelector('[data-sortable-list-v2-target="submitBtn"]'),
    ).toBeDisabled();
    expect(
      document.querySelector(
        '[data-sortable-list-v2-target="templateSelector"]',
      ).value,
    ).toBe("none");
  });

  it("announces when multiple checked values move between lists", async () => {
    renderFixture();
    application = await startController();

    check("available-list", "Alpha");
    check("available-list", "Beta");
    document
      .querySelector('[data-sortable-list-v2-target="addButton"]')
      .click();

    expect(checkboxValues("available-list")).toEqual([]);
    expect(checkboxValues("selected-list")).toEqual([
      "One",
      "Two",
      "Alpha",
      "Beta",
    ]);
    expect(
      document.querySelector('[data-sortable-list-v2-target="ariaLiveUpdate"]'),
    ).toHaveTextContent(
      "The following items were moved to Selected: Alpha and Beta",
    );
  });

  it("announces moves without list titles when data-title is missing", async () => {
    renderFixture({ withListTitles: false, withTemplateSelector: false });
    application = await startController();

    check("available-list", "Alpha");
    document
      .querySelector('[data-sortable-list-v2-target="addButton"]')
      .click();

    expect(
      document.querySelector('[data-sortable-list-v2-target="ariaLiveUpdate"]'),
    ).toHaveTextContent("The following item was moved to : Alpha");
  });

  it("does nothing when the configured lists are missing", async () => {
    renderFixture({ withLists: false });
    application = await startController();

    const controller = getController(application);

    expect(() => controller.handleSelectionChange()).not.toThrow();
    expect(document.getElementById("available-list")).toBeNull();
    expect(document.getElementById("selected-list")).toBeNull();
  });

  it("skips param construction without a field target", async () => {
    renderFixture({ withField: false, withTemplateSelector: false });
    application = await startController();

    const controller = getController(application);

    expect(() => controller.constructParams()).not.toThrow();
    expect(
      document.querySelectorAll('[data-sortable-list-v2-target="field"]'),
    ).toHaveLength(0);
  });

  it("ignores template events without a usable option", async () => {
    renderFixture();
    application = await startController();

    const controller = getController(application);
    const emptySelect = document.createElement("select");

    controller.setTemplate({ target: null });
    controller.setTemplate({ target: emptySelect });

    expect(checkboxValues("available-list")).toEqual(["Alpha", "Beta"]);
    expect(checkboxValues("selected-list")).toEqual(["One", "Two"]);
  });

  it("treats a template option without fields as an empty selection", async () => {
    renderFixture();
    application = await startController();

    const selector = document.querySelector(
      '[data-sortable-list-v2-target="templateSelector"]',
    );
    const option = document.createElement("option");
    option.value = "template-empty";
    option.textContent = "Empty";
    selector.append(option);

    selector.value = "template-empty";
    selector.dispatchEvent(new Event("change", { bubbles: true }));

    expect(checkboxValues("selected-list")).toEqual([]);
    expect(checkboxValues("available-list")).toEqual([
      "Alpha",
      "Beta",
      "One",
      "Two",
    ]);
  });

  it("skips items it cannot rebuild when no item template is available", async () => {
    renderFixture({ withItemTemplate: false });
    application = await startController();

    const selector = document.querySelector(
      '[data-sortable-list-v2-target="templateSelector"]',
    );

    selector.value = "template-1";
    selector.dispatchEvent(new Event("change", { bubbles: true }));

    expect(checkboxValues("available-list")).toEqual([]);
    expect(checkboxValues("selected-list")).toEqual([]);
  });

  it("skips items the empty item template cannot build", async () => {
    renderFixture({ emptyItemTemplate: true, withTemplateSelector: false });
    application = await startController();

    const controller = getController(application);
    controller.updateMetadataListing({
      detail: { content: { metadata: ["Gamma"] } },
    });

    expect(checkboxValues("available-list")).toEqual([]);
    expect(checkboxValues("selected-list")).toEqual([]);
  });

  it("no-ops the disabled action targets when their buttons are absent", async () => {
    renderFixture({
      withAddButton: false,
      withRemoveButton: false,
      withReorderButtons: false,
      withSubmit: false,
      withTemplateSelector: false,
    });
    application = await startController();

    const controller = getController(application);

    check("available-list", "Alpha");
    controller.addSelectionByAddButton();
    controller.removeSelectionByRemoveButton();
    controller.moveSelection({ target: null });

    expect(checkboxValues("available-list")).toEqual(["Alpha", "Beta"]);
    expect(checkboxValues("selected-list")).toEqual(["One", "Two"]);
  });

  it("guards reordering when an enabled control has no single target", async () => {
    renderFixture({
      selected: [listItem("One"), listItem("Two"), listItem("Three")],
      withTemplateSelector: false,
    });
    application = await startController();

    const controller = getController(application);
    const upButton = document.querySelector(
      '[data-sortable-list-v2-target="upButton"]',
    );

    // Force the control enabled to reach the internal guards that the disabled
    // state would normally short-circuit.
    upButton.setAttribute("aria-disabled", "false");
    controller.moveSelection({ target: upButton });
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Three"]);

    // Exactly one checked item, but it is already at the edge (no target).
    check("selected-list", "One");
    upButton.setAttribute("aria-disabled", "false");
    controller.moveSelection({ target: upButton });
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Three"]);
  });

  it("does not move anything when an enabled add button has no checked items", async () => {
    renderFixture({ withTemplateSelector: false });
    application = await startController();

    const controller = getController(application);
    const addButton = document.querySelector(
      '[data-sortable-list-v2-target="addButton"]',
    );

    // Force the button enabled even though nothing is checked to exercise the
    // guard inside the move routine.
    addButton.setAttribute("aria-disabled", "false");
    controller.addSelectionByAddButton();

    expect(checkboxValues("available-list")).toEqual(["Alpha", "Beta"]);
    expect(checkboxValues("selected-list")).toEqual(["One", "Two"]);
  });

  it("keeps focus on the reorder control while further moves stay possible", async () => {
    renderFixture({
      selected: [
        listItem("One"),
        listItem("Two"),
        listItem("Three"),
        listItem("Four"),
      ],
      withTemplateSelector: false,
    });
    application = await startController();

    check("selected-list", "Two");
    const downButton = document.querySelector(
      '[data-sortable-list-v2-target="downButton"]',
    );

    downButton.focus();
    downButton.click();

    expect(checkboxValues("selected-list")).toEqual([
      "One",
      "Three",
      "Two",
      "Four",
    ]);
    expectAriaEnabled(downButton);
    // Focus is left on the still-actionable control rather than the moved item.
    expect(document.activeElement).toBe(downButton);
  });

  it("dedupes values shared between both lists when tracking originals", async () => {
    renderFixture({
      available: [listItem("Alpha"), listItem("Shared")],
      selected: [listItem("Shared"), listItem("Two")],
      withTemplateSelector: false,
    });
    application = await startController();

    const selector = document.querySelector(
      '[data-sortable-list-v2-target="templateSelector"]',
    );

    expect(selector).toBeNull();
    expect(checkboxValues("available-list")).toEqual(["Alpha", "Shared"]);
    expect(checkboxValues("selected-list")).toEqual(["Shared", "Two"]);
  });

  it("falls back to a random id when crypto.randomUUID is unavailable", async () => {
    renderFixture();
    application = await startController();

    const originalRandomUUID = crypto.randomUUID;
    Object.defineProperty(crypto, "randomUUID", {
      value: undefined,
      configurable: true,
    });

    try {
      const selector = document.querySelector(
        '[data-sortable-list-v2-target="templateSelector"]',
      );

      selector.value = "template-1";
      selector.dispatchEvent(new Event("change", { bubbles: true }));
    } finally {
      Object.defineProperty(crypto, "randomUUID", {
        value: originalRandomUUID,
        configurable: true,
      });
    }

    const templateOnlyCheckbox = document.querySelector(
      '#selected-list input[type="checkbox"][value="Template only"]',
    );

    expect(templateOnlyCheckbox).not.toBeNull();
    expect(templateOnlyCheckbox.id).toMatch(/^selected-list-item-/);
  });

  it("moves values silently when no aria-live region is present", async () => {
    renderFixture({ withAriaLive: false, withTemplateSelector: false });
    application = await startController();

    check("available-list", "Alpha");
    document
      .querySelector('[data-sortable-list-v2-target="addButton"]')
      .click();

    expect(checkboxValues("available-list")).toEqual(["Beta"]);
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Alpha"]);
    expect(
      document.querySelector('[data-sortable-list-v2-target="ariaLiveUpdate"]'),
    ).toBeNull();
  });
});
