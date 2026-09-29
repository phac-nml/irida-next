import { Application } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import TableController from "../../../app/javascript/controllers/table_controller.js";

// jsdom has no layout. Supply geometry at the browser boundary; use real
// Stimulus actions and the production debounce implementation throughout.
const rect = (left = 0, top = 0, width = 300, height = 200) => ({
  left,
  top,
  right: left + width,
  bottom: top + height,
  width,
  height,
});
const dimensions = (element, values) => {
  for (const [key, value] of Object.entries(values))
    Object.defineProperty(element, key, { configurable: true, value });
};

describe("table", () => {
  let application;
  let controller;
  let root;
  let scroller;
  let cells;
  let sticky;

  async function mount({
    reduced = false,
    media = "normal",
    overflow = "auto",
    scrollable = true,
  } = {}) {
    vi.useFakeTimers();
    if (media === "missing") vi.stubGlobal("matchMedia", undefined);
    else if (media === "empty")
      vi.stubGlobal(
        "matchMedia",
        vi.fn(() => undefined),
      );
    else if (media === "throw")
      vi.stubGlobal(
        "matchMedia",
        vi.fn(() => {
          throw new Error("media failed");
        }),
      );
    else
      vi.stubGlobal(
        "matchMedia",
        vi.fn(() => ({ matches: reduced })),
      );
    document.body.innerHTML = `<div id="scroller" style="overflow-x:${overflow}">
      <table id="table"><thead><tr><th>Header</th></tr></thead>
      <tbody data-controller="table" data-action="focusin->table#handleCellFocus">
        <tr id="first"><td style="position:sticky;left:0px">Pinned</td><td tabindex="0">First</td><td tabindex="0">Other</td></tr>
        <tr><td>Pinned</td><td tabindex="0">Middle</td></tr>
        <tr><td>Pinned</td><td tabindex="0">Last</td></tr>
      </tbody><tfoot><tr><td>Footer</td></tr></tfoot></table></div>`;
    scroller = document.getElementById("scroller");
    root = document.querySelector("tbody");
    cells = [...root.querySelectorAll("[tabindex]")];
    sticky = root.querySelector("td");
    dimensions(scroller, {
      scrollWidth: scrollable ? 1000 : 300,
      clientWidth: 300,
    });
    scroller.scrollLeft = 100;
    scroller.scrollTo = vi.fn();
    vi.spyOn(scroller, "getBoundingClientRect").mockReturnValue(rect());
    vi.spyOn(sticky, "getBoundingClientRect").mockReturnValue(
      rect(0, 20, 80, 20),
    );
    for (const cell of cells) {
      vi.spyOn(cell, "getBoundingClientRect").mockReturnValue(
        rect(40, 40, 100, 20),
      );
      vi.spyOn(cell, "scrollIntoView");
    }
    application = Application.start();
    application.register("table", TableController);
    // Stimulus connects through MutationObserver microtasks, not the debounce timer.
    await Promise.resolve();
    await Promise.resolve();
    controller = application.getControllerForElementAndIdentifier(
      root,
      "table",
    );
  }

  async function focus(cell = cells[0]) {
    cell.dispatchEvent(new FocusEvent("focusin", { bubbles: true }));
    await vi.advanceTimersByTimeAsync(100);
  }

  afterEach(async () => {
    document.body.replaceChildren();
    await Promise.resolve();
    application?.stop();
    vi.unstubAllEnvs();
  });

  it.each([false, true])(
    "scrolls past left sticky columns with reduced motion=%s",
    async (reduced) => {
      await mount({ reduced });
      await focus();
      expect(cells[0].scrollIntoView).toHaveBeenCalledWith({
        block: "nearest",
        inline: "nearest",
        behavior: reduced ? "auto" : "smooth",
      });
      if (reduced) expect(scroller.scrollLeft).toBe(52);
      else
        expect(scroller.scrollTo).toHaveBeenCalledWith({
          left: 52,
          behavior: "smooth",
        });
    },
  );

  it.each(["missing", "empty"])(
    "defaults to smooth motion when matchMedia is %s",
    async (media) => {
      await mount({ media });
      await focus();
      expect(scroller.scrollTo).toHaveBeenCalledWith({
        left: 52,
        behavior: "smooth",
      });
    },
  );

  it("debounces rapid focus, skips duplicate cells, and cancels pending work on disconnect", async () => {
    await mount();
    cells[0].dispatchEvent(new FocusEvent("focusin", { bubbles: true }));
    cells[1].dispatchEvent(new FocusEvent("focusin", { bubbles: true }));
    expect(scroller.scrollTo).not.toHaveBeenCalled();
    await vi.advanceTimersByTimeAsync(100);
    expect(cells[0].scrollIntoView).not.toHaveBeenCalled();
    expect(cells[1].scrollIntoView).toHaveBeenCalledOnce();
    await focus(cells[1]);
    expect(cells[1].scrollIntoView).toHaveBeenCalledOnce();
    cells[0].dispatchEvent(new FocusEvent("focusin", { bubbles: true }));
    root.remove();
    await Promise.resolve();
    await vi.advanceTimersByTimeAsync(100);
    expect(cells[0].scrollIntoView).not.toHaveBeenCalled();
  });

  it("clamps horizontal movement at both ends", async () => {
    await mount({ reduced: true });
    scroller.scrollLeft = 5;
    await focus();
    expect(scroller.scrollLeft).toBe(0);
    cells[1].getBoundingClientRect.mockReturnValue(rect(250, 40, 2000, 20));
    await focus(cells[1]);
    expect(scroller.scrollLeft).toBe(700);
  });

  it.each(["auto", "scroll", "overlay"])(
    "finds %s overflow via the shorthand property",
    async (overflow) => {
      await mount();
      scroller.style.cssText = `overflow:${overflow}`;
      // jsdom returns the initial overflow-x value instead of resolving shorthand.
      const computed = getComputedStyle;
      vi.spyOn(window, "getComputedStyle").mockImplementation((element) => {
        const style = computed(element);
        return element === scroller
          ? { ...style, overflowX: "", overflow }
          : style;
      });
      await focus();
      expect(scroller.scrollTo).toHaveBeenCalledOnce();
    },
  );

  it.each(["no overflow", "hidden overflow", "non-cell", "sticky cell"])(
    "does not scroll horizontally for %s",
    async (kind) => {
      await mount({
        scrollable: kind !== "no overflow",
        overflow: kind === "hidden overflow" ? "hidden" : "auto",
      });
      if (kind === "non-cell") await focus(root);
      else if (kind === "sticky cell") await focus(sticky);
      else {
        await focus();
        await focus(cells[1]);
        await focus();
      }
      expect(scroller.scrollTo).not.toHaveBeenCalled();
    },
  );

  it("adjusts vertical visibility around sticky headers and footers with edge-row padding", async () => {
    await mount();
    const head = document.querySelector("thead");
    const foot = document.querySelector("tfoot");
    head.style.cssText = "position:sticky;top:0px";
    foot.style.cssText = "position:sticky;bottom:0px";
    vi.spyOn(head, "getBoundingClientRect").mockReturnValue(
      rect(0, 0, 300, 30),
    );
    vi.spyOn(foot, "getBoundingClientRect").mockReturnValue(
      rect(0, 180, 300, 20),
    );
    cells[0].getBoundingClientRect.mockReturnValue(rect(100, 10, 50, 20));
    await focus();
    expect(scroller.scrollTop).toBe(-20);
    scroller.scrollTop = 0;
    cells[2].getBoundingClientRect.mockReturnValue(rect(100, 160, 50, 30));
    await focus(cells[2]);
    expect(scroller.scrollTop).toBe(26);
    scroller.scrollTop = 0;
    cells[3].getBoundingClientRect.mockReturnValue(rect(100, 160, 50, 30));
    await focus(cells[3]);
    expect(scroller.scrollTop).toBe(10);
  });

  it("caches geometry and refreshes sticky overlays after their lifetimes", async () => {
    await mount();
    const head = document.querySelector("thead");
    head.style.cssText = "position:sticky;top:0px";
    const geometry = vi
      .spyOn(head, "getBoundingClientRect")
      .mockReturnValue(rect(0, 0, 300, 10));
    await focus();
    const initial = geometry.mock.calls.length;
    await focus(cells[1]);
    await focus();
    expect(geometry).toHaveBeenCalledTimes(initial);
    expect(sticky.getBoundingClientRect).toHaveBeenCalledOnce();
    await vi.advanceTimersByTimeAsync(5001);
    await focus(cells[1]);
    expect(geometry.mock.calls.length).toBeGreaterThan(initial);
    expect(sticky.getBoundingClientRect).toHaveBeenCalledTimes(2);
  });

  it.each(["display:none", "visibility:hidden", "opacity:0"])(
    "ignores rows with %s when determining table edges",
    async (style) => {
      await mount();
      root.querySelectorAll("tr").forEach((row) => {
        row.style.cssText = style;
      });
      root.children[1].style.cssText = "";
      cells[2].getBoundingClientRect.mockReturnValue(rect(100, 0, 50, 200));
      await focus(cells[2]);
      expect(scroller.scrollTop).toBe(0);
    },
  );

  it("handles a table with no visible rows", async () => {
    await mount();
    root.querySelectorAll("tr").forEach((row) => {
      row.style.display = "none";
    });
    cells[0].getBoundingClientRect.mockReturnValue(rect(100, 0, 50, 20));
    await focus();
    expect(scroller.scrollTop).toBe(-16);
  });

  it.each(["id", "data"])("uses a tbody %s for cache keys", async (kind) => {
    await mount();
    if (kind === "id") root.id = "body";
    else root.dataset.cacheKey = "body";
    await focus();
    await focus(cells[1]);
    expect(scroller.scrollTo).toHaveBeenCalledTimes(2);
  });

  it("validates public events and quietly handles errors outside development", async () => {
    await mount();
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    controller.handleCellFocus(null);
    controller.handleCellFocus(new Event("focusin"));
    controller.handleCellFocus(new FocusEvent("focusin"));
    const text = document.createTextNode("text");
    root.append(text);
    const event = new FocusEvent("focusin");
    text.dispatchEvent(event);
    controller.handleCellFocus(event);
    expect(warn).not.toHaveBeenCalled();
    expect(scroller.scrollTo).not.toHaveBeenCalled();
  });

  it("reports initialization failure and handles missing debounce during disconnect", async () => {
    vi.stubEnv("NODE_ENV", "development");
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    await mount({ media: "throw" });
    await focus();
    controller.disconnect();
    expect(warn).toHaveBeenCalledWith(
      "TableController: Failed to initialize TableController",
      expect.objectContaining({ error: "media failed" }),
    );
    expect(warn).toHaveBeenCalledWith(
      "TableController: Error in handleCellFocus",
      expect.any(Object),
    );
  });

  it.each(["rect", "scrollIntoView", "scrollTo"])(
    "contains browser %s failures and reports context",
    async (method) => {
      await mount();
      vi.stubEnv("NODE_ENV", "development");
      const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
      const mock =
        method === "rect"
          ? cells[0].getBoundingClientRect
          : method === "scrollIntoView"
            ? cells[0].scrollIntoView
            : scroller.scrollTo;
      mock.mockImplementation(() => {
        throw new Error("browser failure");
      });
      await focus();
      expect(warn).toHaveBeenCalledWith(
        expect.stringContaining("TableController:"),
        expect.objectContaining({ error: "browser failure" }),
      );
    },
  );

  it("ignores a cell detached during the debounce interval", async () => {
    await mount();
    cells[0].dispatchEvent(new FocusEvent("focusin", { bubbles: true }));
    cells[0].remove();
    await vi.advanceTimersByTimeAsync(100);
    expect(cells[0].scrollIntoView).not.toHaveBeenCalled();
  });
  it("handles detached cells after scrollIntoView without further scrolling", async () => {
    await mount();
    cells[0].scrollIntoView.mockImplementation(() => cells[0].remove());
    await focus();
    expect(scroller.scrollTo).not.toHaveBeenCalled();
  });

  it.each(["thead", "row only", "cell only"])(
    "handles a focused cell in %s without a tbody",
    async (kind) => {
      await mount();
      const cell = cells[0];
      if (kind === "thead") document.querySelector("thead tr").append(cell);
      else if (kind === "row only") {
        const row = document.createElement("tr");
        scroller.append(row);
        row.append(cell);
      } else scroller.append(cell);
      const event = new FocusEvent("focusin");
      cell.dispatchEvent(event);
      controller.handleCellFocus(event);
      await vi.advanceTimersByTimeAsync(100);
      expect(cell.scrollIntoView).toHaveBeenCalledOnce();
    },
  );

  it.each(["auto", "failed rect"])(
    "ignores sticky overlays with %s",
    async (kind) => {
      await mount();
      document.querySelector("table").removeAttribute("id");
      const head = document.querySelector("thead");
      head.style.cssText = `position:sticky;top:${kind === "auto" ? "auto" : "0px"}`;
      sticky.style.left = kind === "auto" ? "auto" : "0px";
      if (kind === "failed rect") {
        vi.spyOn(head, "getBoundingClientRect").mockImplementation(() => {
          throw new Error("rect failed");
        });
        sticky.getBoundingClientRect.mockImplementation(() => {
          throw new Error("rect failed");
        });
      }
      await focus();
      expect(scroller.scrollTo).not.toHaveBeenCalled();
    },
  );

  it.each([
    "first row",
    "last row",
    "overlay",
    "sticky cell",
    "left overlay",
    "scroller",
  ])("contains computed-style failure in %s", async (stage) => {
    await mount();
    vi.stubEnv("NODE_ENV", "development");
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    const computed = getComputedStyle;
    let rowCalls = 0;
    vi.spyOn(window, "getComputedStyle").mockImplementation((element) => {
      if (element === root.children[0]) {
        rowCalls++;
        if (
          (stage === "first row" && rowCalls === 2) ||
          (stage === "last row" && rowCalls === 3)
        )
          throw new Error(stage);
      }
      if (
        (stage === "overlay" && element.tagName === "THEAD") ||
        (stage === "sticky cell" && element === cells[0]) ||
        (stage === "left overlay" && element === sticky) ||
        (stage === "scroller" && element === scroller)
      )
        throw new Error(stage);
      return computed(element);
    });
    await focus();
    expect(warn).toHaveBeenCalledWith(
      expect.stringContaining("TableController:"),
      expect.objectContaining({ error: stage }),
    );
  });

  it("contains unexpected errors from the focus target", async () => {
    await mount();
    vi.stubEnv("NODE_ENV", "development");
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    const closest = cells[0].closest.bind(cells[0]);
    vi.spyOn(cells[0], "closest").mockImplementation((selector) => {
      if (selector === "td, th") throw "unavailable";
      return closest(selector);
    });
    await focus();
    expect(warn).toHaveBeenCalledWith(
      "TableController: Error in internal cell focus handler",
      expect.objectContaining({ error: "unavailable" }),
    );
  });

  it("contains scrollTop setter failures", async () => {
    await mount();
    vi.stubEnv("NODE_ENV", "development");
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    cells[0].getBoundingClientRect.mockReturnValue(rect(100, 190, 50, 50));
    Object.defineProperty(scroller, "scrollTop", {
      configurable: true,
      get: () => 0,
      set: () => {
        throw new Error("scrollTop failed");
      },
    });
    await focus();
    expect(warn).toHaveBeenCalledWith(
      "TableController: Error ensuring vertical visibility",
      expect.objectContaining({ error: "scrollTop failed" }),
    );
  });

  it("skips horizontal correction when a later geometry read fails", async () => {
    await mount();
    cells[0].getBoundingClientRect
      .mockReturnValueOnce(rect(40, 40, 100, 20))
      .mockImplementation(() => {
        throw new Error("rect failed");
      });
    await focus();
    expect(scroller.scrollTo).not.toHaveBeenCalled();
  });

  it("contains horizontal calculation errors", async () => {
    await mount();
    vi.stubEnv("NODE_ENV", "development");
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    const broken = rect();
    Object.defineProperty(broken, "left", {
      get: () => {
        throw new Error("left failed");
      },
    });
    scroller.getBoundingClientRect.mockReturnValue(broken);
    await focus();
    expect(warn).toHaveBeenCalledWith(
      "TableController: Error in horizontal scrolling",
      expect.objectContaining({ error: "left failed" }),
    );
  });
});
