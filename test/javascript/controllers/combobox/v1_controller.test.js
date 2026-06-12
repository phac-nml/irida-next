import { Application } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import ComboboxController from "../../../../app/javascript/controllers/combobox/v1_controller.js";

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

function option({ id, value, text, disabled = false }) {
  return `
    <div
      id="${id}"
      role="option"
      data-value="${value}"
      ${disabled ? 'aria-disabled="true"' : ""}
    >${text}</div>
  `;
}

function renderFixture({ disabled = false } = {}) {
  document.body.innerHTML = `
    <div
      data-controller="combobox--v1"
      data-combobox--v1-clear-selection-label-value="Clear selection"
      data-combobox--v1-no-results-text-value="No results found"
      data-combobox--v1-show-options-label-value="Show options"
      data-combobox--v1-single-result-text-value="1 result available"
      data-combobox--v1-multiple-results-text-value="%{num} results available"
    >
      <input
        type="hidden"
        value=""
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
          ${disabled ? 'aria-disabled="true" readonly' : ""}
          data-combobox--v1-target="combobox"
        >
        <button
          type="button"
          tabindex="-1"
          data-combobox--v1-target="indicatorClearButton"
          data-action="mousedown->combobox--v1#onIndicatorMouseDown click->combobox--v1#onClearClick"
        >Clear</button>
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
          ${option({ id: "option-alpha", value: "alpha", text: "Alpha" })}
          ${option({ id: "option-disabled", value: "disabled", text: "Disabled", disabled: true })}
          ${option({ id: "option-bravo", value: "bravo", text: "Bravo" })}
        </div>
        <div
          role="status"
          hidden
          data-combobox--v1-target="noResults"
        ></div>
      </div>
      <div aria-live="polite" data-combobox--v1-target="ariaLiveUpdate"></div>
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

  afterEach(() => {
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
});
