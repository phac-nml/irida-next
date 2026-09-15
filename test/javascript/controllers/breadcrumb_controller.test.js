import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import BreadcrumbController from "../../../app/javascript/controllers/breadcrumb_controller.js";

describe("breadcrumb controller", () => {
  let application, element, list, dropdown, crumbs, observers, availableWidth;
  beforeEach(() => {
    observers = [];
    vi.stubGlobal(
      "ResizeObserver",
      vi.fn(function (callback) {
        this.callback = callback;
        this.observe = vi.fn();
        this.disconnect = vi.fn();
        observers.push(this);
      }),
    );
  });
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount({
    widths = [80, 70, 100],
    width = 300,
    dropdownWidth = 30,
    currentLabel = true,
  } = {}) {
    availableWidth = width;
    document.body.innerHTML = `<nav aria-label="Breadcrumb" data-controller="breadcrumb">
      <ol data-breadcrumb-target="list">
        <li class="invisible absolute" data-breadcrumb-target="dropdownMenu">${widths
          .slice(0, -1)
          .map(
            (_, index) =>
              `<a role="menuitem" href="/level-${index}">Level ${index}</a>`,
          )
          .join("")}</li>
        ${widths.map((_, index) => `<li data-breadcrumb-target="crumb">${currentLabel && index === widths.length - 1 ? '<span aria-current="page" title="Current page"> Current page </span>' : `<a href="/level-${index}">Level ${index}</a>`}</li>`).join("")}
      </ol>
    </nav>`;
    element = document.querySelector("nav");
    list = element.querySelector("ol");
    dropdown = element.querySelector('[data-breadcrumb-target="dropdownMenu"]');
    crumbs = [...element.querySelectorAll('[data-breadcrumb-target="crumb"]')];
    vi.spyOn(list, "getBoundingClientRect").mockImplementation(() => ({
      width: availableWidth,
    }));
    vi.spyOn(dropdown, "getBoundingClientRect").mockReturnValue({
      width: dropdownWidth,
    });
    crumbs.forEach((crumb, index) => {
      vi.spyOn(crumb, "getBoundingClientRect").mockImplementation(() => {
        // Hidden/truncated items must be restored before measuring intrinsic widths.
        expect(crumb.classList.contains("hidden")).toBe(false);
        expect(crumb.classList.contains("truncate")).toBe(false);
        return { width: widths[index] };
      });
    });
    application = startApplication();
    application.register("breadcrumb", BreadcrumbController);
    await Promise.resolve();
  }
  function resize(width = availableWidth) {
    availableWidth = width;
    observers.at(-1).callback();
  }
  function visible() {
    return crumbs.flatMap((crumb, index) =>
      crumb.classList.contains("hidden") ? [] : [index],
    );
  }
  function menuVisible() {
    return [...dropdown.querySelectorAll('[role="menuitem"]')].flatMap(
      (item, index) => (item.classList.contains("hidden") ? [] : [index]),
    );
  }
  it("observes the breadcrumb list and hides overflow when everything fits", async () => {
    await mount();
    expect(observers[0].observe).toHaveBeenCalledExactlyOnceWith(list);
    resize();
    expect(visible()).toEqual([0, 1, 2]);
    expect(menuVisible()).toEqual([]);
    expect(dropdown.classList.contains("invisible")).toBe(true);
    expect(dropdown.classList.contains("absolute")).toBe(true);
    expect(dropdown.classList.contains("inline-flex")).toBe(false);
  });
  it("keeps all breadcrumbs visible when their widths exactly fit", async () => {
    await mount({ width: 250 });
    resize();
    expect(visible()).toEqual([0, 1, 2]);
    expect(dropdown.classList.contains("invisible")).toBe(true);
  });
  it("reserves overflow-button width and keeps the nearest ancestors", async () => {
    await mount({ width: 230 });
    resize();
    expect(visible()).toEqual([1, 2]);
    expect(menuVisible()).toEqual([0]);
    expect(dropdown.classList.contains("inline-flex")).toBe(true);
    expect(dropdown.classList.contains("absolute")).toBe(false);
    expect(dropdown.classList.contains("invisible")).toBe(false);
  });
  it("fits an ancestor exactly alongside the current page and overflow button", async () => {
    await mount({ width: 200 });
    resize();
    expect(visible()).toEqual([1, 2]);
    expect(menuVisible()).toEqual([0]);
  });
  it.each([150, 50])(
    "retains the current page at narrow width %i",
    async (width) => {
      await mount({ width });
      resize();
      expect(visible()).toEqual([2]);
      expect(menuVisible()).toEqual([0, 1]);
      expect(crumbs[2].classList.contains("truncate")).toBe(true);
      expect(crumbs[2].querySelector('[aria-current="page"]').title).toBe(
        "Current page",
      );
    },
  );
  it("restores hidden ancestors and removes truncation when widened", async () => {
    await mount({ width: 150 });
    resize();
    resize(300);
    expect(visible()).toEqual([0, 1, 2]);
    expect(crumbs[2].classList.contains("truncate")).toBe(false);
    expect(menuVisible()).toEqual([]);
  });
  it.each([[[]], [[100]]])(
    "handles zero or one breadcrumb without overflow: %j",
    async (widths) => {
      await mount({ widths });
      resize();
      expect(visible()).toEqual(widths.map((_, i) => i));
      expect(dropdown.classList.contains("invisible")).toBe(true);
    },
  );
  it("restores a previously hidden breadcrumb when it becomes the only item after a morph", async () => {
    await mount({ width: 150 });
    resize();
    crumbs[1].remove();
    crumbs[2].remove();
    dropdown.replaceChildren();
    document.dispatchEvent(new Event("turbo:morph"));
    expect(crumbs[0].classList.contains("hidden")).toBe(false);
    expect(dropdown.classList.contains("invisible")).toBe(true);
  });
  it("updates visibility even if a current-page label is absent", async () => {
    await mount({ width: 150, currentLabel: false });
    resize();
    expect(visible()).toEqual([2]);
  });
  it("recalculates on morph and releases the observer and listener on disconnect", async () => {
    await mount();
    resize();
    availableWidth = 150;
    document.dispatchEvent(new Event("turbo:morph"));
    expect(visible()).toEqual([2]);
    element.remove();
    await Promise.resolve();
    expect(observers[0].disconnect).toHaveBeenCalledOnce();
    availableWidth = 300;
    document.dispatchEvent(new Event("turbo:morph"));
    expect(visible()).toEqual([2]);
    document.body.append(element);
    await Promise.resolve();
    expect(observers).toHaveLength(2);
    resize();
    expect(visible()).toEqual([0, 1, 2]);
  });
  it("disconnects safely if observer creation fails during connection", async () => {
    const error = new Error("Observer unavailable");
    ResizeObserver.mockImplementationOnce(function () {
      throw error;
    });
    document.body.innerHTML = '<nav data-controller="breadcrumb"></nav>';
    element = document.querySelector("nav");
    application = startApplication();
    const report = vi
      .spyOn(application, "handleError")
      .mockImplementation(() => {});
    application.register("breadcrumb", BreadcrumbController);
    await Promise.resolve();
    expect(report).toHaveBeenCalledExactlyOnceWith(
      error,
      "Error connecting controller",
      expect.any(Object),
    );
    report.mockRestore();
    element.remove();
    await Promise.resolve();
  });
});
