import { describe, it, expect, vi } from "vitest";
import {
  isVisible,
  focusWhenVisible,
} from "../../../app/javascript/utilities/focus.js";

function buildElement({
  connected = true,
  hasOffsetParent = true,
  rectCount = 1,
  style = {},
} = {}) {
  const element = document.createElement("button");

  if (connected) {
    document.body.appendChild(element);
  }

  Object.defineProperty(element, "offsetParent", {
    configurable: true,
    get: () => (hasOffsetParent ? document.body : null),
  });

  element.getClientRects = () =>
    Array.from({ length: rectCount }, () => ({ width: 10, height: 10 }));

  Object.assign(element.style, style);

  return element;
}

describe("focus", () => {
  describe("isVisible", () => {
    it("returns false when element is not connected", () => {
      const element = buildElement({ connected: false });

      expect(isVisible(element)).toBe(false);
    });

    it("returns false when element has no offset parent", () => {
      const element = buildElement({ hasOffsetParent: false });

      expect(isVisible(element)).toBe(false);
    });

    it("returns false when display is none", () => {
      const element = buildElement({ style: { display: "none" } });

      expect(isVisible(element)).toBe(false);
    });

    it("returns false when visibility is hidden", () => {
      const element = buildElement({ style: { visibility: "hidden" } });

      expect(isVisible(element)).toBe(false);
    });

    it("returns false when opacity is 0", () => {
      const element = buildElement({ style: { opacity: "0" } });

      expect(isVisible(element)).toBe(false);
    });

    it("returns false when there are no client rects", () => {
      const element = buildElement({ rectCount: 0 });

      expect(isVisible(element)).toBe(false);
    });

    it("returns true for a connected rendered element", () => {
      const element = buildElement();

      expect(isVisible(element)).toBe(true);
    });
  });

  describe("focusWhenVisible", () => {
    it("returns early when element is missing", () => {
      const rafSpy = vi.spyOn(window, "requestAnimationFrame");

      focusWhenVisible(null);

      expect(rafSpy).not.toHaveBeenCalled();
    });

    it("focuses immediately when element is already visible", () => {
      const element = buildElement();
      const focusSpy = vi.spyOn(element, "focus");
      vi.spyOn(window, "requestAnimationFrame").mockImplementation((cb) => {
        cb();
        return 1;
      });

      focusWhenVisible(element, { focusOptions: { preventScroll: true } });

      expect(focusSpy).toHaveBeenCalledWith({ preventScroll: true });
    });

    it("keeps checking frames until the element becomes visible", () => {
      const element = document.createElement("button");
      document.body.appendChild(element);

      let isNowVisible = false;
      Object.defineProperty(element, "offsetParent", {
        configurable: true,
        get: () => (isNowVisible ? document.body : null),
      });
      element.getClientRects = () => (isNowVisible ? [{ width: 10 }] : []);

      const focusSpy = vi.spyOn(element, "focus");
      let frame = 0;
      vi.spyOn(window, "requestAnimationFrame").mockImplementation((cb) => {
        frame += 1;
        if (frame === 2) {
          isNowVisible = true;
        }
        cb();
        return frame;
      });

      focusWhenVisible(element, { maxFrames: 5 });

      expect(frame).toBe(2);
      expect(focusSpy).toHaveBeenCalledTimes(1);
    });

    it("stops retrying after maxFrames when element stays hidden", () => {
      const element = buildElement({ hasOffsetParent: false });
      const focusSpy = vi.spyOn(element, "focus");
      let frame = 0;
      vi.spyOn(window, "requestAnimationFrame").mockImplementation((cb) => {
        frame += 1;
        cb();
        return frame;
      });

      focusWhenVisible(element, { maxFrames: 3 });

      expect(frame).toBe(3);
      expect(focusSpy).not.toHaveBeenCalled();
    });
  });
});
