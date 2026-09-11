import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import ClipboardController from "../../../app/javascript/controllers/clipboard_controller.js";

describe("clipboard tooltip control", () => {
  let application, root, writeText, tooltip;
  const target = (name) =>
    root.querySelector(`[data-clipboard-target="${name}"]`);
  beforeEach(() => {
    vi.useFakeTimers();
    writeText = vi.fn().mockResolvedValue(undefined);
    vi.stubGlobal("navigator", { clipboard: { writeText } });
    tooltip = { show: vi.fn(), hide: vi.fn(), destroy: vi.fn() };
    vi.stubGlobal(
      "Tooltip",
      vi.fn(
        class {
          constructor() {
            return tooltip;
          }
        },
      ),
    );
  });
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount({ button = true, content = true } = {}) {
    document.body.innerHTML = `<div data-controller="clipboard" data-clipboard-copied-value="Copied">
      ${button ? '<button value="secret" data-clipboard-target="button" data-action="clipboard#copy"><span>Copy</span></button>' : ""}
      ${content ? '<div data-clipboard-target="content">Copied</div>' : ""}
      <div aria-live="polite" data-clipboard-target="ariaLive"></div>
    </div>`;
    root = document.body.firstElementChild;
    application = startApplication();
    application.register("clipboard", ClipboardController);
    await Promise.resolve();
  }
  it("copies the button value when a descendant is clicked and restores feedback", async () => {
    await mount();
    const button = target("button");
    const original = button.innerHTML;
    const bubbled = vi.fn();
    root.addEventListener("click", bubbled);
    button.querySelector("span").click();
    await Promise.resolve();
    expect(writeText).toHaveBeenCalledWith("secret");
    expect(bubbled).not.toHaveBeenCalled();
    expect(tooltip.show).toHaveBeenCalledOnce();
    expect(button).toBeDisabled();
    expect(target("ariaLive").innerText).toBe("Copied");
    vi.advanceTimersByTime(1000);
    expect(tooltip.hide).toHaveBeenCalledOnce();
    expect(button).toBeEnabled();
    expect(button.innerHTML).toBe(original);
    expect(target("ariaLive").innerText).toBe("");
  });
  it("destroys its tooltip and clears feedback when removed", async () => {
    await mount();
    target("button").click();
    await Promise.resolve();
    root.remove();
    await Promise.resolve();
    await Promise.resolve();
    expect(tooltip.destroy).toHaveBeenCalledOnce();
    expect(vi.getTimerCount()).toBe(0);
    expect(target("button")).toBeEnabled();
    expect(target("ariaLive").innerText).toBe("");
  });
  it("does not report a stale write after reconnect", async () => {
    let resolve;
    writeText.mockReturnValue(
      new Promise((done) => {
        resolve = done;
      }),
    );
    await mount();
    target("button").click();
    root.remove();
    await Promise.resolve();
    await Promise.resolve();
    document.body.append(root);
    await Promise.resolve();
    resolve();
    await Promise.resolve();
    expect(tooltip.show).not.toHaveBeenCalled();
    expect(target("button")).toBeEnabled();
  });
  it("cleans up when the tooltip target is replaced", async () => {
    await mount();
    target("content").remove();
    await Promise.resolve();
    await Promise.resolve();
    expect(tooltip.destroy).toHaveBeenCalledOnce();
    root.insertAdjacentHTML(
      "beforeend",
      '<div data-clipboard-target="content">Copied again</div>',
    );
    await Promise.resolve();
    expect(Tooltip).toHaveBeenCalledTimes(2);
  });
  it("does not construct a tooltip without its button", async () => {
    await mount({ button: false });
    expect(Tooltip).not.toHaveBeenCalled();
  });
  it("copies without tooltip feedback when no content target exists", async () => {
    await mount({ content: false });
    target("button").click();
    await Promise.resolve();
    expect(writeText).toHaveBeenCalledWith("secret");
    expect(tooltip.show).not.toHaveBeenCalled();
  });
  it("logs unavailable clipboard support", async () => {
    vi.stubGlobal("navigator", {});
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    await mount();
    target("button").click();
    expect(log).toHaveBeenCalledWith("Clipboard API not available");
    expect(tooltip.show).not.toHaveBeenCalled();
  });
  it("logs rejected writes without success feedback", async () => {
    const error = new Error("Denied");
    writeText.mockRejectedValue(error);
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    await mount();
    target("button").click();
    await Promise.resolve();
    expect(log).toHaveBeenCalledWith("Failed to copy text: ", error);
    expect(tooltip.show).not.toHaveBeenCalled();
  });
});
