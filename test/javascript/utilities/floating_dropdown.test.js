import { beforeEach, describe, expect, it, vi } from "vitest";
import { autoUpdate, computePosition, size } from "@floating-ui/dom";

vi.mock("@floating-ui/dom", () => ({
  autoUpdate: vi.fn(() => vi.fn()),
  computePosition: vi.fn(() => Promise.resolve({ x: 14, y: 18 })),
  flip: vi.fn(() => "flip"),
  offset: vi.fn(() => "offset"),
  shift: vi.fn(() => "shift"),
  size: vi.fn(() => "size"),
}));

import FloatingDropdown from "../../../app/javascript/utilities/floating_dropdown.js";

function buildDropdown({
  triggerType = "click",
  manageAria = true,
  autoSize = true,
  onShow,
  onHide,
  distance = 8,
} = {}) {
  const trigger = document.createElement("button");
  const dropdown = document.createElement("div");
  dropdown.setAttribute("aria-hidden", "true");
  dropdown.setAttribute("hidden", "");

  document.body.append(trigger, dropdown);

  const instance = new FloatingDropdown({
    trigger,
    triggerType,
    dropdown,
    distance,
    manageAria,
    autoSize,
    onShow,
    onHide,
  });

  return { trigger, dropdown, instance };
}

describe("floating_dropdown", () => {
  beforeEach(() => {
    document.body.innerHTML = "";
    vi.clearAllMocks();
  });

  it("starts hidden and toggles via the trigger click event", () => {
    const { trigger, dropdown, instance } = buildDropdown();

    expect(instance.isVisible()).toBe(false);
    expect(trigger.getAttribute("aria-expanded")).toBeNull();

    trigger.click();

    expect(instance.isVisible()).toBe(true);
    expect(trigger.getAttribute("aria-expanded")).toBe("true");
    expect(dropdown.getAttribute("aria-hidden")).toBeNull();
    expect(dropdown.hidden).toBe(false);

    trigger.click();

    expect(instance.isVisible()).toBe(false);
    expect(trigger.getAttribute("aria-expanded")).toBe("false");
    expect(dropdown.getAttribute("aria-hidden")).toBe("true");
    expect(dropdown.hidden).toBe(true);
  });

  it("shows and hides with callbacks and cleanup", () => {
    const onShow = vi.fn();
    const onHide = vi.fn();
    const cleanup = vi.fn();
    autoUpdate.mockReturnValue(cleanup);
    const { instance } = buildDropdown({ onShow, onHide });

    instance.show();

    expect(instance.isVisible()).toBe(true);
    expect(onShow).toHaveBeenCalledTimes(1);
    expect(autoUpdate).toHaveBeenCalledWith(
      expect.any(HTMLElement),
      expect.any(HTMLElement),
      expect.any(Function),
    );

    instance.hide();

    expect(instance.isVisible()).toBe(false);
    expect(onHide).toHaveBeenCalledTimes(1);
    expect(cleanup).toHaveBeenCalledTimes(1);
  });

  it("hides when a click occurs outside the trigger and dropdown", () => {
    const { trigger, dropdown, instance } = buildDropdown();
    const outside = document.createElement("button");
    document.body.append(outside);

    instance.show();
    outside.click();

    expect(instance.isVisible()).toBe(false);
    expect(dropdown.hidden).toBe(true);
    expect(trigger.getAttribute("aria-expanded")).toBe("false");
  });

  it("stays open when clicking the dropdown or its descendants", () => {
    const { dropdown, instance } = buildDropdown();
    const child = document.createElement("button");
    dropdown.appendChild(child);

    instance.show();
    dropdown.click();
    expect(instance.isVisible()).toBe(true);
    child.click();
    expect(instance.isVisible()).toBe(true);

    instance.destroy();
  });

  it("updates the floating position with the computed coordinates", async () => {
    const { dropdown, trigger, instance } = buildDropdown({ autoSize: true });
    const sizeMock = vi.mocked(size);
    sizeMock.mockImplementation(({ apply }) => {
      apply({
        availableWidth: 40,
        availableHeight: 50,
        rects: { reference: { width: 30 } },
        elements: { floating: dropdown },
      });
      return "size";
    });

    await instance.update();

    expect(computePosition).toHaveBeenCalledWith(trigger, dropdown, {
      strategy: "absolute",
      placement: "bottom",
      middleware: ["flip", "offset", "shift", "size"],
    });
    expect(dropdown.style.position).toBe("absolute");
    expect(dropdown.style.left).toBe("14px");
    expect(dropdown.style.top).toBe("18px");
    expect(dropdown.style.maxWidth).toBe("40px");
    expect(dropdown.style.maxHeight).toBe("50px");
    expect(dropdown.style.minWidth).toBe("30px");
  });

  it("falls back to the trigger rectangle when computePosition fails", async () => {
    computePosition.mockRejectedValueOnce(new Error("boom"));
    const { dropdown, trigger, instance } = buildDropdown({ autoSize: false });
    trigger.getBoundingClientRect = () => ({ left: 25, bottom: 40 });

    instance.update();
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(dropdown.style.position).toBe("absolute");
    expect(dropdown.style.left).toBe("25px");
    expect(dropdown.style.top).toBe("40px");
  });

  it("skips auto sizing when disabled", async () => {
    const { dropdown, trigger, instance } = buildDropdown({ autoSize: false });

    await instance.update();

    expect(computePosition).toHaveBeenCalledWith(trigger, dropdown, {
      strategy: "absolute",
      placement: "bottom",
      middleware: ["flip", "offset", "shift"],
    });
    expect(dropdown.style.left).toBe("14px");
  });

  it("removes listeners and clears references on destroy", () => {
    const { trigger, dropdown, instance } = buildDropdown();

    instance.show();
    instance.destroy();
    trigger.click();

    expect(instance.isVisible()).toBe(false);
    expect(dropdown.hidden).toBe(true);
  });

  it("leaves aria management disabled when configured off", () => {
    const { trigger, dropdown, instance } = buildDropdown({
      manageAria: false,
    });

    instance.show();
    expect(trigger.getAttribute("aria-expanded")).toBeNull();
    expect(dropdown.getAttribute("aria-hidden")).toBe("true");
    expect(dropdown.hasAttribute("hidden")).toBe(true);

    instance.hide();
    expect(trigger.getAttribute("aria-expanded")).toBeNull();
    expect(dropdown.getAttribute("aria-hidden")).toBe("true");
    expect(dropdown.hasAttribute("hidden")).toBe(true);
  });

  it("ignores trigger types that do not attach click listeners", () => {
    const { trigger, instance } = buildDropdown({ triggerType: "none" });

    trigger.click();
    instance.destroy();

    expect(instance.isVisible()).toBe(false);
  });
});
