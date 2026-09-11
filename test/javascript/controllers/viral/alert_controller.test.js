import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";
import AlertController from "../../../../app/javascript/controllers/viral/alert_controller.js";
import { announce, createLiveRegion } from "utilities/live_region";
vi.mock("utilities/live_region", () => ({
  announce: vi.fn(),
  createLiveRegion: vi.fn(),
}));

describe("alert controller", () => {
  let application, element, region;
  beforeEach(() => {
    vi.useFakeTimers();
    createLiveRegion.mockImplementation(() => {
      region = document.createElement("div");
      document.body.append(region);
      return region;
    });
  });
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount({
    dismissible = true,
    autoDismiss = false,
    announceAlert = true,
    type = "info",
    progress = true,
  } = {}) {
    document.body.innerHTML = `<div data-controller="viral--alert" data-viral--alert-dismissible-value="${dismissible}"
      data-viral--alert-auto-dismiss-value="${autoDismiss}" data-viral--alert-announce-alert-value="${announceAlert}"
      data-viral--alert-type-value="${type}" data-viral--alert-auto-dismiss-duration-value="1000"
      data-viral--alert-alert-id-value="notice" data-viral--alert-dismissed-text-value="Alert dismissed">
      <button data-action="viral--alert#dismiss">Close</button><a href="#help">Help</a>
      ${progress ? '<div data-viral--alert-target="progressBar" style="width: 100%"></div>' : ""}
    </div>`;
    element = document.body.firstElementChild;
    application = startApplication();
    application.register("viral--alert", AlertController);
    await Promise.resolve();
  }
  function key(key, target = element) {
    const event = new KeyboardEvent("keydown", {
      key,
      bubbles: true,
      cancelable: true,
    });
    target.dispatchEvent(event);
    return event;
  }
  function interact(type) {
    element.dispatchEvent(new Event(type));
  }
  it("sets assertive announcements and focusability for dismissible alerts", async () => {
    await mount();
    expect(element.getAttribute("aria-live")).toBe("assertive");
    expect(element.getAttribute("aria-atomic")).toBe("true");
    expect(element.tabIndex).toBe(-1);
    expect(element.hasAttribute("tabindex")).toBe(true);
  });
  it("does not make a persistent alert keyboard-dismissible", async () => {
    await mount({ dismissible: false });
    expect(element.hasAttribute("tabindex")).toBe(false);
    expect(key("Escape").defaultPrevented).toBe(false);
    expect(element.isConnected).toBe(true);
  });
  it("respects disabled initial announcements", async () => {
    await mount({ announceAlert: false });
    expect(element.hasAttribute("aria-live")).toBe(false);
  });
  it.each(["Escape", "Enter", " "])(
    "dismisses with %j and announces the result temporarily",
    async (value) => {
      await mount();
      expect(key(value).defaultPrevented).toBe(true);
      expect(element.isConnected).toBe(false);
      expect(createLiveRegion).toHaveBeenCalledWith({
        id: "alert-announcement-notice",
        politeness: "polite",
        atomic: true,
      });
      expect(announce).toHaveBeenCalledWith("Alert dismissed", {
        element: region,
      });
      expect(region.isConnected).toBe(true);
      await vi.advanceTimersByTimeAsync(3000);
      expect(region.isConnected).toBe(false);
    },
  );
  it.each(["Enter", " ", "ArrowDown"])(
    "leaves child controls and unrelated keys alone: %j",
    async (value) => {
      await mount();
      expect(key(value, element.querySelector("a")).defaultPrevented).toBe(
        false,
      );
      expect(element.isConnected).toBe(true);
    },
  );
  it("dismisses through the close-button action", async () => {
    await mount();
    element.querySelector("button").click();
    expect(element.isConnected).toBe(false);
  });
  it("updates progress and dismisses when the countdown ends", async () => {
    await mount({ autoDismiss: true });
    await vi.advanceTimersByTimeAsync(500);
    expect(
      element.querySelector('[data-viral--alert-target="progressBar"]').style
        .width,
    ).toBe("50%");
    await vi.advanceTimersByTimeAsync(500);
    expect(element.isConnected).toBe(false);
    await vi.advanceTimersByTimeAsync(3000);
    expect(vi.getTimerCount()).toBe(0);
  });
  it("auto-dismisses without an optional progress bar", async () => {
    await mount({ autoDismiss: true, progress: false });
    await vi.advanceTimersByTimeAsync(1000);
    expect(element.isConnected).toBe(false);
  });
  it("never auto-dismisses danger alerts", async () => {
    await mount({ autoDismiss: true, type: "danger" });
    await vi.advanceTimersByTimeAsync(5000);
    expect(element.isConnected).toBe(true);
    expect(vi.getTimerCount()).toBe(0);
  });
  it.each([
    ["mouseenter", "mouseleave"],
    ["focusin", "focusout"],
  ])("pauses on %s and restarts the countdown on %s", async (pause, resume) => {
    await mount({ autoDismiss: true });
    await vi.advanceTimersByTimeAsync(400);
    interact(pause);
    await vi.advanceTimersByTimeAsync(2000);
    expect(element.isConnected).toBe(true);
    interact(resume);
    await vi.advanceTimersByTimeAsync(999);
    expect(element.isConnected).toBe(true);
    await vi.advanceTimersByTimeAsync(1);
    expect(element.isConnected).toBe(false);
  });
  it("does not leave duplicate countdowns when multiple resume events arrive", async () => {
    await mount({ autoDismiss: true });
    interact("mouseenter");
    interact("focusin");
    interact("mouseleave");
    interact("focusout");
    expect(vi.getTimerCount()).toBe(1);
    await vi.advanceTimersByTimeAsync(4000);
    expect(createLiveRegion).toHaveBeenCalledOnce();
    expect(vi.getTimerCount()).toBe(0);
  });
  it("keeps one timer if a resume event repeats", async () => {
    await mount({ autoDismiss: true });
    interact("mouseleave");
    interact("mouseleave");
    expect(vi.getTimerCount()).toBe(1);
    element.remove();
    await Promise.resolve();
    expect(vi.getTimerCount()).toBe(0);
  });
  it("stays paused until both hover and focus leave the alert", async () => {
    await mount({ autoDismiss: true });
    interact("mouseenter");
    interact("focusin");
    interact("mouseleave");
    expect(vi.getTimerCount()).toBe(0);
    await vi.advanceTimersByTimeAsync(2000);
    expect(element.isConnected).toBe(true);
    interact("focusout");
    expect(vi.getTimerCount()).toBe(1);
  });
  it("does not restart while focus moves between controls inside the alert", async () => {
    await mount({ autoDismiss: true });
    interact("focusin");
    element.querySelector("button").dispatchEvent(
      new FocusEvent("focusout", {
        bubbles: true,
        relatedTarget: element.querySelector("a"),
      }),
    );
    expect(vi.getTimerCount()).toBe(0);
  });
  it.each([
    ["auto-dismiss", "false"],
    ["type", "danger"],
  ])("does not resume after %s changes to %s", async (name, value) => {
    await mount({ autoDismiss: true });
    interact("mouseenter");
    element.setAttribute(`data-viral--alert-${name}-value`, value);
    interact("mouseleave");
    expect(vi.getTimerCount()).toBe(0);
  });
  it("clears timers and listeners on removal, then reconnects once", async () => {
    await mount({ autoDismiss: true });
    element.remove();
    await Promise.resolve();
    expect(vi.getTimerCount()).toBe(0);
    interact("mouseleave");
    key("Escape");
    expect(createLiveRegion).not.toHaveBeenCalled();
    expect(vi.getTimerCount()).toBe(0);
    document.body.append(element);
    await Promise.resolve();
    expect(vi.getTimerCount()).toBe(1);
    element.querySelector("button").click();
    expect(createLiveRegion).toHaveBeenCalledOnce();
  });
  it("still dismisses if the announcement service fails", async () => {
    await mount();
    const error = new Error("Announcement unavailable");
    createLiveRegion.mockImplementationOnce(() => {
      throw error;
    });
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    element.querySelector("button").click();
    expect(element.isConnected).toBe(false);
    expect(log).toHaveBeenCalledWith("❌ Failed to announce dismissal:", error);
  });
});
