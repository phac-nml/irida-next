import { describe, it, expect, beforeEach, vi } from "vitest";
import {
  announce,
  findOrCreateGlobalRegion,
  createLiveRegion,
  clearLiveRegion,
  GLOBAL_LIVE_REGION_ID,
} from "../../../app/javascript/utilities/live_region.js";

describe("live_region", () => {
  describe("announce", () => {
    beforeEach(() => {
      vi.spyOn(window, "requestAnimationFrame").mockImplementation((cb) =>
        cb(),
      );
    });

    it("creates a global live region and sets textContent", () => {
      announce("hello");
      const region = document.getElementById(GLOBAL_LIVE_REGION_ID);
      expect(region).toBeInTheDocument();
      expect(region.textContent).toBe("hello");
    });

    it("uses the provided element instead of creating a global region", () => {
      const el = document.createElement("div");
      document.body.appendChild(el);
      announce("hello", { element: el });
      expect(el.textContent).toBe("hello");
      expect(document.getElementById(GLOBAL_LIVE_REGION_ID)).toBeNull();
    });

    it("is a no-op when message is empty string", () => {
      announce("");
      expect(document.getElementById(GLOBAL_LIVE_REGION_ID)).toBeNull();
    });

    it("is a no-op when message is null", () => {
      announce(null);
      expect(document.getElementById(GLOBAL_LIVE_REGION_ID)).toBeNull();
    });
  });

  describe("findOrCreateGlobalRegion", () => {
    it("creates a new region when none exists", () => {
      const region = findOrCreateGlobalRegion();
      expect(region).toBeInTheDocument();
      expect(region.id).toBe(GLOBAL_LIVE_REGION_ID);
      expect(region.getAttribute("role")).toBe("status");
      expect(region.getAttribute("aria-live")).toBe("polite");
    });

    it("creates region with assertive politeness when specified", () => {
      const region = findOrCreateGlobalRegion("assertive");
      expect(region.getAttribute("aria-live")).toBe("assertive");
    });

    it("returns existing region without overwriting attributes", () => {
      const existing = document.createElement("span");
      existing.id = GLOBAL_LIVE_REGION_ID;
      existing.setAttribute("role", "alert");
      existing.setAttribute("aria-live", "assertive");
      document.body.appendChild(existing);

      const region = findOrCreateGlobalRegion("polite");
      expect(region).toBe(existing);
      expect(region.getAttribute("role")).toBe("alert");
      expect(region.getAttribute("aria-live")).toBe("assertive");
    });

    it("sets role on existing region that lacks one", () => {
      const existing = document.createElement("span");
      existing.id = GLOBAL_LIVE_REGION_ID;
      document.body.appendChild(existing);

      const region = findOrCreateGlobalRegion();
      expect(region.getAttribute("role")).toBe("status");
    });
  });

  describe("createLiveRegion", () => {
    it("creates a span with default attributes", () => {
      const region = createLiveRegion();
      expect(region.tagName).toBe("SPAN");
      expect(region.id).toBe(GLOBAL_LIVE_REGION_ID);
      expect(region.getAttribute("role")).toBe("status");
      expect(region.getAttribute("aria-live")).toBe("polite");
      expect(region.className).toBe("sr-only");
      expect(region).toBeInTheDocument();
    });

    it("creates region with custom id, politeness, and atomic", () => {
      const region = createLiveRegion({
        id: "custom",
        politeness: "assertive",
        atomic: true,
      });
      expect(region.id).toBe("custom");
      expect(region.getAttribute("aria-live")).toBe("assertive");
      expect(region.getAttribute("aria-atomic")).toBe("true");
    });

    it("returns existing element when same id already exists", () => {
      const first = createLiveRegion({ id: "unique-id" });
      const second = createLiveRegion({ id: "unique-id" });
      expect(first).toBe(second);
      expect(document.querySelectorAll("#unique-id").length).toBe(1);
    });
  });

  describe("clearLiveRegion", () => {
    it("clears textContent of provided element", () => {
      const el = document.createElement("div");
      el.textContent = "some text";
      document.body.appendChild(el);
      clearLiveRegion(el);
      expect(el.textContent).toBe("");
    });

    it("clears #sr-status when no argument provided", () => {
      const region = createLiveRegion();
      region.textContent = "some announcement";
      clearLiveRegion();
      expect(region.textContent).toBe("");
    });

    it("is a no-op when no #sr-status exists and no argument given", () => {
      expect(() => clearLiveRegion()).not.toThrow();
    });
  });
});
