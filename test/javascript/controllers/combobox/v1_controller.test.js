import { Application } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { announce } from "utilities/live_region";
import ComboboxController from "../../../../app/javascript/controllers/combobox/v1_controller.js";

vi.mock("utilities/live_region", () => ({ announce: vi.fn() }));

vi.mock("utilities/floating_dropdown", () => ({
  default: class FloatingDropdownStub {
    #visible = false;
    #onShow;
    #onHide;

    constructor({ onShow, onHide }) {
      this.#onShow = onShow;
      this.#onHide = onHide;
    }

    isVisible() {
      return this.#visible;
    }

    show() {
      this.#visible = true;
      this.#onShow?.();
    }

    hide() {
      this.#visible = false;
      this.#onHide?.();
    }

    toggle() {
      if (this.#visible) {
        this.hide();
      } else {
        this.show();
      }
    }

    destroy() {}
  },
}));

function option({ id, value, text, label = text, disabled = false }) {
  return `
    <div
      id="${id}"
      role="option"
      data-value="${value}"
      data-label="${label}"
      ${disabled ? 'aria-disabled="true"' : ""}
    >${text}</div>
  `;
}

function renderFixture({
  disabled = false,
  hiddenValue = "",
  comboboxValue = "",
  optionsHtml,
  includeClearButton = true,
  includeAriaLive = true,
  noResultsText = "No results found",
  singleResultText = "1 result available",
  multipleResultText = "%{num} results available",
} = {}) {
  const renderedOptions =
    optionsHtml ||
    [
      option({ id: "option-alpha", value: "alpha", text: "Alpha" }),
      option({
        id: "option-disabled",
        value: "disabled",
        text: "Disabled",
        disabled: true,
      }),
      option({ id: "option-bravo", value: "bravo", text: "Bravo" }),
    ].join("\n");

  const optionalValueAttribute = (name, value) =>
    value === null ? "" : `data-combobox--v1-${name}-value="${value}"`;

  document.body.innerHTML = `
    <div
      data-controller="combobox--v1"
      data-combobox--v1-clear-selection-label-value="Clear selection"
      ${optionalValueAttribute("no-results-text", noResultsText)}
      data-combobox--v1-show-options-label-value="Show options"
      ${optionalValueAttribute("single-result-text", singleResultText)}
      ${optionalValueAttribute("multiple-results-text", multipleResultText)}
    >
      <input
        type="hidden"
        value="${hiddenValue}"
        data-combobox--v1-target="hidden"
      >
      <div>
        <input
          id="field"
          type="text"
          role="combobox"
          aria-autocomplete="list"
          aria-controls="field_listbox"
          aria-expanded="false"
          value="${comboboxValue}"
          ${disabled ? 'aria-disabled="true" readonly' : ""}
          data-combobox--v1-target="combobox"
        >
        ${
          includeClearButton
            ? `<button
          type="button"
          tabindex="-1"
          data-combobox--v1-target="indicatorClearButton"
          data-action="mousedown->combobox--v1#onIndicatorMouseDown click->combobox--v1#onClearClick"
        >Clear</button>`
            : ""
        }
        <button
          type="button"
          tabindex="-1"
          data-combobox--v1-target="indicatorButton"
          data-action="mousedown->combobox--v1#onIndicatorMouseDown click->combobox--v1#onIndicatorClick"
        ><span></span></button>
      </div>
      <div
        aria-hidden="true"
        style="display: none;"
        data-combobox--v1-target="popup"
      >
        <div
          id="field_listbox"
          role="listbox"
          data-combobox--v1-target="listbox"
        >
          ${renderedOptions}
        </div>
        <div
          role="status"
          hidden
          data-combobox--v1-target="noResults"
        ></div>
      </div>
      ${
        includeAriaLive
          ? `<div aria-live="polite" data-combobox--v1-target="ariaLiveUpdate"></div>`
          : ""
      }
    </div>
  `;
}

async function startController() {
  const application = Application.start();
  application.register("combobox--v1", ComboboxController);
  await Promise.resolve();
  return application;
}

