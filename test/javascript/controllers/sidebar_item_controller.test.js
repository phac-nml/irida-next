import { startApplication, stopApplication } from "../helpers/stimulus.js";
import { afterEach, describe, expect, it, vi } from "vitest";
import SidebarItemController from "../../../app/javascript/controllers/sidebar_item_controller.js";

describe("sidebar item controller", () => {
  let application;
  async function mount(disabled = false) {
    document.body.innerHTML = `<div data-controller="sidebar-item" ${disabled ? "data-disabled" : ""}><a href="#page" data-action="sidebar-item#onClick">Page</a></div>`;
    application = startApplication();
    application.register("sidebar-item", SidebarItemController);
    await Promise.resolve();
    return document.body.firstElementChild;
  }
  afterEach(async () => {
    await stopApplication(application);
  });

  it.each([true, false])(
    "cancels navigation and propagation only when disabled=%s",
    async (disabled) => {
      const root = await mount(disabled);
      const bubbled = vi.fn();
      root.addEventListener("click", bubbled);
      const event = new MouseEvent("click", {
        bubbles: true,
        cancelable: true,
      });
      root.querySelector("a").dispatchEvent(event);
      expect(event.defaultPrevented).toBe(disabled);
      expect(bubbled).toHaveBeenCalledTimes(disabled ? 0 : 1);
    },
  );

  it("keeps the active class and current-page semantics in sync", async () => {
    const root = await mount();
    const controller = application.getControllerForElementAndIdentifier(
      root,
      "sidebar-item",
    );
    controller.setActive(true);
    expect(root).toHaveClass("active");
    expect(root).toHaveAttribute("aria-current", "page");
    controller.setActive(false);
    expect(root).not.toHaveClass("active");
    expect(root).not.toHaveAttribute("aria-current");
  });
});
