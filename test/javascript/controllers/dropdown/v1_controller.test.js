import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";
import DropdownV1Controller from "../../../../app/javascript/controllers/dropdown/v1_controller.js";

const mockState = { instances: [] };

// Flowbite's Dropdown is provided as a global at runtime; stub it so show/hide
// are deterministic and the onShow/onHide option callbacks are exercised.
class DropdownMock {
  constructor(menu, trigger, options) {
    this.menu = menu;
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

function fixture({
  withCaret = true,
  empty = false,
  triggerMenuItem = false,
} = {}) {
  const caret = withCaret
    ? '<span data-dropdown--v1-target="caret">v</span>'
    : "";
  const triggerExtra = triggerMenuItem
    ? '<span role="menuitem">extra</span>'
    : "";
  const items = empty
    ? ""
    : `
        <li role="menuitem"><a href="#a">Item A</a></li>
        <li role="menuitem"></li>
        <button role="menuitem">Item C</button>
      `;
  return `
    <div
      data-controller="dropdown--v1"
      data-dropdown--v1-skidding-value="0"
      data-dropdown--v1-distance-value="8"
    >
      <button data-dropdown--v1-target="trigger">Open${triggerExtra}</button>
      ${caret}
      <div role="menu" hidden data-dropdown--v1-target="menu">${items}</div>
    </div>
  `;
}

const root = () => document.querySelector('[data-controller="dropdown--v1"]');
const trigger = () =>
  document.querySelector('[data-dropdown--v1-target="trigger"]');
const caret = () =>
  document.querySelector('[data-dropdown--v1-target="caret"]');
const menu = () => document.querySelector('[data-dropdown--v1-target="menu"]');
const menuItems = () =>
  Array.from(menu().querySelectorAll('[role="menuitem"]'));
const dropdown = () => mockState.instances.at(-1);

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
  application.register("dropdown--v1", DropdownV1Controller);
  await Promise.resolve();
  await new Promise((resolve) => requestAnimationFrame(resolve));
  return application;
}

describe("dropdown/v1 controller", () => {
  let application;

  beforeEach(() => {
    mockState.instances = [];
    vi.stubGlobal("Dropdown", DropdownMock);
  });

  afterEach(async () => {
    await stopApplication(application);
    document.body.innerHTML = "";
  });

  it("marks itself connected and hides menu items", async () => {
    application = await mount();
    expect(root().getAttribute("data-controller-connected")).toBe("true");
    expect(menu().getAttribute("aria-hidden")).toBe("true");
    menuItems().forEach((item) =>
      expect(item.getAttribute("tabindex")).toBe("-1"),
    );
    expect(mockState.instances).toHaveLength(1);
  });

  it("applies show/hide ARIA state through the Dropdown callbacks", async () => {
    application = await mount();

    trigger().click();
    expect(trigger().getAttribute("aria-expanded")).toBe("true");
    expect(menu().getAttribute("aria-hidden")).toBe("false");
    expect(menu().hasAttribute("hidden")).toBe(false);
    expect(caret().classList.contains("rotate-180")).toBe(true);
    expect(document.activeElement).toBe(menuItems()[0]);

    trigger().click();
    expect(trigger().getAttribute("aria-expanded")).toBe("false");
    expect(menu().getAttribute("aria-hidden")).toBe("true");
    expect(menu().hasAttribute("hidden")).toBe(true);
    expect(caret().classList.contains("rotate-180")).toBe(false);
  });

  it("hides on focusout only when focus leaves the dropdown", async () => {
    application = await mount();
    dropdown().show();

    menu().dispatchEvent(
      new FocusEvent("focusout", { bubbles: true, relatedTarget: trigger() }),
    );
    expect(dropdown().isVisible()).toBe(true);

    menu().dispatchEvent(
      new FocusEvent("focusout", {
        bubbles: true,
        relatedTarget: document.body,
      }),
    );
    expect(dropdown().isVisible()).toBe(false);
  });

  it("opens with keyboard keys on the trigger", async () => {
    application = await mount();

    press(trigger(), "Enter");
    expect(document.activeElement).toBe(menuItems()[0]);
    dropdown().hide();

    press(trigger(), " ");
    expect(document.activeElement).toBe(menuItems()[0]);
    dropdown().hide();

    press(trigger(), "ArrowDown");
    expect(document.activeElement).toBe(menuItems()[0]);
    dropdown().hide();

    press(trigger(), "ArrowUp");
    expect(document.activeElement).toBe(menuItems().at(-1));

    press(trigger(), "a");
    expect(document.activeElement).toBe(menuItems().at(-1));
  });

  it("closes on click when already open", async () => {
    application = await mount();
    dropdown().show();
    trigger().click();
    expect(dropdown().isVisible()).toBe(false);
  });

  it("lazy-loads menu items on turbo:frame-load when the menu starts empty", async () => {
    application = await mount({ empty: true });
    press(trigger(), "ArrowDown");
    expect(dropdown().isVisible()).toBe(true);

    menu().innerHTML =
      '<li role="menuitem"><a href="#x">X</a></li><li role="menuitem">Y</li>';
    document.dispatchEvent(new Event("turbo:frame-load"));

    const items = menuItems();
    expect(items[1].getAttribute("tabindex")).toBe("-1");
    expect(document.activeElement).toBe(items[0]);
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

  it("hides when a list item without a clickable child is activated", async () => {
    application = await mount();
    const items = menuItems();
    items[1].focus();
    press(menu(), " ");
    expect(dropdown().isVisible()).toBe(false);
  });

  it("clicks a non-list menu item directly on Enter", async () => {
    application = await mount();
    const button = menuItems()[2];
    const clickSpy = vi.spyOn(button, "click").mockImplementation(() => {});
    button.focus();
    press(menu(), "Enter");
    expect(clickSpy).toHaveBeenCalled();
  });

  it("focuses the trigger on Escape", async () => {
    application = await mount();
    const triggerFocus = vi.spyOn(trigger(), "focus");
    menuItems()[0].focus();
    const event = press(menu(), "Escape");
    expect(event.defaultPrevented).toBe(true);
    expect(triggerFocus).toHaveBeenCalled();
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

  it("closes on Shift+Tab and ignores plain Tab", async () => {
    application = await mount();
    const items = menuItems();
    const triggerFocus = vi.spyOn(trigger(), "focus");

    items[0].focus();
    const shiftTab = press(menu(), "Tab", { shiftKey: true });
    expect(shiftTab.defaultPrevented).toBe(true);
    expect(triggerFocus).toHaveBeenCalled();
    expect(dropdown().isVisible()).toBe(false);

    dropdown().show();
    items[0].focus();
    const tab = press(menu(), "Tab");
    expect(tab.defaultPrevented).toBe(false);
    expect(dropdown().isVisible()).toBe(true);
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
    expect(dropdown().isVisible()).toBe(true);
    trigger().click();
    expect(dropdown().isVisible()).toBe(false);
  });

  it("resets the tabindex of menuitems found within the trigger on hide", async () => {
    application = await mount({ triggerMenuItem: true });
    const triggerItem = trigger().querySelector('[role="menuitem"]');
    triggerItem.setAttribute("tabindex", "0");

    dropdown().show();
    dropdown().hide();

    expect(triggerItem.getAttribute("tabindex")).toBe("-1");
  });
});
