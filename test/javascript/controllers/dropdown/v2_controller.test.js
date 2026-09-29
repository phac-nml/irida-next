import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";

const mockState = vi.hoisted(() => ({ instances: [] }));

// FloatingDropdown is unit-tested separately; mock it so show/hide are
// deterministic and the controller's onShow/onHide callbacks are exercised.
vi.mock("utilities/floating_dropdown", () => ({
  default: class FloatingDropdownMock {
    constructor(options) {
      this.options = options;
      this.visible = false;
      this.destroy = vi.fn();
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
  },
}));

const DropdownV2Controller = (
  await import("../../../../app/javascript/controllers/dropdown/v2_controller.js")
).default;

function fixture({ withCaret = true, empty = false } = {}) {
  const caret = withCaret
    ? '<span data-dropdown--v2-target="caret">v</span>'
    : "";
  const items = empty
    ? ""
    : `
        <li role="menuitem"><a href="#a">Item A</a></li>
        <li role="menuitem"></li>
        <button role="menuitem">Item C</button>
      `;
  return `
    <div data-controller="dropdown--v2" data-dropdown--v2-distance-value="8">
      <button data-dropdown--v2-target="trigger">Open</button>
      ${caret}
      <div role="menu" data-dropdown--v2-target="menu">${items}</div>
    </div>
  `;
}

const trigger = () =>
  document.querySelector('[data-dropdown--v2-target="trigger"]');
const caret = () =>
  document.querySelector('[data-dropdown--v2-target="caret"]');
const menu = () => document.querySelector('[data-dropdown--v2-target="menu"]');
const menuItems = () =>
  Array.from(menu().querySelectorAll('[role="menuitem"]'));
const fd = () => mockState.instances.at(-1);

function press(el, key, options = {}) {
  const event = new KeyboardEvent("keydown", {
    key,
    bubbles: true,
    cancelable: true,
    ...options,
  });
  el.dispatchEvent(event);
  return event;
}

async function mount(options) {
  document.body.innerHTML = fixture(options);
  const application = startApplication();
  application.register("dropdown--v2", DropdownV2Controller);
  await Promise.resolve();
  await new Promise((resolve) => requestAnimationFrame(resolve));
  return application;
}

describe("dropdown/v2 controller", () => {
  let application;

  beforeEach(() => {
    mockState.instances = [];
  });

  afterEach(async () => {
    await stopApplication(application);
    document.body.innerHTML = "";
  });

  it("builds a FloatingDropdown on connect and hides menu items", async () => {
    application = await mount();
    expect(mockState.instances).toHaveLength(1);
    expect(menu().getAttribute("aria-hidden")).toBe("true");
    menuItems().forEach((item) =>
      expect(item.getAttribute("tabindex")).toBe("-1"),
    );
  });

  it("recreates the FloatingDropdown on turbo:morph and destroys it on disconnect", async () => {
    application = await mount();
    const first = fd();

    document.dispatchEvent(new Event("turbo:morph"));
    expect(mockState.instances).toHaveLength(2);
    expect(fd()).not.toBe(first);

    await stopApplication(application);
    application = null;
    expect(mockState.instances.at(-1).destroy).toHaveBeenCalled();
  });

  it("toggles the menu on trigger click", async () => {
    application = await mount();
    const focusSpy = vi.spyOn(trigger(), "focus");

    trigger().click();
    expect(fd().isVisible()).toBe(true);
    expect(caret().classList.contains("rotate-180")).toBe(true);
    expect(document.activeElement).toBe(menuItems()[0]);

    trigger().click();
    expect(fd().isVisible()).toBe(false);
    expect(caret().classList.contains("rotate-180")).toBe(false);
    expect(focusSpy).toHaveBeenCalled();
  });

  it("opens on Enter, Space, and ArrowDown to the first item, ArrowUp to the last", async () => {
    application = await mount();

    press(trigger(), "Enter");
    expect(document.activeElement).toBe(menuItems()[0]);
    fd().hide();

    press(trigger(), " ");
    expect(document.activeElement).toBe(menuItems()[0]);
    fd().hide();

    press(trigger(), "ArrowDown");
    expect(document.activeElement).toBe(menuItems()[0]);
    fd().hide();

    press(trigger(), "ArrowUp");
    expect(document.activeElement).toBe(menuItems().at(-1));
  });

  it("ignores unrelated keys on the trigger", async () => {
    application = await mount();
    press(trigger(), "a");
    expect(fd().isVisible()).toBe(false);
  });

  it("lazy-loads menu items on turbo:frame-load when the menu starts empty", async () => {
    application = await mount({ empty: true });
    press(trigger(), "ArrowDown");
    expect(fd().isVisible()).toBe(true);
    expect(document.activeElement).toBe(menu());

    menu().innerHTML =
      '<li role="menuitem"><a href="#x">X</a></li><li role="menuitem">Y</li>';
    document.dispatchEvent(new Event("turbo:frame-load"));

    const items = menuItems();
    expect(items[1].getAttribute("tabindex")).toBe("-1");
    expect(document.activeElement).toBe(items[0]);
    expect(items[0].tabIndex).toBe(0);
  });

  it("activates a list item's clickable child on Enter and refocuses the trigger after morph", async () => {
    application = await mount();
    const items = menuItems();
    const link = items[0].querySelector("a");
    const clickSpy = vi.spyOn(link, "click").mockImplementation(() => {});
    const triggerFocus = vi.spyOn(trigger(), "focus");

    items[0].focus();
    press(menu(), "Enter");
    expect(clickSpy).toHaveBeenCalled();

    document.dispatchEvent(new Event("turbo:morph"));
    expect(triggerFocus).toHaveBeenCalled();
  });

  it("hides the dropdown when a list item without a clickable child is activated", async () => {
    application = await mount();
    const items = menuItems();
    items[1].focus();
    press(menu(), " ");
    expect(fd().isVisible()).toBe(false);
  });

  it("clicks a non-list menu item directly on Enter", async () => {
    application = await mount();
    const items = menuItems();
    const button = items[2];
    const clickSpy = vi.spyOn(button, "click").mockImplementation(() => {});
    button.focus();
    press(menu(), "Enter");
    expect(clickSpy).toHaveBeenCalled();
  });

  it("hides on Escape", async () => {
    application = await mount();
    fd().show();
    menuItems()[0].focus();
    press(menu(), "Escape");
    expect(fd().isVisible()).toBe(false);
  });

  it("wraps focus with ArrowUp and ArrowDown", async () => {
    application = await mount();
    const items = menuItems();

    items[0].focus();
    press(menu(), "ArrowUp");
    expect(document.activeElement).toBe(items.at(-1));

    items.at(-1).focus();
    press(menu(), "ArrowDown");
    expect(document.activeElement).toBe(items[0]);

    items[0].focus();
    press(menu(), "ArrowDown");
    expect(document.activeElement).toBe(items[1]);

    items[1].focus();
    press(menu(), "ArrowUp");
    expect(document.activeElement).toBe(items[0]);
  });

  it("jumps to first and last items with Home and End", async () => {
    application = await mount();
    const items = menuItems();

    items[1].focus();
    press(menu(), "Home");
    expect(document.activeElement).toBe(items[0]);

    items[0].focus();
    press(menu(), "End");
    expect(document.activeElement).toBe(items.at(-1));
  });

  it("closes on Shift+Tab (focuses trigger) and on plain Tab", async () => {
    application = await mount();
    const items = menuItems();
    const triggerFocus = vi.spyOn(trigger(), "focus");

    items[0].focus();
    const shiftTab = press(menu(), "Tab", { shiftKey: true });
    expect(shiftTab.defaultPrevented).toBe(true);
    expect(triggerFocus).toHaveBeenCalled();
    expect(fd().isVisible()).toBe(false);

    fd().show();
    items[0].focus();
    const tab = press(menu(), "Tab");
    expect(tab.defaultPrevented).toBe(false);
    expect(fd().isVisible()).toBe(false);
  });

  it("ignores unrelated keys inside the menu", async () => {
    application = await mount();
    menuItems()[0].focus();
    press(menu(), "x");
    expect(document.activeElement).toBe(menuItems()[0]);
  });

  it("works without a caret target", async () => {
    application = await mount({ withCaret: false });
    trigger().click();
    expect(fd().isVisible()).toBe(true);
    trigger().click();
    expect(fd().isVisible()).toBe(false);
  });
});
