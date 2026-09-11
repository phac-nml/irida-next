import { startApplication, stopApplication } from "../helpers/stimulus.js";
import { afterEach, describe, expect, it, vi } from "vitest";
import CollapsibleController from "../../../app/javascript/controllers/collapsible_controller.js";

describe("collapsible controller", () => {
  let application;
  let root;
  let controller;
  const target = (name) =>
    root.querySelector(`[data-collapsible-target="${name}"]`);

  async function mount({
    attributes = 'class="hidden"',
    icon = true,
    id = 'id="section"',
    button = true,
    item = true,
  } = {}) {
    document.body.innerHTML = `<div data-controller="collapsible">
      ${button ? '<button data-collapsible-target="button" data-action="collapsible#toggle">Toggle</button>' : ""}
      ${item ? `<div data-collapsible-target="item" ${id} ${attributes}>Content</div>` : ""}
      ${icon ? '<span data-collapsible-target="icon" class="rotate-0"></span>' : ""}
    </div>`;
    root = document.body.firstElementChild;
    application = startApplication();
    application.register("collapsible", CollapsibleController);
    await Promise.resolve();
    controller = application.getControllerForElementAndIdentifier(
      root,
      "collapsible",
    );
  }

  afterEach(async () => {
    await stopApplication(application);
  });

  it("expands and collapses through the button, updating semantics and events", async () => {
    await mount();
    const expanded = vi.fn();
    const collapsed = vi.fn();
    root.addEventListener("collapsible:expanded", expanded);
    root.addEventListener("collapsible:collapsed", collapsed);
    expect(target("button")).toHaveAttribute("aria-controls", "section");
    expect(target("button")).toHaveAttribute("aria-expanded", "false");
    target("button").click();
    expect(target("item")).not.toHaveClass("hidden");
    expect(target("item")).toHaveAttribute("aria-hidden", "false");
    expect(target("item")).not.toHaveAttribute("hidden");
    expect(target("item")).not.toHaveAttribute("tabindex");
    expect(target("button")).toHaveAttribute("aria-expanded", "true");
    expect(target("icon")).toHaveClass("rotate-180");
    expect(expanded).toHaveBeenCalledOnce();
    target("button").click();
    expect(target("item")).toHaveClass("hidden");
    expect(target("item")).toHaveAttribute("hidden");
    expect(target("item")).toHaveAttribute("aria-hidden", "true");
    expect(target("button")).toHaveAttribute("aria-expanded", "false");
    expect(target("icon")).toHaveClass("rotate-0");
    expect(collapsed).toHaveBeenCalledOnce();
  });

  it("recognizes native hidden markup on connection", async () => {
    await mount({ attributes: "hidden" });
    expect(target("button")).toHaveAttribute("aria-expanded", "false");
    expect(target("icon")).not.toHaveClass("rotate-180");
    controller.toggle();
    expect(target("item")).not.toHaveAttribute("hidden");
  });

  it("preserves opt-in focusability only while expanded without requiring an icon", async () => {
    await mount({
      attributes: 'class="hidden" data-collapsible-focusable',
      icon: false,
      id: 'data-id="fallback"',
    });
    expect(target("button")).toHaveAttribute("aria-controls", "fallback");
    controller.toggle();
    expect(target("item")).toHaveAttribute("tabindex", "0");
    controller.toggle();
    expect(target("item")).not.toHaveAttribute("tabindex");
  });

  it("initializes expanded sections and cancels the toggle event", async () => {
    await mount({ attributes: "", id: "" });
    expect(target("button")).toHaveAttribute("aria-expanded", "true");
    expect(target("button")).toHaveAttribute("aria-controls", "");
    const event = new MouseEvent("click", { bubbles: true, cancelable: true });
    const bubbled = vi.fn();
    root.addEventListener("click", bubbled);
    target("button").dispatchEvent(event);
    expect(event.defaultPrevented).toBe(true);
    expect(bubbled).not.toHaveBeenCalled();
  });
  it("keeps the expanded icon state when the same section reconnects", async () => {
    await mount({ attributes: "" });
    root.remove();
    await Promise.resolve();
    await Promise.resolve();
    document.body.append(root);
    await Promise.resolve();
    expect(target("button")).toHaveAttribute("aria-expanded", "true");
    expect(target("icon")).toHaveClass("rotate-180");
    controller.toggle();
    expect(target("icon")).toHaveClass("rotate-0");
  });

  it.each(["item", "button"])(
    "reports a missing required %s target",
    async (missing) => {
      const warning = vi.spyOn(console, "warn").mockImplementation(() => {});
      await mount({ [missing]: false });
      expect(warning).toHaveBeenCalledWith(
        `⚠️ Collapsible controller missing ${missing} target`,
      );
      const stopped = stopApplication(application);
      application = undefined;
      await expect(stopped).rejects.toThrow();
    },
  );
});
