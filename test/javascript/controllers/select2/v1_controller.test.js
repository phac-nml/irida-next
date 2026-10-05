import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { Controller } from "@hotwired/stimulus";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";
import Select2V1Controller from "../../../../app/javascript/controllers/select2/v1_controller.js";

const mockState = { instances: [] };

class DropdownMock {
  constructor(dropdown, trigger, options) {
    this.dropdown = dropdown;
    this.trigger = trigger;
    this.options = options;
    this.visible = false;
    mockState.instances.push(this);
  }
  isVisible() {
    return this.visible;
  }
  show() {
    this.visible = true;
    this.options.onShow?.();
  }
  hide() {
    this.visible = false;
    this.options.onHide?.();
  }
}

let outletReady;
class SpreadsheetImportStub extends Controller {
  checkFormInputsReadyForSubmit() {
    outletReady();
  }
}

function fixture({
  inputValue = "",
  includeSubmit = true,
  includeOutlet = false,
  scrollerId = "scroller",
  missing = null,
  includeDup = false,
  bareItem = false,
  emptyTextItem = false,
  blankLabelItem = false,
} = {}) {
  const target = (name) =>
    missing === name ? "" : `data-select2--v1-target="${name}"`;
  const outletAttr = includeOutlet
    ? 'data-select2--v1-spreadsheet-import-outlet="#si"'
    : "";
  const submit = includeSubmit
    ? '<button data-select2--v1-target="submitButton">Submit</button>'
    : "";
  const outletEl = includeOutlet
    ? '<div id="si" data-controller="spreadsheet-import"></div>'
    : "";
  const dup = includeDup
    ? `<li><button ${target("item")} data-action="click->select2--v1#select" data-value="dup" data-label="dup">dup</button></li>`
    : "";
  const bare = bareItem
    ? `<button ${target("item")} data-action="click->select2--v1#select" data-value="4" data-label="Delta">Delta</button>`
    : "";
  const emptyText = emptyTextItem
    ? `<li><button ${target("item")} data-action="click->select2--v1#select" data-value="5" data-label="Five"></button></li>`
    : "";
  const blankLabel = blankLabelItem
    ? `<li><button ${target("item")} data-action="click->select2--v1#select" data-value="6" data-label="">Six</button></li>`
    : "";
  return `
    ${outletEl}
    <div data-controller="select2--v1" data-action="keydown->select2--v1#keydown" ${outletAttr}>
      <input ${target("input")} data-action="input->select2--v1#input" value="${inputValue}" />
      <input type="hidden" ${target("hidden")} />
      <div ${target("dropdown")}>
        <div id="${scrollerId}" ${target("scroller")}>
          <ul>
            <li><button ${target("item")} data-action="click->select2--v1#select" data-value="1" data-label="Alpha">Alpha</button></li>
            <li><button ${target("item")} data-action="click->select2--v1#select" data-value="2" data-label="Beta">Beta</button></li>
            <li><button ${target("item")} data-action="click->select2--v1#select" data-value="3" data-label="Gamma">Gamma</button></li>
            ${dup}
            ${emptyText}
            ${blankLabel}
          </ul>
          ${bare}
        </div>
        <div ${target("empty")} class="hidden">No results</div>
      </div>
      ${submit}
    </div>
  `;
}

const root = () => document.querySelector('[data-controller="select2--v1"]');
const input = () => document.querySelector('[data-select2--v1-target="input"]');
const hidden = () =>
  document.querySelector('[data-select2--v1-target="hidden"]');
const empty = () => document.querySelector('[data-select2--v1-target="empty"]');
const submitButton = () =>
  document.querySelector('[data-select2--v1-target="submitButton"]');
const items = () =>
  Array.from(document.querySelectorAll('[data-select2--v1-target="item"]'));
const dropdown = () => mockState.instances.at(-1);

function controllerFor(application) {
  return application.getControllerForElementAndIdentifier(
    root(),
    "select2--v1",
  );
}

function press(el, key) {
  const event = new KeyboardEvent("keydown", {
    key,
    bubbles: true,
    cancelable: true,
  });
  el.dispatchEvent(event);
  return event;
}

