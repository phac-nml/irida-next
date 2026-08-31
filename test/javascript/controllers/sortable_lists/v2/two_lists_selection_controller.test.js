import { Application } from "@hotwired/stimulus";
import userEvent from "@testing-library/user-event";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import SortableListsController from "../../../../../app/javascript/controllers/sortable_lists/v2/two_lists_selection_controller.js";

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
} = {}) {
  document.body.innerHTML = `
    <div
      data-controller="sortable-lists--v2--two-lists-selection"
      data-sortable-lists--v2--two-lists-selection-selected-list-value="selected-list"
      data-sortable-lists--v2--two-lists-selection-available-list-value="available-list"
      data-sortable-lists--v2--two-lists-selection-field-name-value="fields[]"
    >
      ${
        withTemplateSelector
          ? `<select
              data-sortable-lists--v2--two-lists-selection-target="templateSelector"
              data-action="sortable-lists--v2--two-lists-selection#setTemplate"
            >
              <option value="none">None</option>
              <option value="template-1" data-fields='["Beta", "Template only"]'>Template 1</option>
            </select>`
          : ""
      }
      <ul
        id="available-list"
        data-title="Available"
        aria-required="false"
        data-action="change->sortable-lists--v2--two-lists-selection#handleSelectionChange"
      >
        ${available.join("")}
      </ul>
      <button
        type="button"
        data-sortable-lists--v2--two-lists-selection-target="addButton"
        data-action="click->sortable-lists--v2--two-lists-selection#addSelectionByAddButton"
      >Add</button>

      <ul
        id="selected-list"
        data-title="Selected"
        aria-required="true"
        data-action="change->sortable-lists--v2--two-lists-selection#handleSelectionChange"
      >
        ${selected.join("")}
      </ul>
      <button
        type="button"
        data-sortable-lists--v2--two-lists-selection-target="removeButton"
        data-action="click->sortable-lists--v2--two-lists-selection#removeSelectionByRemoveButton"
      >Remove</button>
      <button
        type="button"
        data-sortable-lists--v2--two-lists-selection-target="upButton"
        data-action="click->sortable-lists--v2--two-lists-selection#moveSelection"
      >Up</button>
      <button
        type="button"
        data-sortable-lists--v2--two-lists-selection-target="downButton"
        data-action="click->sortable-lists--v2--two-lists-selection#moveSelection"
      >Down</button>
      <button
        type="submit"
        data-sortable-lists--v2--two-lists-selection-target="submitBtn"
      >Submit</button>
      <div data-sortable-lists--v2--two-lists-selection-target="field"></div>
      <div
        aria-live="polite"
        data-sortable-lists--v2--two-lists-selection-target="ariaLiveUpdate"
        data-translations='${translations}'
      ></div>
      <template data-sortable-lists--v2--two-lists-selection-target="itemTemplate">
        <li class="border-b border-slate-200 px-4 py-2 last:border-b-0 dark:border-slate-600">
          <label class="flex cursor-pointer items-center gap-3 py-1 text-sm text-slate-900 dark:text-white">
            <input
              type="checkbox"
              class="h-4 w-4 rounded border-slate-300 text-primary-700 focus:ring-primary-600 dark:border-slate-600 dark:bg-slate-700"
            >
            <span></span>
          </label>
        </li>
      </template>
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

async function startController() {
  const application = Application.start();
  application.register(
    "sortable-lists--v2--two-lists-selection",
    SortableListsController,
  );
  await Promise.resolve();
  return application;
}

function getController(application) {
  const root = document.querySelector(
    '[data-controller="sortable-lists--v2--two-lists-selection"]',
  );

  return application.getControllerForElementAndIdentifier(
    root,
    "sortable-lists--v2--two-lists-selection",
  );
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

    expect(
      document.querySelector(
        '[data-sortable-lists--v2--two-lists-selection-target="addButton"]',
      ),
    ).toBeDisabled();
    expect(
      document.querySelector(
        '[data-sortable-lists--v2--two-lists-selection-target="removeButton"]',
      ),
    ).toBeDisabled();
    expect(
      document.querySelector(
        '[data-sortable-lists--v2--two-lists-selection-target="upButton"]',
      ),
    ).toBeDisabled();
    expect(
      document.querySelector(
        '[data-sortable-lists--v2--two-lists-selection-target="downButton"]',
      ),
    ).toBeDisabled();
    expect(
      document.querySelector(
        '[data-sortable-lists--v2--two-lists-selection-target="submitBtn"]',
      ),
    ).not.toBeDisabled();
  });

  it("moves checked available values into selected list", async () => {
    renderFixture();
    application = await startController();

    check("available-list", "Alpha");
    document
      .querySelector(
        '[data-sortable-lists--v2--two-lists-selection-target="addButton"]',
      )
      .click();

    expect(checkboxValues("available-list")).toEqual(["Beta"]);
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Alpha"]);
    expect(
      document.querySelector(
        '[data-sortable-lists--v2--two-lists-selection-target="ariaLiveUpdate"]',
      ),
    ).toHaveTextContent("The following item was moved to Selected: Alpha");
  });

  it("moves checked selected values back to available list", async () => {
    renderFixture();
    application = await startController();

    check("selected-list", "One");
    document
      .querySelector(
        '[data-sortable-lists--v2--two-lists-selection-target="removeButton"]',
      )
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
      '[data-sortable-lists--v2--two-lists-selection-target="upButton"]',
    );
    const downButton = document.querySelector(
      '[data-sortable-lists--v2--two-lists-selection-target="downButton"]',
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
      '[data-sortable-lists--v2--two-lists-selection-target="templateSelector"]',
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
      .querySelector(
        '[data-sortable-lists--v2--two-lists-selection-target="removeButton"]',
      )
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
        '[data-sortable-lists--v2--two-lists-selection-target="field"] input[type="hidden"]',
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
      '[data-sortable-lists--v2--two-lists-selection-target="addButton"]',
    );
    const removeButton = document.querySelector(
      '[data-sortable-lists--v2--two-lists-selection-target="removeButton"]',
    );

    availableCheckbox.focus();
    await user.keyboard("[Space]");
    expect(addButton).not.toBeDisabled();

    addButton.focus();
    await user.keyboard("[Enter]");
    expect(checkboxValues("selected-list")).toEqual(["One", "Two", "Alpha"]);

    const movedCheckbox = document.querySelector(
      '#selected-list input[type="checkbox"][value="Alpha"]',
    );
    movedCheckbox.focus();
    await user.keyboard("[Space]");
    expect(removeButton).not.toBeDisabled();

    removeButton.focus();
    await user.keyboard("[Space]");
    expect(checkboxValues("available-list")).toEqual(["Beta", "Alpha"]);
  });
});
