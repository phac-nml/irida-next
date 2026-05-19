import { Application } from "@hotwired/stimulus";
import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import SortableListsController from "../../../../../app/javascript/controllers/sortable_lists/v1/two_lists_selection_controller.js";

const translations = JSON.stringify({
  added: "Added: ",
  removed: "Removed: ",
  move_up: "Moved OPTION_PLACEHOLDER up",
  move_down: "Moved OPTION_PLACEHOLDER down",
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
      <div
        aria-live="polite"
        data-sortable-lists--v1--two-lists-selection-target="ariaLiveUpdate"
        data-translations='${translations}'
      ></div>
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
    ).toHaveTextContent("Moved Two up");
  });
});
