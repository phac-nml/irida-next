import { Application } from "@hotwired/stimulus";
import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import SortableListsController from "../../../../../app/javascript/controllers/sortable_lists/v1/two_lists_selection_controller.js";

const translations = JSON.stringify({
  move_down:
    "ITEM_PLACEHOLDER was moved down to position POSITION_PLACEHOLDER in LIST_PLACEHOLDER.",
  move_up:
    "ITEM_PLACEHOLDER was moved up to position POSITION_PLACEHOLDER in LIST_PLACEHOLDER.",
  moved_list_multiple:
    "The following items were moved to LIST_PLACEHOLDER: ITEMS_PLACEHOLDER",
  moved_list_single:
    "The following item was moved to LIST_PLACEHOLDER: ITEMS_PLACEHOLDER",
});

function option(id, text, selected = false) {
  return `
    <li
      id="${id}"
      data-action="click->sortable-lists--v1--two-lists-selection#handleClick"
      role="option"
      tabindex="-1"
      aria-selected="${selected}"
    >
      <span aria-hidden="true"></span>
      <span>${text}</span>
    </li>
  `;
}

function renderFixture({
  available = [
    option("available-alpha", "Alpha"),
    option("available-beta", "Beta"),
    option("available-alpine", "Alpine"),
    option("available-gamma", "Gamma"),
  ],
  selected = [
    option("selected-one", "One"),
    option("selected-two", "Two"),
    option("selected-three", "Three"),
  ],
  templateSelector = false,
  submit = false,
  ariaLive = true,
  titles = true,
} = {}) {
  document.body.innerHTML = `
    <div
      data-controller="sortable-lists--v1--two-lists-selection"
      data-sortable-lists--v1--two-lists-selection-selected-list-value="selected-list"
      data-sortable-lists--v1--two-lists-selection-available-list-value="available-list"
      data-sortable-lists--v1--two-lists-selection-field-name-value="fields[]"
    >
      ${
        templateSelector
          ? `<select
              data-sortable-lists--v1--two-lists-selection-target="templateSelector"
              data-action="sortable-lists--v1--two-lists-selection#setTemplate"
            >
              <option value="none">None</option>
              <option value="custom" data-fields='["Template only"]'>Custom</option>
              <option value="existing" data-fields='["Alpha","Beta"]'>Existing</option>
            </select>`
          : ""
      }
      <ul
        id="available-list"
        role="listbox"
        tabindex="0"
        aria-labelledby="available-label"
        aria-describedby="instructions"
        aria-required="false"
        aria-multiselectable="true"
        data-action="focus->sortable-lists--v1--two-lists-selection#handleListFocus blur->sortable-lists--v1--two-lists-selection#handleListBlur keydown->sortable-lists--v1--two-lists-selection#handleKeyboardInput"
        ${titles ? 'data-title="Available list"' : ""}
        >${available.join("")}</ul>
      <button
        type="button"
        aria-disabled="true"
        aria-controls="available-list selected-list"
        data-sortable-lists--v1--two-lists-selection-target="addButton"
        data-action="click->sortable-lists--v1--two-lists-selection#addSelectionByAddButton"
      >Add</button>
      <ul
        id="selected-list"
        role="listbox"
        tabindex="0"
        aria-labelledby="selected-label"
        aria-describedby="instructions selected-list-required"
        aria-required="true"
        aria-multiselectable="true"
        data-action="focus->sortable-lists--v1--two-lists-selection#handleListFocus blur->sortable-lists--v1--two-lists-selection#handleListBlur keydown->sortable-lists--v1--two-lists-selection#handleKeyboardInput"
        ${titles ? 'data-title="Selected list"' : ""}
        >${selected.join("")}</ul>
      <button
        type="button"
        aria-disabled="true"
        aria-controls="available-list selected-list"
        data-sortable-lists--v1--two-lists-selection-target="removeButton"
        data-action="click->sortable-lists--v1--two-lists-selection#removeSelectionByRemoveButton"
      >Remove</button>
      <button
        type="button"
        aria-disabled="true"
        aria-controls="selected-list"
        data-sortable-lists--v1--two-lists-selection-target="upButton"
        data-action="click->sortable-lists--v1--two-lists-selection#moveSelection"
      >Up</button>
      <button
        type="button"
        aria-disabled="true"
        aria-controls="selected-list"
        data-sortable-lists--v1--two-lists-selection-target="downButton"
        data-action="click->sortable-lists--v1--two-lists-selection#moveSelection"
      >Down</button>
      ${
        submit
          ? `<div
              class="hidden"
              data-sortable-lists--v1--two-lists-selection-target="field"
            ></div>
            <button
              type="submit"
              disabled
              aria-disabled="true"
              data-sortable-lists--v1--two-lists-selection-target="submitBtn"
              data-action="click->sortable-lists--v1--two-lists-selection#constructParams"
            >Submit</button>`
          : ""
      }
      ${
        ariaLive
          ? `<div
              aria-live="polite"
              data-sortable-lists--v1--two-lists-selection-target="ariaLiveUpdate"
              data-translations='${translations}'
            ></div>`
          : ""
      }
      <template data-sortable-lists--v1--two-lists-selection-target="checkmarkTemplate">
        <span>✓</span>
      </template>
      <template data-sortable-lists--v1--two-lists-selection-target="hiddenCheckmarkTemplate">
        <span aria-hidden="true"></span>
      </template>
      <template data-sortable-lists--v1--two-lists-selection-target="itemTemplate">
        ${option("template-item", "NAME_HERE")}
      </template>
    </div>
  `;
}

