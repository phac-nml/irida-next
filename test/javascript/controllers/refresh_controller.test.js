import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import RefreshController from "../../../app/javascript/controllers/refresh_controller.js";

describe("refresh controller", () => {
  let application, element, source, notice, controller;
  beforeEach(() => vi.useFakeTimers());
  afterEach(async () => {
    await stopApplication(application);
  });

  async function mount({ withNotice = true } = {}) {
    document.body.innerHTML = `<div data-controller="refresh">
      <div data-refresh-target="source"></div>
      ${withNotice ? '<div class="hidden" data-refresh-target="notice"></div>' : ""}
      <button data-action="refresh#dismiss">Dismiss</button>
    </div>`;
    element = document.body.firstElementChild;
    source = element.querySelector('[data-refresh-target="source"]');
    notice = element.querySelector('[data-refresh-target="notice"]');
    application = startApplication();
    application.register("refresh", RefreshController);
    await Promise.resolve();
    controller = application.getControllerForElementAndIdentifier(
      element,
      "refresh",
    );
  }

  function broadcast(data = '<turbo-stream action="refresh"></turbo-stream>') {
    const downstream = vi.fn();
    source.addEventListener("message", downstream, { once: true });
    source.dispatchEvent(new MessageEvent("message", { data }));
    source.removeEventListener("message", downstream);
    return downstream;
  }

  it.each([
    null,
    {},
    "",
    '<turbo-stream action="replace"></turbo-stream>',
    'other action="refresh"',
  ])("passes unrelated messages through: %j", async (data) => {
    await mount();
    expect(broadcast(data)).toHaveBeenCalledOnce();
    expect(notice.classList.contains("hidden")).toBe(true);
  });

  it("allows Turbo to refresh when no notice exists", async () => {
    await mount({ withNotice: false });
    expect(broadcast()).toHaveBeenCalledOnce();
  });

  it("shows one notice per burst and allows another after the debounce", async () => {
    await mount();
    expect(broadcast()).not.toHaveBeenCalled();
    expect(notice.classList.contains("hidden")).toBe(false);
    element.querySelector("button").click();
    expect(notice.classList.contains("hidden")).toBe(true);
    expect(broadcast()).not.toHaveBeenCalled();
    expect(notice.classList.contains("hidden")).toBe(true);
    await vi.advanceTimersByTimeAsync(300);
    broadcast();
    expect(notice.classList.contains("hidden")).toBe(false);
  });

  it("suppresses exactly the next refresh following a local edit", async () => {
    await mount();
    controller.ignoreNextRefresh();
    expect(broadcast()).not.toHaveBeenCalled();
    expect(notice.classList.contains("hidden")).toBe(true);
    expect(vi.getTimerCount()).toBe(0);
    broadcast();
    expect(notice.classList.contains("hidden")).toBe(false);
  });

  it("extends the suppression deadline on another local edit", async () => {
    await mount();
    controller.ignoreNextRefresh();
    await vi.advanceTimersByTimeAsync(4000);
    controller.ignoreNextRefresh();
    await vi.advanceTimersByTimeAsync(4000);
    expect(vi.getTimerCount()).toBe(1);
    expect(notice.classList.contains("hidden")).toBe(true);
    await vi.advanceTimersByTimeAsync(1000);
    broadcast();
    expect(notice.classList.contains("hidden")).toBe(false);
  });

  it("removes listeners and clears pending suppression when its source reconnects", async () => {
    await mount();
    controller.ignoreNextRefresh();
    source.remove();
    await Promise.resolve();
    expect(vi.getTimerCount()).toBe(0);
    expect(broadcast()).toHaveBeenCalledOnce();
    element.append(source);
    await Promise.resolve();
    broadcast();
    expect(notice.classList.contains("hidden")).toBe(false);
  });

  it("clears a pending debounce when its source disconnects", async () => {
    await mount();
    broadcast();
    source.remove();
    await Promise.resolve();
    expect(vi.getTimerCount()).toBe(0);
    controller.dismiss();
    element.append(source);
    await Promise.resolve();
    broadcast();
    expect(notice.classList.contains("hidden")).toBe(false);
  });

  it("reloads on an explicit refresh request", async () => {
    await mount();
    const reload = vi.fn();
    vi.stubGlobal("window", { location: { reload } });
    try {
      controller.refresh();
    } finally {
      vi.unstubAllGlobals();
    }
    expect(reload).toHaveBeenCalledOnce();
  });
});
