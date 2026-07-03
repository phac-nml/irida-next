import { Application } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";

import DropdownV2Controller from "../../../../app/javascript/controllers/dropdown/v2_controller";
import ToolbarController from "../../../../../pathogen-view-components/app/assets/javascripts/pathogen_view_components/toolbar_controller";

vi.mock("utilities/floating_dropdown", () => {
  class MockFloatingDropdown {
    #visible = false;

    constructor({ trigger, dropdown, onShow, onHide }) {
      this.trigger = trigger;
      this.dropdown = dropdown;
      this.onShow = onShow;
      this.onHide = onHide;
    }

    isVisible() {
      return this.#visible;
    }

    show() {
      this.#visible = true;
      this.trigger.setAttribute("aria-expanded", "true");
      this.dropdown.removeAttribute("aria-hidden");
      this.dropdown.removeAttribute("hidden");
      this.onShow?.();
    }

    hide() {
      this.#visible = false;
      this.trigger.setAttribute("aria-expanded", "false");
      this.dropdown.setAttribute("aria-hidden", "true");
      this.dropdown.setAttribute("hidden", "");
      this.onHide?.();
    }

    destroy() {
      this.hide();
    }
  }

  return { default: MockFloatingDropdown };
});

const flush = async () => {
  await Promise.resolve();
};

const dispatchKey = (target, key) => {
  const event = new KeyboardEvent("keydown", {
    bubbles: true,
    cancelable: true,
    key,
  });

  target.dispatchEvent(event);

  return event;
};

const toolbarDropdownMarkup = () => `
  <div
    role="toolbar"
    data-controller="pathogen--toolbar"
    data-action="keydown->pathogen--toolbar#handleKeyDown focusin->pathogen--toolbar#handleFocusIn"
  >
    <div
      data-controller="dropdown--v2"
      data-dropdown--v2-distance-value="10"
      data-dropdown--v2-caret-value="false"
    >
      <button
        id="menu-trigger"
        type="button"
        data-dropdown--v2-target="trigger"
        data-pathogen--toolbar-target="item"
        tabindex="0"
        aria-haspopup="true"
        aria-expanded="false"
        aria-controls="sample-menu"
      >
        Actions
      </button>
      <ul
        id="sample-menu"
        role="menu"
        data-dropdown--v2-target="menu"
        aria-labelledby="menu-trigger"
        aria-hidden="true"
        hidden
      >
        <li role="none">
          <form action="/clone" method="post" class="button_to">
            <button id="menu-first" type="submit" role="menuitem" tabindex="-1">
              Clone
            </button>
          </form>
        </li>
        <li role="none">
          <form action="/transfer" method="post" class="button_to">
            <button id="menu-second" type="submit" role="menuitem" tabindex="-1">
              Transfer
            </button>
          </form>
        </li>
      </ul>
    </div>
  </div>
`;

describe("dropdown/v2_controller with pathogen toolbar", () => {
  let application;

  const startControllers = async () => {
    document.body.innerHTML = toolbarDropdownMarkup();

    application?.stop();
    application = Application.start();
    application.register("pathogen--toolbar", ToolbarController);
    application.register("dropdown--v2", DropdownV2Controller);

    await flush();
  };

  afterEach(() => {
    application?.stop();
    document.body.innerHTML = "";
  });

  it("moves focus into the menu from the trigger with ArrowDown while open", async () => {
    await startControllers();

    const trigger = document.querySelector("#menu-trigger");
    const first = document.querySelector("#menu-first");
    const second = document.querySelector("#menu-second");

    trigger.focus();
    dispatchKey(trigger, "ArrowDown");
    expect(trigger.getAttribute("aria-expanded")).toBe("true");
    expect(document.activeElement).toBe(first);

    dispatchKey(document.activeElement, "ArrowDown");
    expect(document.activeElement).toBe(second);
  });

  it("does not let the toolbar capture ArrowDown while the menu is open", async () => {
    await startControllers();

    const trigger = document.querySelector("#menu-trigger");
    trigger.focus();
    dispatchKey(trigger, "ArrowDown");

    const event = dispatchKey(trigger, "ArrowDown");

    expect(event.defaultPrevented).toBe(true);
    expect(document.activeElement.id).toBe("menu-second");
    expect(document.querySelector("#item-one")).not.toBe(
      document.activeElement,
    );
  });

  it("keeps focus in a lazily loaded menu after the turbo frame loads", async () => {
    await startControllers();

    const trigger = document.querySelector("#menu-trigger");
    const menu = document.querySelector("#sample-menu");

    // Simulate the metadata-template dropdown: the menu is empty until its
    // lazy turbo frame loads its items.
    menu.innerHTML = "";
    trigger.focus();
    dispatchKey(trigger, "ArrowDown");

    // Frame content arrives, then Turbo fires turbo:frame-load.
    menu.innerHTML = `
      <li role="none">
        <button id="lazy-first" type="submit" role="menuitemradio" tabindex="-1">All</button>
      </li>
      <li role="none">
        <button id="lazy-second" type="submit" role="menuitemradio" tabindex="-1">None</button>
      </li>
    `;
    document.dispatchEvent(
      new CustomEvent("turbo:frame-load", { bubbles: true }),
    );
    await flush();

    expect(document.activeElement.id).toBe("lazy-first");

    dispatchKey(document.activeElement, "ArrowDown");
    expect(document.activeElement.id).toBe("lazy-second");
  });
});