function keydown(list, key, options = {}) {
  list.dispatchEvent(
    new KeyboardEvent("keydown", {
      key,
      bubbles: true,
      cancelable: true,
      ...options,
    }),
  );
}

function click(node, options = {}) {
  node.dispatchEvent(
    new MouseEvent("click", { bubbles: true, cancelable: true, ...options }),
  );
}

function target(name) {
  return document.querySelector(
    `[data-sortable-lists--v1--two-lists-selection-target="${name}"]`,
  );
}

function fieldValues() {
  return Array.from(target("field").querySelectorAll("input")).map(
    (input) => input.value,
  );
}

function list(id) {
  return document.getElementById(id);
}

function activeId(listbox) {
  return listbox.getAttribute("aria-activedescendant");
}

function selectedIds(listbox) {
  return Array.from(listbox.querySelectorAll('[aria-selected="true"]')).map(
    (item) => item.id,
  );
}

function optionIds(listbox) {
  return Array.from(listbox.querySelectorAll('[role="option"]')).map(
    (item) => item.id,
  );
}

function activeOptionIds(listbox) {
  return Array.from(listbox.querySelectorAll("[data-active-option]")).map(
    (item) => item.id,
  );
}

async function startController() {
  const application = Application.start();
  application.register(
    "sortable-lists--v1--two-lists-selection",
    SortableListsController,
  );
  await Promise.resolve();
  return application;
}

function controllerInstance(app) {
  return app.getControllerForElementAndIdentifier(
    document.querySelector(
      '[data-controller~="sortable-lists--v1--two-lists-selection"]',
    ),
    "sortable-lists--v1--two-lists-selection",
  );
}

function itemTexts(id) {
  return Array.from(list(id).querySelectorAll("li")).map(
    (item) => item.lastElementChild.textContent,
  );
}