async function mount(options = {}, { withDropdown = true } = {}) {
  document.body.innerHTML = fixture(options);
  if (withDropdown) {
    vi.stubGlobal("Dropdown", DropdownMock);
  }
  const application = startApplication();
  application.register("select2--v1", Select2V1Controller);
  application.register("spreadsheet-import", SpreadsheetImportStub);
  await Promise.resolve();
  await new Promise((resolve) => requestAnimationFrame(resolve));
  return application;
}

describe("select2/v1 controller", () => {
  let application;
  let consoleError;
  let consoleWarn;

  beforeEach(() => {
    mockState.instances = [];
    outletReady = vi.fn();
    consoleError = vi.spyOn(console, "error").mockImplementation(() => {});
    consoleWarn = vi.spyOn(console, "warn").mockImplementation(() => {});
  });

  afterEach(async () => {
    await stopApplication(application);
    document.body.innerHTML = "";
  });

  it("wires ARIA roles and marks itself connected", async () => {
    application = await mount();
    expect(root().getAttribute("data-controller-connected")).toBe("true");
    expect(input().getAttribute("role")).toBe("combobox");
    expect(input().getAttribute("aria-expanded")).toBe("false");
    expect(input().getAttribute("aria-controls")).toBe("scroller");
    items().forEach((item, idx) => {
      expect(item.getAttribute("role")).toBe("option");
      expect(item.getAttribute("id")).toBe(`select2-option-${idx}`);
    });
    expect(mockState.instances).toHaveLength(1);
  });

  it("falls back to a default listbox id when the scroller has none", async () => {
    application = await mount({ scrollerId: "" });
    expect(input().getAttribute("aria-controls")).toBe("select2-listbox");
    expect(
      document.querySelector('[data-select2--v1-target="scroller"]').id,
    ).toBe("select2-listbox");
  });

  it("logs an error when a required target is missing", async () => {
    application = await mount({ missing: "hidden" });
    expect(root().getAttribute("data-controller-connected")).toBeNull();
    expect(consoleError).toHaveBeenCalled();
  });

  it("selects a default item that matches the input value on connect", async () => {
    application = await mount({ inputValue: "2" });
    expect(input().value).toBe("Beta");
    expect(hidden().value).toBe("2");
    expect(submitButton().disabled).toBe(false);
  });

  it("logs an error when the default input value matches no item", async () => {
    application = await mount({ inputValue: "nope" });
    expect(consoleError).toHaveBeenCalled();
  });

  it("selects an item on click, updating input/hidden and hiding the dropdown", async () => {
    application = await mount();
    dropdown().show();
    items()[2].click();
    expect(input().value).toBe("Gamma");
    expect(hidden().value).toBe("3");
    expect(dropdown().isVisible()).toBe(false);
    expect(submitButton().disabled).toBe(false);
  });

  it("warns when selection cannot be determined", async () => {
    application = await mount();
    controllerFor(application).select(new Event("click"));
    expect(consoleWarn).toHaveBeenCalled();
  });

  it("filters items on input and shows the empty state when nothing matches", async () => {
    application = await mount();
    const controller = controllerFor(application);

    input().value = "bet";
    controller.input();
    expect(items()[0].classList.contains("hidden")).toBe(true);
    expect(items()[1].classList.contains("hidden")).toBe(false);
    expect(empty().classList.contains("hidden")).toBe(true);
    expect(submitButton().disabled).toBe(true);

    input().value = "zzz";
    controller.input();
    expect(empty().classList.contains("hidden")).toBe(false);
  });

  it("navigates items with the keyboard and selects with Enter", async () => {
    application = await mount();
    press(input(), "ArrowDown");
    expect(document.activeElement).toBe(items()[0]);
    press(input(), "ArrowDown");
    expect(document.activeElement).toBe(items()[1]);
    press(input(), "ArrowUp");
    expect(document.activeElement).toBe(items()[0]);

    press(input(), "Enter");
    expect(input().value).toBe("Alpha");
    expect(hidden().value).toBe("1");
  });

  it("jumps to first/last with Home and End", async () => {
    application = await mount();
    press(input(), "End");
    expect(document.activeElement).toBe(items().at(-1));
    press(input(), "Home");
    expect(document.activeElement).toBe(items()[0]);
  });

  it("opens the dropdown on Enter when nothing is highlighted", async () => {
    application = await mount();
    press(input(), "Enter");
    expect(dropdown().isVisible()).toBe(true);
  });

  it("ignores keys that are not navigation keys", async () => {
    application = await mount();
    const event = press(input(), "a");
    expect(event.defaultPrevented).toBe(false);
  });

  it("resets the input to the cached value on Escape", async () => {
    application = await mount();
    items()[0].click();
    expect(hidden().value).toBe("1");

    input().value = "typing";
    press(input(), "Escape");
    expect(input().value).toBe("Alpha");
    expect(hidden().value).toBe("1");
  });

  it("clears the selection on Escape when nothing was cached", async () => {
    application = await mount();
    input().value = "typing";
    press(input(), "Escape");
    expect(input().value).toBe("");
    expect(hidden().value).toBe("");
    expect(submitButton().disabled).toBe(true);
  });

  it("shows and hides the dropdown through the public methods", async () => {
    application = await mount();
    const controller = controllerFor(application);
    controller.showDropdown();
    expect(input().getAttribute("aria-expanded")).toBe("true");
    controller.hideDropdown();
    expect(input().getAttribute("aria-expanded")).toBe("false");
  });

  it("hides on focusout when focus leaves the dropdown", async () => {
    application = await mount();
    const dropdownEl = document.querySelector(
      '[data-select2--v1-target="dropdown"]',
    );
    dropdown().show();
    dropdownEl.dispatchEvent(
      new FocusEvent("focusout", { bubbles: true, relatedTarget: items()[0] }),
    );
    expect(dropdown().isVisible()).toBe(true);
    dropdownEl.dispatchEvent(
      new FocusEvent("focusout", {
        bubbles: true,
        relatedTarget: document.body,
      }),
    );
    expect(dropdown().isVisible()).toBe(false);
  });

  it("notifies the spreadsheet-import outlet when selection changes", async () => {
    application = await mount({ includeOutlet: true });
    items()[0].click();
    expect(outletReady).toHaveBeenCalled();
  });

  it("restores the label from cache when the dropdown hides without a new selection", async () => {
    application = await mount();
    items()[1].click();
    expect(input().value).toBe("Beta");

    input().value = "part";
    controllerFor(application).input();
    dropdown().hide();
    expect(input().value).toBe("Beta");
  });

  it("scrolls the container to keep the focused item visible", async () => {
    application = await mount();
    const scroller = document.querySelector(
      '[data-select2--v1-target="scroller"]',
    );
    scroller.getBoundingClientRect = () => ({ top: 0, bottom: 100 });
    items()[0].getBoundingClientRect = () => ({ top: 120, bottom: 160 });
    items()[1].getBoundingClientRect = () => ({ top: -40, bottom: -10 });

    scroller.scrollTop = 0;
    press(input(), "ArrowDown");
    expect(scroller.scrollTop).toBeGreaterThan(0);

    controllerFor(application);
    scroller.scrollTop = 100;
    press(input(), "ArrowDown");
    expect(scroller.scrollTop).toBeLessThan(100);
  });

  it("operates without a Dropdown global (init fails gracefully)", async () => {
    application = await mount({}, { withDropdown: false });
    expect(consoleError).toHaveBeenCalled();
    const controller = controllerFor(application);
    const dropdownEl = document.querySelector(
      '[data-select2--v1-target="dropdown"]',
    );
    // None of these should throw even though the dropdown is null.
    controller.showDropdown();
    controller.hideDropdown();
    press(input(), "Enter");
    press(input(), "Escape");
    items()[0].click();
    dropdownEl.dispatchEvent(
      new FocusEvent("focusout", {
        bubbles: true,
        relatedTarget: document.body,
      }),
    );
    input().value = "alp";
    controller.input();
    expect(input().getAttribute("aria-expanded")).toBe("false");
  });

  it("does not reopen the dropdown on input when it is already visible", async () => {
    application = await mount();
    dropdown().show();
    const showSpy = vi.spyOn(dropdown(), "show");
    input().value = "alp";
    controllerFor(application).input();
    expect(showSpy).not.toHaveBeenCalled();
  });

  it("works without a submit button target", async () => {
    application = await mount({ includeSubmit: false });
    items()[0].click();
    expect(input().value).toBe("Alpha");
  });

  it("routes errors through the handler when the dropdown throws", async () => {
    application = await mount();
    const dd = dropdown();
    dd.show = () => {
      throw new Error("boom-show");
    };
    dd.hide = () => {
      throw new Error("boom-hide");
    };
    const controller = controllerFor(application);
    const dropdownEl = document.querySelector(
      '[data-select2--v1-target="dropdown"]',
    );

    controller.showDropdown();
    controller.hideDropdown();
    press(input(), "Enter");
    press(input(), "Escape");
    items()[0].click();
    dropdownEl.dispatchEvent(
      new FocusEvent("focusout", {
        bubbles: true,
        relatedTarget: document.body,
      }),
    );
    input().value = "alp";
    controller.input();

    await stopApplication(application);
    application = null;
    expect(consoleError).toHaveBeenCalled();
  });

  it("clamps navigation at the first and last items", async () => {
    application = await mount();
    press(input(), "ArrowUp");
    expect(document.activeElement).toBe(items()[0]);

    press(input(), "End");
    press(input(), "ArrowDown");
    expect(document.activeElement).toBe(items().at(-1));
  });

  it("warns when the highlighted item has no data on Enter", async () => {
    application = await mount();
    press(input(), "ArrowDown");
    items()[0].removeAttribute("data-value");
    press(input(), "Enter");
    expect(consoleWarn).toHaveBeenCalled();
  });

  it("treats items outside a list wrapper as visible via their parent node", async () => {
    application = await mount({ bareItem: true });
    input().value = "delta";
    controllerFor(application).input();
    const bare = items().find((item) => item.dataset.value === "4");
    expect(bare.classList.contains("hidden")).toBe(false);
  });

  it("keeps the input when Escape leaves a value equal to the cached value", async () => {
    application = await mount({ includeDup: true });
    const dupItem = items().find((item) => item.dataset.value === "dup");
    dupItem.click();
    expect(input().value).toBe("dup");

    press(input(), "Escape");
    expect(input().value).toBe("dup");
    expect(hidden().value).toBe("dup");
  });

  it("clears the cache on hide when the input has been emptied", async () => {
    application = await mount({ includeOutlet: true });
    items()[1].click();
    expect(hidden().value).toBe("2");

    input().value = "";
    controllerFor(application).input();
    dropdown().hide();
    expect(hidden().value).toBe("");
    expect(input().value).toBe("");
  });

  it("notifies the outlet when resetting on Escape", async () => {
    application = await mount({ includeOutlet: true });
    items()[0].click();
    outletReady.mockClear();
    press(input(), "Escape");
    expect(outletReady).toHaveBeenCalled();
  });

  it("does not navigate when no items are visible", async () => {
    application = await mount();
    input().value = "zzz";
    controllerFor(application).input();
    press(input(), "ArrowDown");
    press(input(), "Home");
    expect(document.activeElement).not.toBe(items()[0]);
  });

  it("tolerates items with empty text while filtering", async () => {
    application = await mount({ emptyTextItem: true });
    input().value = "five";
    controllerFor(application).input();
    const emptyItem = items().find((item) => item.dataset.value === "5");
    expect(emptyItem.classList.contains("hidden")).toBe(true);
  });

  it("logs an error when a default match has no label", async () => {
    application = await mount({ blankLabelItem: true, inputValue: "6" });
    expect(consoleError).toHaveBeenCalled();
  });

  it.each(["input", "dropdown", "scroller"])(
    "logs an error when the %s target is missing",
    async (missing) => {
      application = await mount({ missing });
      expect(root().getAttribute("data-controller-connected")).toBeNull();
      expect(consoleError).toHaveBeenCalled();
    },
  );
});
