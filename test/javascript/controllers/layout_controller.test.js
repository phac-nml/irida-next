import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import LayoutController from "../../../app/javascript/controllers/layout_controller.js";
import { announce } from "utilities/live_region";
import { focusWhenVisible } from "utilities/focus";
vi.mock("utilities/live_region", () => ({ announce: vi.fn() }));
vi.mock("utilities/focus", () => ({ focusWhenVisible: vi.fn() }));

describe("layout controller", () => {
  let application, element, layout, originalStyle;
  beforeEach(() => {
    originalStyle = document.documentElement.getAttribute("style");
    document.documentElement.style.fontSize = "16px";
  });
  afterEach(async () => {
    await stopApplication(application);
    if (originalStyle === null)
      document.documentElement.removeAttribute("style");
    else document.documentElement.setAttribute("style", originalStyle);
  });
  async function mount({
    saved,
    width = 1440,
    buttons = true,
    announcement = true,
    messages = true,
  } = {}) {
    if (saved) localStorage.setItem("layout", saved);
    vi.stubGlobal("innerWidth", width);
    document.body.innerHTML = `<div data-controller="layout" ${messages ? 'data-layout-collapsed-announcement-value="Sidebar collapsed" data-layout-expanded-announcement-value="Sidebar expanded"' : ""}>
      <div data-layout-target="layoutContainer" class="max-xl:collapsed">
        ${buttons ? '<button data-layout-target="collapseButton" data-action="layout#collapse">Collapse</button>' : ""}
        <div data-layout-target="expandButtonContainer" class="xl:hidden">
          ${buttons ? '<button data-layout-target="expandButton" data-action="layout#expand">Expand</button>' : ""}
        </div>
        <main data-layout-target="content"></main>
        <div tabindex="0" data-action="focus->layout#handleContentFocus"></div>
      </div>
      ${announcement ? '<div data-layout-target="announcement"></div>' : ""}
    </div>`;
    element = document.body.firstElementChild;
    layout = element.querySelector('[data-layout-target="layoutContainer"]');
    application = startApplication();
    application.register("layout", LayoutController);
    await Promise.resolve();
  }
  function button(target) {
    return element.querySelector(`[data-layout-target="${target}"]`);
  }
  function expanded(value) {
    for (const target of ["collapseButton", "expandButton"])
      expect(button(target).getAttribute("aria-expanded")).toBe(String(value));
  }
  it("initializes an expanded sidebar without moving focus or announcing", async () => {
    await mount();
    expanded(true);
    expect(announce).not.toHaveBeenCalled();
    expect(focusWhenVisible).not.toHaveBeenCalled();
  });
  it("restores a collapsed sidebar silently", async () => {
    await mount({ saved: "collapsed" });
    expanded(false);
    expect(layout.classList.contains("collapsed")).toBe(true);
    expect(
      button("expandButtonContainer").classList.contains("xl:hidden"),
    ).toBe(false);
    expect(announce).not.toHaveBeenCalled();
    expect(focusWhenVisible).not.toHaveBeenCalled();
  });
  it.each([1024, 1440])(
    "persists user changes and transfers focus at width %i",
    async (width) => {
      await mount({ width });
      button("collapseButton").click();
      expanded(false);
      expect(localStorage.getItem("layout")).toBe("collapsed");
      expect(focusWhenVisible).toHaveBeenLastCalledWith(button("expandButton"));
      expect(announce).toHaveBeenLastCalledWith("Sidebar collapsed", {
        element: button("announcement"),
      });
      button("expandButton").click();
      expanded(true);
      expect(localStorage.getItem("layout")).toBe("expanded");
      expect(layout.classList.contains("collapsed")).toBe(false);
      expect(layout.classList.contains("max-xl:collapsed")).toBe(width >= 1280);
      expect(
        button("expandButtonContainer").classList.contains("xl:hidden"),
      ).toBe(true);
      expect(focusWhenVisible).toHaveBeenLastCalledWith(
        button("collapseButton"),
      );
      expect(announce).toHaveBeenLastCalledWith("Sidebar expanded", {
        element: button("announcement"),
      });
    },
  );
  it("keeps user announcements enabled after a Turbo morph restores collapsed state", async () => {
    await mount({ saved: "collapsed" });
    layout.classList.remove("collapsed");
    document.dispatchEvent(new Event("turbo:morph"));
    expect(layout.classList.contains("collapsed")).toBe(true);
    expect(announce).not.toHaveBeenCalled();
    button("expandButton").click();
    expect(announce).toHaveBeenCalledWith(
      "Sidebar expanded",
      expect.any(Object),
    );
  });
  it("collapses an open narrow sidebar when focus enters the content, without stealing focus", async () => {
    await mount({ width: 1024 });
    button("expandButton").click();
    focusWhenVisible.mockClear();
    element.querySelector('[tabindex="0"]').focus();
    expect(layout.classList.contains("collapsed")).toBe(true);
    expect(focusWhenVisible).not.toHaveBeenCalled();
    announce.mockClear();
    element
      .querySelector('[tabindex="0"]')
      .dispatchEvent(new FocusEvent("focus"));
    expect(announce).not.toHaveBeenCalled();
  });
  it("keeps a wide sidebar open when content receives focus", async () => {
    await mount();
    element.querySelector('[tabindex="0"]').focus();
    expanded(true);
  });
  it("supports layouts without optional buttons or an announcement target", async () => {
    await mount({ saved: "collapsed", buttons: false, announcement: false });
    const controller = application.getControllerForElementAndIdentifier(
      element,
      "layout",
    );
    controller.collapse(new Event("click"));
    expect(layout.classList.contains("collapsed")).toBe(true);
    expect(announce).not.toHaveBeenCalled();
    expect(focusWhenVisible).not.toHaveBeenCalled();
  });
  it.each([{ announcement: false }, { messages: false }])(
    "does not announce without configured feedback: %j",
    async (options) => {
      await mount(options);
      button("collapseButton").click();
      button("expandButton").click();
      expect(announce).not.toHaveBeenCalled();
    },
  );
  it("removes the document listener on disconnect and registers it once on reconnect", async () => {
    await mount();
    element.remove();
    await Promise.resolve();
    const read = vi.spyOn(Storage.prototype, "getItem");
    document.dispatchEvent(new Event("turbo:morph"));
    expect(read).not.toHaveBeenCalled();
    document.body.append(element);
    await Promise.resolve();
    read.mockClear();
    document.dispatchEvent(new Event("turbo:morph"));
    expect(read).toHaveBeenCalledOnce();
  });
});