describe("sortable lists two-lists selection controller", () => {
  let application;

  beforeEach(() => {
    window.requestAnimationFrame = (callback) => setTimeout(callback, 0);
  });

  afterEach(() => {
    application?.stop();
    vi.useRealTimers();
  });

  it("sets each listbox as the tab stop without an active descendant until focus", async () => {
    renderFixture({
      selected: [
        option("selected-one", "One"),
        option("selected-two", "Two", true),
        option("selected-three", "Three"),
      ],
    });

    application = await startController();

    expect(list("available-list")).toHaveAttribute("tabindex", "0");
    expect(list("available-list")).not.toHaveAttribute("aria-activedescendant");
    expect(list("selected-list")).not.toHaveAttribute("aria-activedescendant");

    list("available-list").focus();
    expect(activeId(list("available-list"))).toBe("available-alpha");

    list("selected-list").focus();
    expect(activeId(list("selected-list"))).toBe("selected-two");
  });

  it("clears active option styling when a listbox loses focus", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    expect(activeOptionIds(availableList)).toEqual(["available-alpha"]);

    availableList.blur();
    expect(activeOptionIds(availableList)).toEqual([]);
  });

  it("keeps an empty listbox focusable without a stale active descendant", async () => {
    renderFixture({ available: [], selected: [] });

    application = await startController();

    expect(list("available-list")).toHaveAttribute("tabindex", "0");
    expect(list("available-list")).toHaveAttribute("aria-activedescendant", "");
  });

  it("moves focus with arrows and Home/End without changing selection", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();

    keydown(availableList, "ArrowDown");
    expect(activeId(availableList)).toBe("available-beta");
    keydown(availableList, "End");
    expect(activeId(availableList)).toBe("available-gamma");
    keydown(availableList, "Home");
    expect(activeId(availableList)).toBe("available-alpha");
    expect(selectedIds(availableList)).toEqual([]);
  });

  it("supports Space, Shift+Arrow, Shift+Space, and Ctrl/Meta+A selection", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();

    keydown(availableList, " ");
    expect(selectedIds(availableList)).toEqual(["available-alpha"]);

    keydown(availableList, "ArrowDown", { shiftKey: true });
    expect(activeId(availableList)).toBe("available-beta");
    expect(selectedIds(availableList)).toEqual([
      "available-alpha",
      "available-beta",
    ]);

    keydown(availableList, "ArrowDown");
    keydown(availableList, " ", { shiftKey: true });
    expect(selectedIds(availableList)).toEqual([
      "available-alpha",
      "available-beta",
      "available-alpine",
    ]);

    keydown(availableList, "a", { ctrlKey: true });
    expect(selectedIds(availableList)).toEqual([
      "available-alpha",
      "available-beta",
      "available-alpine",
      "available-gamma",
    ]);
    keydown(availableList, "a", { metaKey: true });
    expect(selectedIds(availableList)).toEqual([]);
  });

  it("supports Ctrl+Shift+Home and Ctrl+Shift+End range selection", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();

    keydown(availableList, "End");
    keydown(availableList, "Home", { ctrlKey: true, shiftKey: true });
    expect(selectedIds(availableList)).toEqual([
      "available-alpha",
      "available-beta",
      "available-alpine",
      "available-gamma",
    ]);

    keydown(availableList, "a", { ctrlKey: true });
    keydown(availableList, "Home");
    keydown(availableList, "End", { ctrlKey: true, shiftKey: true });
    expect(selectedIds(availableList)).toEqual([
      "available-alpha",
      "available-beta",
      "available-alpine",
      "available-gamma",
    ]);
  });

  it("supports single-character and multi-character type-ahead", async () => {
    vi.useFakeTimers();
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();

    keydown(availableList, "g");
    expect(activeId(availableList)).toBe("available-gamma");

    vi.advanceTimersByTime(500);
    keydown(availableList, "a");
    expect(activeId(availableList)).toBe("available-alpha");

    keydown(availableList, "l");
    expect(activeId(availableList)).toBe("available-alpine");
  });

  it("moves selected items with Enter and Delete while preserving useful focus", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    const selectedList = list("selected-list");
    availableList.focus();

    keydown(availableList, " ");
    keydown(availableList, "Enter");
    expect(optionIds(availableList)).toEqual([
      "available-beta",
      "available-alpine",
      "available-gamma",
    ]);
    expect(optionIds(selectedList)).toContain("available-alpha");
    expect(activeId(availableList)).toBe("available-beta");
    expect(document.activeElement).toBe(availableList);

    selectedList.focus();
    keydown(selectedList, "End");
    keydown(selectedList, " ");
    keydown(selectedList, "Delete");
    expect(optionIds(selectedList)).not.toContain("available-alpha");
    expect(optionIds(availableList)).toContain("available-alpha");
    expect(document.activeElement).toBe(selectedList);
  });

  it("clears stale active option state when moving multiple selected items", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    const selectedList = list("selected-list");
    availableList.focus();

    keydown(availableList, "ArrowDown");
    keydown(availableList, " ");
    keydown(availableList, "ArrowDown");
    keydown(availableList, " ");
    keydown(availableList, "Enter");

    expect(activeOptionIds(availableList)).toEqual(["available-gamma"]);
    expect(selectedList.querySelector("#available-beta")).not.toHaveAttribute(
      "data-active-option",
    );
    expect(selectedList.querySelector("#available-alpine")).not.toHaveAttribute(
      "data-active-option",
    );

    selectedList.focus();
    expect(activeOptionIds(selectedList)).toHaveLength(1);
  });

  it("clears active descendant when template-only items are removed from the available list", async () => {
    renderFixture({ templateSelector: true });
    application = await startController();

    const availableList = list("available-list");
    const selectedList = list("selected-list");
    const selector = document.querySelector(
      '[data-sortable-lists--v1--two-lists-selection-target="templateSelector"]',
    );

    selector.value = "custom";
    selector.dispatchEvent(new Event("change", { bubbles: true }));

    const templateOnlyOption = selectedList.querySelector(
      '[role="option"]:last-child',
    );
    expect(templateOnlyOption).toHaveTextContent("Template only");

    selectedList.focus();
    keydown(selectedList, "End");
    keydown(selectedList, " ");
    keydown(selectedList, "Delete");

    availableList.focus();
    expect(availableList).toHaveAttribute(
      "aria-activedescendant",
      "available-alpha",
    );
    expect(document.getElementById(activeId(availableList)).parentNode).toBe(
      availableList,
    );
    expect(availableList).not.toHaveTextContent("Template only");
  });

  it("reorders one selected item with Alt+Arrow and announces the change", async () => {
    vi.useFakeTimers();
    renderFixture({
      selected: [
        option("selected-one", "One"),
        option("selected-two", "Two", true),
        option("selected-three", "Three"),
      ],
    });
    application = await startController();

    const selectedList = list("selected-list");
    selectedList.focus();

    keydown(selectedList, "ArrowUp", { altKey: true });

    expect(optionIds(selectedList)).toEqual([
      "selected-two",
      "selected-one",
      "selected-three",
    ]);
    expect(activeId(selectedList)).toBe("selected-two");
    vi.runAllTimers();
    expect(
      document.querySelector(
        '[data-sortable-lists--v1--two-lists-selection-target="ariaLiveUpdate"]',
      ),
    ).toHaveTextContent("Two was moved up to position 1 in Selected list.");
  });

  it("announces each add and remove action via the aria-live region", async () => {
    vi.useFakeTimers();
    renderFixture({
      available: [option("available-foo", "foo")],
      selected: [],
    });
    application = await startController();

    const availableList = list("available-list");
    const selectedList = list("selected-list");
    const addButton = document.querySelector(
      '[data-sortable-lists--v1--two-lists-selection-target="addButton"]',
    );
    const removeButton = document.querySelector(
      '[data-sortable-lists--v1--two-lists-selection-target="removeButton"]',
    );
    const ariaLive = document.querySelector(
      '[data-sortable-lists--v1--two-lists-selection-target="ariaLiveUpdate"]',
    );

    availableList.focus();
    keydown(availableList, " ");
    addButton.focus();
    addButton.click();
    vi.runAllTimers();
    expect(ariaLive).toHaveTextContent(
      "The following item was moved to Selected list: foo",
    );
    expect(document.activeElement).toBe(addButton);
    expect(addButton).toHaveAttribute("aria-disabled", "true");

    selectedList.focus();
    keydown(selectedList, " ");
    removeButton.focus();
    removeButton.click();
    vi.runAllTimers();
    expect(ariaLive).toHaveTextContent(
      "The following item was moved to Available list: foo",
    );
    expect(document.activeElement).toBe(removeButton);
    expect(removeButton).toHaveAttribute("aria-disabled", "true");

    availableList.focus();
    keydown(availableList, " ");
    addButton.focus();
    addButton.click();
    vi.runAllTimers();
    expect(ariaLive).toHaveTextContent(
      "The following item was moved to Selected list: foo",
    );
    expect(document.activeElement).toBe(addButton);
    expect(addButton).toHaveAttribute("aria-disabled", "true");
  });

  it("builds hidden inputs for the selected list when submitting", async () => {
    renderFixture({ submit: true });
    application = await startController();

    const submitBtn = target("submitBtn");
    submitBtn.setAttribute("aria-disabled", "false");
    click(submitBtn);

    expect(fieldValues()).toEqual(["One", "Two", "Three"]);
  });

  it("blocks submit clicks while the submit button is aria-disabled", async () => {
    renderFixture({ submit: true });
    application = await startController();

    const submitBtn = target("submitBtn");
    submitBtn.setAttribute("aria-disabled", "true");
    const event = new MouseEvent("click", { bubbles: true, cancelable: true });
    submitBtn.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(true);
  });

  it("allows submit clicks once the submit button is enabled", async () => {
    renderFixture({ submit: true });
    application = await startController();

    const submitBtn = target("submitBtn");
    submitBtn.setAttribute("aria-disabled", "false");
    const event = new MouseEvent("click", { bubbles: true, cancelable: true });
    submitBtn.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
  });

  it("stops guarding submit clicks after the controller disconnects", async () => {
    renderFixture({ submit: true });
    application = await startController();

    const submitBtn = target("submitBtn");
    submitBtn.setAttribute("aria-disabled", "true");
    controllerInstance(application).disconnect();

    const event = new MouseEvent("click", { bubbles: true, cancelable: true });
    submitBtn.dispatchEvent(event);

    expect(event.defaultPrevented).toBe(false);
  });

  it("toggles the native submit disabled state with the required list contents", async () => {
    renderFixture({ submit: true, selected: [] });
    application = await startController();

    const submitBtn = target("submitBtn");
    expect(submitBtn.disabled).toBe(true);

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, " ");
    keydown(availableList, "Enter");

    expect(submitBtn.disabled).toBe(false);
  });

  it("toggles selection on click and tracks the active option", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    const alpha = document.getElementById("available-alpha");

    click(alpha);
    expect(selectedIds(availableList)).toEqual(["available-alpha"]);
    expect(activeId(availableList)).toBe("available-alpha");

    click(alpha);
    expect(selectedIds(availableList)).toEqual([]);
  });

  it("selects a range from the last clicked option on shift-click", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    click(document.getElementById("available-alpha"));
    click(document.getElementById("available-gamma"), { shiftKey: true });

    expect(selectedIds(availableList)).toEqual([
      "available-alpha",
      "available-beta",
      "available-alpine",
      "available-gamma",
    ]);
  });

  it("selects from the top of the list on shift-click without a prior click", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    click(document.getElementById("available-alpine"), { shiftKey: true });

    expect(selectedIds(availableList)).toEqual([
      "available-alpha",
      "available-beta",
      "available-alpine",
    ]);
  });

  it("ignores clicks that are not on a listbox option", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    controllerInstance(application).handleClick({ target: document.body });

    expect(selectedIds(availableList)).toEqual([]);
    expect(activeOptionIds(availableList)).toEqual([]);
  });

  it("reorders a selected item with the up and down buttons", async () => {
    renderFixture();
    application = await startController();

    const selectedList = list("selected-list");
    selectedList.focus();
    keydown(selectedList, "ArrowDown");
    keydown(selectedList, " ");

    click(target("downButton"));
    expect(optionIds(selectedList)).toEqual([
      "selected-one",
      "selected-three",
      "selected-two",
    ]);

    click(target("upButton"));
    expect(optionIds(selectedList)).toEqual([
      "selected-one",
      "selected-two",
      "selected-three",
    ]);
  });

  it("ignores move button clicks while the button is disabled", async () => {
    renderFixture();
    application = await startController();

    const upButton = target("upButton");
    expect(upButton).toHaveAttribute("aria-disabled", "true");

    click(upButton);
    expect(optionIds(list("selected-list"))).toEqual([
      "selected-one",
      "selected-two",
      "selected-three",
    ]);
  });

  it("does nothing when a move button has no option to swap with", async () => {
    renderFixture();
    application = await startController();

    const selectedList = list("selected-list");
    selectedList.focus();
    keydown(selectedList, " ");

    const upButton = target("upButton");
    upButton.setAttribute("aria-disabled", "false");
    click(upButton);

    expect(optionIds(selectedList)).toEqual([
      "selected-one",
      "selected-two",
      "selected-three",
    ]);
  });

  it("reconciles the lists when metadata is pushed dynamically", async () => {
    renderFixture({
      available: [
        option("available-foo", "foo"),
        option("available-extra", "extra"),
      ],
      selected: [
        option("selected-keep", "keep"),
        option("selected-drop", "drop"),
      ],
    });
    application = await startController();

    controllerInstance(application).updateMetadataListing({
      detail: { content: { metadata: ["foo", "keep", "new"] } },
    });

    expect(itemTexts("available-list")).toEqual(["foo"]);
    expect(itemTexts("selected-list")).toEqual(["keep", "new"]);
  });

  it("logs and returns when the template selection target is missing", async () => {
    renderFixture();
    application = await startController();
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    controllerInstance(application).setTemplate({ target: null });

    expect(errorSpy).toHaveBeenCalledWith(
      "Template selection target not found",
    );
  });

  it("logs and returns when no template option is selected", async () => {
    renderFixture();
    application = await startController();
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    const emptySelect = document.createElement("select");
    controllerInstance(application).setTemplate({ target: emptySelect });

    expect(errorSpy).toHaveBeenCalledWith("No template option selected");
  });

  it("logs the caught error when template fields are malformed", async () => {
    renderFixture();
    application = await startController();
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    const select = document.createElement("select");
    const brokenOption = document.createElement("option");
    brokenOption.value = "custom";
    brokenOption.dataset.fields = "{not valid json";
    select.append(brokenOption);
    select.selectedIndex = 0;

    controllerInstance(application).setTemplate({ target: select });

    expect(errorSpy).toHaveBeenCalledWith(
      "Error setting template:",
      expect.any(Error),
    );
  });

  it("ignores keyboard input dispatched on non-listbox elements", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    controllerInstance(application).handleKeyboardInput({
      target: document.body,
    });

    expect(selectedIds(availableList)).toEqual([]);
  });

  it("does not move items when Enter/Delete target the wrong list", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    const selectedList = list("selected-list");

    selectedList.focus();
    keydown(selectedList, " ");
    keydown(selectedList, "Enter");
    expect(optionIds(selectedList)).toContain("selected-one");

    availableList.focus();
    keydown(availableList, " ");
    keydown(availableList, "Delete");
    expect(optionIds(availableList)).toContain("available-alpha");
  });

  it("ignores add and remove button clicks while they are disabled", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    const selectedList = list("selected-list");

    click(target("addButton"));
    click(target("removeButton"));

    expect(optionIds(availableList)).toEqual([
      "available-alpha",
      "available-beta",
      "available-alpine",
      "available-gamma",
    ]);
    expect(optionIds(selectedList)).toEqual([
      "selected-one",
      "selected-two",
      "selected-three",
    ]);
  });

  it("treats moving an empty selection as a no-op", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, "Enter");

    expect(optionIds(availableList)).toEqual([
      "available-alpha",
      "available-beta",
      "available-alpine",
      "available-gamma",
    ]);
  });

  it("searches upward for the next focus target when trailing options are selected", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, "ArrowDown");
    keydown(availableList, " ");
    keydown(availableList, "ArrowDown");
    keydown(availableList, " ");
    keydown(availableList, "ArrowDown");
    keydown(availableList, " ");
    keydown(availableList, "Enter");

    expect(activeId(availableList)).toBe("available-alpha");
  });

  it("clears focus when every option is moved out of a list", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, "End");
    keydown(availableList, "a", { ctrlKey: true });
    keydown(availableList, "Enter");

    expect(optionIds(availableList)).toEqual([]);
    expect(availableList).toHaveAttribute("aria-activedescendant", "");

    keydown(availableList, "Enter");
    expect(optionIds(availableList)).toEqual([]);
  });

  it("anchors a shift-space range on the current option when no anchor exists", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, "ArrowDown");
    keydown(availableList, " ", { shiftKey: true });

    expect(selectedIds(availableList)).toEqual(["available-beta"]);
  });

  it("skips the aria-live announcement when no live region is present", async () => {
    renderFixture({ ariaLive: false });
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, " ");
    keydown(availableList, "Enter");

    expect(optionIds(list("selected-list"))).toContain("available-alpha");
  });

  it("applies a template that matches existing available options", async () => {
    renderFixture({ templateSelector: true });
    application = await startController();

    const selector = target("templateSelector");
    selector.value = "existing";
    selector.dispatchEvent(new Event("change", { bubbles: true }));

    expect(itemTexts("selected-list")).toEqual(["Alpha", "Beta"]);
    expect(itemTexts("available-list")).toEqual([
      "Alpine",
      "Gamma",
      "One",
      "Two",
      "Three",
    ]);
  });

  it("resets every item to the available list for the none template", async () => {
    renderFixture({ templateSelector: true });
    application = await startController();

    const selector = target("templateSelector");
    selector.value = "existing";
    selector.dispatchEvent(new Event("change", { bubbles: true }));
    selector.value = "none";
    selector.dispatchEvent(new Event("change", { bubbles: true }));

    expect(itemTexts("selected-list")).toEqual([]);
    expect(itemTexts("available-list")).toEqual([
      "Alpha",
      "Beta",
      "Alpine",
      "Gamma",
      "One",
      "Two",
      "Three",
    ]);
  });

  it("defaults the selection list to the event target", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    controllerInstance(application).handleSelection({ target: availableList });

    expect(selectedIds(availableList)).toEqual(["available-alpha"]);
  });

  it("reorders a selected item downward with Alt+ArrowDown", async () => {
    renderFixture({
      selected: [
        option("selected-one", "One", true),
        option("selected-two", "Two"),
        option("selected-three", "Three"),
      ],
    });
    application = await startController();

    const selectedList = list("selected-list");
    selectedList.focus();
    keydown(selectedList, "ArrowDown", { altKey: true });

    expect(optionIds(selectedList)).toEqual([
      "selected-two",
      "selected-one",
      "selected-three",
    ]);
    expect(activeId(selectedList)).toBe("selected-one");
  });

  it("tolerates lists without a data-title attribute", async () => {
    renderFixture({ titles: false });
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, " ");
    keydown(availableList, "Enter");

    expect(optionIds(list("selected-list"))).toContain("available-alpha");
  });

  it("scrolls the active option into view when the browser supports it", async () => {
    renderFixture();
    application = await startController();

    const scrollSpy = vi.fn();
    window.HTMLElement.prototype.scrollIntoView = scrollSpy;

    try {
      list("available-list").focus();
      expect(scrollSpy).toHaveBeenCalled();
    } finally {
      delete window.HTMLElement.prototype.scrollIntoView;
    }
  });

  it("ignores arrow navigation on an empty listbox", async () => {
    renderFixture({ available: [], selected: [] });
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, "ArrowDown");
    keydown(availableList, " ");

    expect(availableList).toHaveAttribute("aria-activedescendant", "");
  });

  it("searches downward past selected options for the next focus target", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, "ArrowDown");
    keydown(availableList, " ");
    keydown(availableList, "ArrowUp");
    keydown(availableList, " ");
    keydown(availableList, "Enter");

    expect(activeId(availableList)).toBe("available-alpine");
  });

  it("falls back to upward search when trailing siblings are all selected", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, "End");
    keydown(availableList, " ");
    keydown(availableList, "ArrowUp");
    keydown(availableList, " ");
    keydown(availableList, "Enter");

    expect(activeId(availableList)).toBe("available-beta");
  });

  it("does nothing when the configured lists are missing", async () => {
    document.body.innerHTML = `
      <div
        data-controller="sortable-lists--v1--two-lists-selection"
        data-sortable-lists--v1--two-lists-selection-selected-list-value="missing-selected"
        data-sortable-lists--v1--two-lists-selection-available-list-value="missing-available"
        data-sortable-lists--v1--two-lists-selection-field-name-value="fields[]"
      ></div>
    `;

    application = await startController();

    expect(document.getElementById("missing-available")).toBeNull();
  });

  it("disconnects cleanly when there is no submit button", async () => {
    renderFixture();
    application = await startController();

    expect(() => controllerInstance(application).disconnect()).not.toThrow();
  });

  it("ignores keys without a handler that are not printable", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, "Escape");

    expect(selectedIds(availableList)).toEqual([]);
  });

  it("does nothing when the down button has no lower option", async () => {
    renderFixture();
    application = await startController();

    const selectedList = list("selected-list");
    selectedList.focus();
    keydown(selectedList, "End");
    keydown(selectedList, " ");

    const downButton = target("downButton");
    downButton.setAttribute("aria-disabled", "false");
    click(downButton);

    expect(optionIds(selectedList)).toEqual([
      "selected-one",
      "selected-two",
      "selected-three",
    ]);
  });

  it("keeps the active option when type-ahead finds no match", async () => {
    renderFixture();
    application = await startController();

    const availableList = list("available-list");
    availableList.focus();
    keydown(availableList, "z");

    expect(activeId(availableList)).toBe("available-alpha");
  });
});
