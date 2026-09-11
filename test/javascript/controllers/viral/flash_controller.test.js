import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";
import FlashController from "../../../../app/javascript/controllers/viral/flash_controller.js";

describe("flash controller", () => {
  let application, element;
  beforeEach(() => vi.useFakeTimers());
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount({ type = "success", timeout = 1000 } = {}) {
    document.body.innerHTML = `<div data-controller="viral--flash" data-viral--flash-type-value="${type}" data-viral--flash-timeout-value="${timeout}" style="opacity: 0">
      Saved <button data-action="viral--flash#dismiss">Close</button></div>`;
    element = document.body.firstElementChild;
    application = startApplication();
    application.register("viral--flash", FlashController);
    await Promise.resolve();
  }
  it("animates in and removes the message after the exit animation", async () => {
    await mount();
    await vi.advanceTimersByTimeAsync(20);
    expect(element.style.opacity).toBe("1");
    expect(element.style.transform).toBe("translateY(0) scale(1)");
    await vi.advanceTimersByTimeAsync(980);
    expect(element.isConnected).toBe(true);
    expect(element.style.opacity).toBe("0");
    expect(element.style.transform).toBe("translateX(100%)");
    await vi.advanceTimersByTimeAsync(300);
    expect(element.isConnected).toBe(false);
    expect(vi.getTimerCount()).toBe(0);
  });
  it.each([{ type: "error" }, { timeout: 0 }, { timeout: -1 }])(
    "keeps persistent messages until manually dismissed: %j",
    async (options) => {
      await mount(options);
      await vi.advanceTimersByTimeAsync(10000);
      expect(element.isConnected).toBe(true);
      element.dispatchEvent(new MouseEvent("mouseenter"));
      element.dispatchEvent(new MouseEvent("mouseleave"));
      expect(vi.getTimerCount()).toBe(0);
      element.querySelector("button").click();
      await vi.advanceTimersByTimeAsync(300);
      expect(element.isConnected).toBe(false);
    },
  );
  it("pauses on hover and resumes with the remaining time", async () => {
    await mount();
    await vi.advanceTimersByTimeAsync(400);
    element.dispatchEvent(new MouseEvent("mouseenter"));
    await vi.advanceTimersByTimeAsync(5000);
    expect(element.style.opacity).toBe("1");
    element.dispatchEvent(new MouseEvent("mouseleave"));
    await vi.advanceTimersByTimeAsync(599);
    expect(element.style.opacity).toBe("1");
    await vi.advanceTimersByTimeAsync(1);
    expect(element.style.opacity).toBe("0");
  });
  it("cancels the entrance frame, timer, and listeners on removal", async () => {
    await mount();
    element.remove();
    await Promise.resolve();
    expect(vi.getTimerCount()).toBe(0);
    element.dispatchEvent(new MouseEvent("mouseleave"));
    expect(vi.getTimerCount()).toBe(0);
    await vi.advanceTimersByTimeAsync(2000);
    expect(element.style.opacity).toBe("0");
  });
  it("cancels exit removal so a reconnected message survives stale work", async () => {
    await mount();
    element.querySelector("button").click();
    element.remove();
    await Promise.resolve();
    expect(vi.getTimerCount()).toBe(0);
    document.body.append(element);
    await Promise.resolve();
    await vi.advanceTimersByTimeAsync(300);
    expect(element.isConnected).toBe(true);
    expect(element.style.opacity).toBe("1");
  });
  it("does not schedule dismissal if its timeout is disabled while paused", async () => {
    await mount();
    element.dispatchEvent(new MouseEvent("mouseenter"));
    element.setAttribute("data-viral--flash-timeout-value", "0");
    element.dispatchEvent(new MouseEvent("mouseenter"));
    element.dispatchEvent(new MouseEvent("mouseleave"));
    await vi.advanceTimersByTimeAsync(2000);
    expect(element.isConnected).toBe(true);
  });
});