function combobox() {
  return document.querySelector('[data-combobox--v1-target="combobox"]');
}

function hidden() {
  return document.querySelector('[data-combobox--v1-target="hidden"]');
}

function listbox() {
  return document.querySelector('[data-combobox--v1-target="listbox"]');
}

function noResults() {
  return document.querySelector('[data-combobox--v1-target="noResults"]');
}

function indicatorButton() {
  return document.querySelector('[data-combobox--v1-target="indicatorButton"]');
}

function clearButton() {
  return document.querySelector(
    '[data-combobox--v1-target="indicatorClearButton"]',
  );
}

function mouse(target, type) {
  return target.dispatchEvent(
    new MouseEvent(type, { bubbles: true, cancelable: true }),
  );
}

function keydown(key, options = {}) {
  return combobox().dispatchEvent(
    new KeyboardEvent("keydown", {
      key,
      bubbles: true,
      cancelable: true,
      ...options,
    }),
  );
}

function keyup(key, options = {}) {
  return combobox().dispatchEvent(
    new KeyboardEvent("keyup", {
      key,
      bubbles: true,
      cancelable: true,
      ...options,
    }),
  );
}

function beforeinput(data = "x") {
  return combobox().dispatchEvent(
    new InputEvent("beforeinput", {
      bubbles: true,
      cancelable: true,
      data,
      inputType: "insertText",
    }),
  );
}

function focusCombobox() {
  combobox().focus();
}

function activeId() {
  return combobox().getAttribute("aria-activedescendant");
}

function selectedOptionIds() {
  return Array.from(listbox().querySelectorAll('[aria-selected="true"]')).map(
    (element) => element.id,
  );
}

describe("combobox v1 controller", () => {
  let application;
  let scrollIntoView;

  beforeEach(() => {
    vi.useFakeTimers();
    scrollIntoView = vi.fn();
    window.HTMLElement.prototype.scrollIntoView = scrollIntoView;
  });

  afterEach(async () => {
    // Remove the controller element and flush microtasks so Stimulus runs
    // disconnect(), detaching the document-level listeners before the next test.
    document.body.innerHTML = "";
    await Promise.resolve();
    await Promise.resolve();
    application?.stop();
    vi.useRealTimers();
  });

  it("opens with Alt+ArrowDown without selecting an active option", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    keydown("ArrowDown", { altKey: true });

    expect(combobox()).toHaveAttribute("aria-expanded", "true");
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");
    expect(selectedOptionIds()).toEqual([]);
  });

  it("moves the active option with ArrowDown and ArrowUp while skipping aria-disabled options", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    keydown("ArrowDown");
    expect(activeId()).toBe("option-alpha");
    expect(selectedOptionIds()).toEqual(["option-alpha"]);

    keydown("ArrowDown");
    expect(activeId()).toBe("option-bravo");
    expect(selectedOptionIds()).toEqual(["option-bravo"]);

    keydown("ArrowUp");
    expect(activeId()).toBe("option-alpha");
    expect(selectedOptionIds()).toEqual(["option-alpha"]);
  });

  it("moves Home and End to the first and last enabled options when the popup is open", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown", { altKey: true });

    keydown("End");
    expect(activeId()).toBe("option-bravo");

    keydown("Home");
    expect(activeId()).toBe("option-alpha");
  });

  it("leaves Home and End as text editing keys when the popup is closed", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    expect(keydown("Home")).toBe(true);
    expect(keydown("End")).toBe(true);
    expect(keyup("Home")).toBe(true);
    expect(keyup("End")).toBe(true);
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");
  });

  it("shows options again after clearing a no-results filter and reopening", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    combobox().value = "zzz";
    keyup("z");
    vi.advanceTimersByTime(300);
    expect(noResults()).not.toHaveAttribute("hidden");

    keydown("Escape");

    combobox().value = "";
    keyup("Backspace");
    vi.advanceTimersByTime(300);
    keydown("ArrowDown", { altKey: true });

    expect(noResults()).toHaveAttribute("hidden");
    expect(listbox()).not.toHaveAttribute("hidden");
    expect(listbox().querySelectorAll('[role="option"]').length).toBe(3);
  });

  it("renders no-results text as status text instead of a selectable option", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    combobox().value = "zzz";
    keyup("z");
    vi.advanceTimersByTime(300);

    expect(noResults()).toHaveAttribute("role", "status");
    expect(noResults()).toHaveTextContent("No results found");
    expect(noResults()).not.toHaveAttribute("hidden");
    expect(listbox()).toHaveAttribute("hidden");
    expect(listbox().querySelector('[role="status"]')).toBeNull();
    expect(listbox().querySelector('[role="option"]')).toBeNull();
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");
  });

  it("closes the popup with Escape, then clears the committed value with Escape when closed", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown");
    keydown("ArrowDown");
    keydown("Enter");

    expect(combobox()).toHaveValue("Bravo");
    expect(hidden()).toHaveValue("bravo");

    keydown("ArrowDown", { altKey: true });
    expect(combobox()).toHaveAttribute("aria-expanded", "true");

    keydown("Escape");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
    expect(combobox()).toHaveValue("Bravo");
    expect(hidden()).toHaveValue("bravo");

    keydown("Escape");
    expect(combobox()).toHaveValue("");
    expect(hidden()).toHaveValue("");
  });

  it("does not change values or fire change events while filtering", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    const comboboxChange = vi.fn();
    const hiddenChange = vi.fn();
    combobox().addEventListener("change", comboboxChange);
    hidden().addEventListener("change", hiddenChange);

    combobox().value = "Al";
    keyup("l");
    vi.advanceTimersByTime(300);

    expect(hidden()).toHaveValue("");
    expect(comboboxChange).not.toHaveBeenCalled();
    expect(hiddenChange).not.toHaveBeenCalled();
  });

  it("commits the active option and fires change events only on commit", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    const comboboxChange = vi.fn();
    const hiddenChange = vi.fn();
    combobox().addEventListener("change", comboboxChange);
    hidden().addEventListener("change", hiddenChange);

    keydown("ArrowDown");
    keydown("ArrowDown");
    expect(hidden()).toHaveValue("");
    expect(comboboxChange).not.toHaveBeenCalled();
    expect(hiddenChange).not.toHaveBeenCalled();

    keydown("Enter");
    expect(combobox()).toHaveValue("Bravo");
    expect(hidden()).toHaveValue("bravo");
    expect(comboboxChange).toHaveBeenCalledTimes(1);
    expect(hiddenChange).toHaveBeenCalledTimes(1);
  });

  it("ignores keyboard and mouse input when aria-disabled is true", async () => {
    renderFixture({ disabled: true });
    application = await startController();
    focusCombobox();

    expect(beforeinput("a")).toBe(false);
    expect(keydown("ArrowDown")).toBe(false);
    combobox().click();
    keyup("a");
    keydown("Enter");

    expect(combobox()).toHaveAttribute("aria-expanded", "false");
    expect(combobox()).toHaveValue("");
    expect(hidden()).toHaveValue("");
    expect(combobox()).toHaveAttribute("aria-disabled", "true");
    expect(combobox()).not.toHaveAttribute("disabled");
  });

  it("initializes from hidden data-value when labels are duplicated", async () => {
    renderFixture({
      hiddenValue: "bravo-2",
      comboboxValue: "Bravo",
      optionsHtml: [
        option({ id: "option-bravo-1", value: "bravo-1", text: "Bravo" }),
        option({ id: "option-bravo-2", value: "bravo-2", text: "Bravo" }),
      ].join("\n"),
    });

    const hiddenChange = vi.fn();
    const comboboxChange = vi.fn();
    hidden().addEventListener("change", hiddenChange);
    combobox().addEventListener("change", comboboxChange);

    application = await startController();

    expect(hidden()).toHaveValue("bravo-2");
    expect(combobox()).toHaveValue("Bravo");
    expect(hiddenChange).not.toHaveBeenCalled();
    expect(comboboxChange).not.toHaveBeenCalled();
  });

  it("keeps selected value and avoids no-results when data-label differs from slot text", async () => {
    renderFixture({
      hiddenValue: "alpha",
      optionsHtml: [
        option({
          id: "option-alpha",
          value: "alpha",
          label: "Alpha Label",
          text: "Slot Alpha",
        }),
        option({ id: "option-bravo", value: "bravo", text: "Bravo" }),
      ].join("\n"),
    });

    application = await startController();

    expect(hidden()).toHaveValue("alpha");
    expect(combobox()).toHaveValue("Alpha Label");
    expect(noResults()).toHaveAttribute("hidden");

    focusCombobox();
    keydown("ArrowDown", { altKey: true });

    expect(combobox()).toHaveAttribute("aria-expanded", "true");
    expect(noResults()).toHaveAttribute("hidden");
    expect(listbox()).not.toHaveAttribute("hidden");
    expect(listbox().querySelectorAll('[role="option"]').length).toBe(1);
    expect(listbox().querySelector('[role="option"]')).toHaveAttribute(
      "data-value",
      "alpha",
    );
  });

  it("cleans up listeners and the dropdown on disconnect", async () => {
    renderFixture();
    application = await startController();
    const removeSpy = vi.spyOn(document.body, "removeEventListener");

    document.querySelector('[data-controller="combobox--v1"]').remove();
    await Promise.resolve();
    await Promise.resolve();

    expect(removeSpy).toHaveBeenCalledWith(
      "mousedown",
      expect.any(Function),
      true,
    );
  });

  it("ignores keydown while Ctrl or Shift is held", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    expect(keydown("ArrowDown", { ctrlKey: true })).toBe(true);
    expect(keydown("ArrowDown", { shiftKey: true })).toBe(true);
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");
  });

  it("selects the only option with ArrowDown when a single result exists", async () => {
    renderFixture({
      optionsHtml: option({ id: "option-only", value: "only", text: "Only" }),
    });
    application = await startController();
    focusCombobox();

    keydown("ArrowDown");

    expect(combobox()).toHaveAttribute("aria-expanded", "true");
    expect(activeId()).toBe("option-only");
  });

  it("wraps from the last option to the first with ArrowDown and first to last with ArrowUp", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    keydown("ArrowDown");
    keydown("ArrowDown");
    expect(activeId()).toBe("option-bravo");

    keydown("ArrowDown");
    expect(activeId()).toBe("option-alpha");

    keydown("ArrowUp");
    expect(activeId()).toBe("option-bravo");
  });

  it("opens with ArrowUp and lands on the last option when closed", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    keydown("ArrowUp");

    expect(combobox()).toHaveAttribute("aria-expanded", "true");
    expect(activeId()).toBe("option-bravo");
  });

  it("opens with Alt+ArrowUp without selecting an option when closed", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    keydown("ArrowUp", { altKey: true });

    expect(combobox()).toHaveAttribute("aria-expanded", "true");
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");
  });

  it("selects the last option with ArrowUp on a null active option while open", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown", { altKey: true });
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");

    keydown("ArrowUp");

    expect(activeId()).toBe("option-bravo");
  });

  it("keeps the current active option when refiltering without a committed value", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    keydown("ArrowDown");
    expect(activeId()).toBe("option-alpha");

    keyup("Backspace");
    vi.advanceTimersByTime(300);

    expect(activeId()).toBe("option-alpha");
    expect(hidden()).toHaveValue("");
  });

  it("commits the active option and closes on Tab", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    keydown("ArrowDown");
    expect(keydown("Tab")).toBe(true);

    expect(hidden()).toHaveValue("alpha");
    expect(combobox()).toHaveValue("Alpha");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
  });

  it("treats keyup Escape as a no-op that does not filter", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    combobox().value = "Al";

    expect(keyup("Escape")).toBe(true);

    expect(combobox()).toHaveValue("Al");
  });

  it("clears the active option with ArrowLeft when the popup is closed", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown");
    keydown("Escape");
    keydown("ArrowDown");
    keydown("Escape");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");

    focusCombobox();
    keydown("ArrowUp", { altKey: true });
    keydown("Escape");

    expect(keyup("ArrowLeft")).toBe(false);
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");
  });

  it("leaves the active option untouched with ArrowRight when the popup is open", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown");
    expect(activeId()).toBe("option-alpha");

    expect(keyup("ArrowRight")).toBe(true);

    expect(activeId()).toBe("option-alpha");
  });

  it("toggles the popup open and closed when clicking the combobox", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    combobox().click();
    expect(combobox()).toHaveAttribute("aria-expanded", "true");

    combobox().click();
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
  });

  it("commits the active option and closes on an outside mousedown", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown");
    expect(hidden()).toHaveValue("");

    mouse(document.body, "mousedown");

    expect(hidden()).toHaveValue("alpha");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
  });

  it("ignores an outside mousedown while the combobox is disabled", async () => {
    renderFixture({ disabled: true });
    application = await startController();

    mouse(document.body, "mousedown");

    expect(hidden()).toHaveValue("");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
  });

  it("toggles the popup through the indicator button", async () => {
    renderFixture();
    application = await startController();

    mouse(indicatorButton(), "mousedown");
    mouse(indicatorButton(), "click");
    expect(combobox()).toHaveAttribute("aria-expanded", "true");

    mouse(indicatorButton(), "mousedown");
    mouse(indicatorButton(), "click");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
  });

  it("clears the committed value and stays closed when cleared from a closed popup", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown");
    keydown("Enter");
    expect(hidden()).toHaveValue("alpha");

    mouse(clearButton(), "mousedown");
    mouse(clearButton(), "click");

    expect(hidden()).toHaveValue("");
    expect(combobox()).toHaveValue("");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
  });

  it("clears the committed value and stays open when cleared from an open popup", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown");
    keydown("Enter");
    keydown("ArrowDown");
    expect(combobox()).toHaveAttribute("aria-expanded", "true");

    mouse(clearButton(), "mousedown");
    mouse(clearButton(), "click");

    expect(hidden()).toHaveValue("");
    expect(combobox()).toHaveValue("");
    expect(combobox()).toHaveAttribute("aria-expanded", "true");
  });

  it("commits an option and closes when clicking it in the listbox", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown");

    const disabledOption = listbox().querySelector('[data-value="disabled"]');
    mouse(disabledOption, "click");
    expect(hidden()).toHaveValue("");

    const bravoOption = listbox().querySelector('[data-value="bravo"]');
    mouse(bravoOption, "click");

    expect(hidden()).toHaveValue("bravo");
    expect(combobox()).toHaveValue("Bravo");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
  });

  it("filters options inside a group and removes non-matching group children", async () => {
    const groupHtml = `
      <div role="group" aria-label="Fruits">
        ${option({ id: "opt-apple", value: "apple", text: "Apple" })}
        ${option({ id: "opt-apricot", value: "apricot", text: "Apricot" })}
        ${option({ id: "opt-banana", value: "banana", text: "Banana" })}
      </div>
    `;
    renderFixture({ optionsHtml: groupHtml });
    application = await startController();
    focusCombobox();
    keydown("ArrowDown", { altKey: true });

    combobox().value = "ap";
    keyup("p");
    vi.advanceTimersByTime(300);

    expect(listbox().querySelector('[role="group"]')).not.toBeNull();
    const visible = Array.from(
      listbox().querySelectorAll('[role="option"]'),
    ).map((element) => element.getAttribute("data-value"));
    expect(visible).toEqual(["apple", "apricot"]);
  });

  it("shows no results when every option in a group is filtered out", async () => {
    const groupHtml = `
      <div role="group" aria-label="Fruits">
        ${option({ id: "opt-apple", value: "apple", text: "Apple" })}
        ${option({ id: "opt-banana", value: "banana", text: "Banana" })}
      </div>
    `;
    renderFixture({ optionsHtml: groupHtml });
    application = await startController();
    focusCombobox();
    keydown("ArrowDown", { altKey: true });

    combobox().value = "zzz";
    keyup("z");
    vi.advanceTimersByTime(300);

    expect(listbox().querySelector('[role="option"]')).toBeNull();
    expect(noResults()).not.toHaveAttribute("hidden");
  });

  it("announces the number of results while the popup is open", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown", { altKey: true });

    announce.mockClear();
    combobox().value = "alph";
    keyup("h");
    vi.advanceTimersByTime(300);
    expect(announce).toHaveBeenLastCalledWith(
      "1 result available",
      expect.objectContaining({ element: expect.any(HTMLElement) }),
    );

    announce.mockClear();
    combobox().value = "a";
    keyup("a");
    vi.advanceTimersByTime(300);
    expect(announce).toHaveBeenLastCalledWith(
      "3 results available",
      expect.objectContaining({ element: expect.any(HTMLElement) }),
    );

    announce.mockClear();
    combobox().value = "zzz";
    keyup("z");
    vi.advanceTimersByTime(300);
    expect(announce).toHaveBeenLastCalledWith(
      "No results found",
      expect.objectContaining({ element: expect.any(HTMLElement) }),
    );
  });

  it("supports comboboxes rendered without indicator buttons", async () => {
    renderFixture({ includeClearButton: false });
    document
      .querySelector('[data-combobox--v1-target="indicatorButton"]')
      ?.remove();
    application = await startController();
    focusCombobox();

    keydown("ArrowDown", { altKey: true });
    expect(combobox()).toHaveAttribute("aria-expanded", "true");

    keydown("Escape");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
  });

  it("dispatches the legacy IE key aliases through the same handlers", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    keydown("Down");
    expect(activeId()).toBe("option-alpha");
    keydown("Up");
    expect(activeId()).toBe("option-bravo");

    keydown("Esc");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");

    keyup("Left");
    keyup("Right");
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");

    expect(keydown("q")).toBe(true);
  });

  it("ignores indicator, clear, and option interactions while disabled", async () => {
    renderFixture({ disabled: true });
    application = await startController();

    mouse(indicatorButton(), "mousedown");
    mouse(indicatorButton(), "click");
    mouse(clearButton(), "mousedown");
    mouse(clearButton(), "click");
    mouse(listbox().querySelector('[data-value="alpha"]'), "click");

    expect(combobox()).toHaveAttribute("aria-expanded", "false");
    expect(hidden()).toHaveValue("");
  });

  it("lets Tab move focus while disabled", async () => {
    renderFixture({ disabled: true });
    application = await startController();
    focusCombobox();

    expect(keydown("Tab")).toBe(true);
  });

  it("does nothing but stays interactive on beforeinput while enabled", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    expect(beforeinput("a")).toBe(true);
  });

  it("commits nothing on Enter or Tab when no option is active", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();

    keydown("ArrowDown", { altKey: true });
    keydown("Enter");
    expect(hidden()).toHaveValue("");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");

    keydown("ArrowDown", { altKey: true });
    keydown("Tab");
    expect(hidden()).toHaveValue("");
  });

  it("does nothing on ArrowDown when no option is selectable", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown", { altKey: true });

    combobox().value = "zzz";
    keyup("z");
    vi.advanceTimersByTime(300);

    keydown("ArrowDown");
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");
  });

  it("does nothing on ArrowUp when no option is selectable", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowUp", { altKey: true });

    combobox().value = "zzz";
    keyup("z");
    vi.advanceTimersByTime(300);

    keydown("ArrowUp");
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");
  });

  it("closes without committing on an outside mousedown when no option is active", async () => {
    renderFixture();
    application = await startController();
    focusCombobox();
    keydown("ArrowDown", { altKey: true });
    expect(combobox()).not.toHaveAttribute("aria-activedescendant");

    mouse(document.body, "mousedown");

    expect(hidden()).toHaveValue("");
    expect(combobox()).toHaveAttribute("aria-expanded", "false");
  });

  it("handles options that expose an empty data-label", async () => {
    renderFixture({
      hiddenValue: "nolabel",
      optionsHtml: option({
        id: "opt-nolabel",
        value: "nolabel",
        label: "",
        text: "No Label",
      }),
    });
    application = await startController();

    expect(combobox()).toHaveValue("");

    focusCombobox();
    keydown("ArrowDown");
    keydown("Enter");

    expect(hidden()).toHaveValue("nolabel");
    expect(combobox()).toHaveValue("");
  });

  it("falls back to the default no-results message when no text value is provided", async () => {
    renderFixture({ noResultsText: null });
    application = await startController();
    focusCombobox();

    combobox().value = "zzz";
    keyup("z");
    vi.advanceTimersByTime(300);

    expect(noResults()).toHaveTextContent("No results found");
    expect(noResults()).not.toHaveAttribute("hidden");
  });

  it("skips announcements when there is no aria-live target", async () => {
    renderFixture({ includeAriaLive: false });
    application = await startController();
    focusCombobox();
    keydown("ArrowDown", { altKey: true });

    announce.mockClear();
    combobox().value = "alph";
    keyup("h");
    vi.advanceTimersByTime(300);

    expect(announce).not.toHaveBeenCalled();
  });

  it("skips the announcement when the result message is empty", async () => {
    renderFixture({ noResultsText: "" });
    application = await startController();
    focusCombobox();
    keydown("ArrowDown", { altKey: true });

    announce.mockClear();
    combobox().value = "zzz";
    keyup("z");
    vi.advanceTimersByTime(300);

    expect(announce).not.toHaveBeenCalled();
  });

  it("scrolls a surrounding dialog into view when the active option is out of bounds", async () => {
    document.body.innerHTML = `
      <dialog open>
        <div class="dialog--section">
          <div
            data-controller="combobox--v1"
            data-combobox--v1-clear-selection-label-value="Clear selection"
            data-combobox--v1-no-results-text-value="No results found"
            data-combobox--v1-show-options-label-value="Show options"
            data-combobox--v1-single-result-text-value="1 result available"
            data-combobox--v1-multiple-results-text-value="%{num} results available"
          >
            <input type="hidden" value="" data-combobox--v1-target="hidden">
            <div>
              <input
                id="field"
                type="text"
                role="combobox"
                aria-expanded="false"
                data-combobox--v1-target="combobox"
              >
              <button
                type="button"
                tabindex="-1"
                data-combobox--v1-target="indicatorButton"
              ><span></span></button>
            </div>
            <div
              aria-hidden="true"
              style="display: none;"
              data-combobox--v1-target="popup"
            >
              <div
                id="field_listbox"
                role="listbox"
                data-combobox--v1-target="listbox"
              >
                ${option({ id: "opt-alpha", value: "alpha", text: "Alpha" })}
                ${option({ id: "opt-bravo", value: "bravo", text: "Bravo" })}
                ${option({ id: "opt-charlie", value: "charlie", text: "Charlie" })}
              </div>
              <div role="status" hidden data-combobox--v1-target="noResults"></div>
            </div>
            <div aria-live="polite" data-combobox--v1-target="ariaLiveUpdate"></div>
          </div>
        </div>
      </dialog>
    `;
    const section = document.querySelector(".dialog--section");
    section.scrollBy = vi.fn();
    const rectSpy = vi
      .spyOn(window.HTMLElement.prototype, "getBoundingClientRect")
      .mockReturnValueOnce({
        top: -50,
        height: 10,
        bottom: 0,
        left: 0,
        right: 0,
        width: 0,
        x: 0,
        y: 0,
      })
      .mockReturnValueOnce({
        top: 0,
        height: 100,
        bottom: 0,
        left: 0,
        right: 0,
        width: 0,
        x: 0,
        y: 0,
      })
      .mockReturnValue({
        top: 0,
        height: 0,
        bottom: 0,
        left: 0,
        right: 0,
        width: 0,
        x: 0,
        y: 0,
      });

    application = await startController();
    focusCombobox();

    keydown("ArrowDown");
    keydown("ArrowDown");
    keydown("ArrowDown");

    expect(section.scrollBy).toHaveBeenCalledTimes(2);
    expect(section.scrollBy).toHaveBeenNthCalledWith(1, 0, -50);
    expect(section.scrollBy).toHaveBeenNthCalledWith(2, 0, 0);

    rectSpy.mockRestore();
  });
});
