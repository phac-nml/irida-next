import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import CopyController from "../../../app/javascript/controllers/copy_controller.js";

describe("copy controller", () => {
  let application;
  let writeText;
  let root;
  let controller;
  const target = (name) => root.querySelector(`[data-copy-target="${name}"]`);
  beforeEach(() => {
    vi.useFakeTimers();
    writeText = vi.fn().mockResolvedValue(undefined);
    vi.stubGlobal("navigator", { clipboard: { writeText } });
  });
  async function mount({
    omit = "",
    text = "  contents\n",
    duration = "",
  } = {}) {
    document.body.innerHTML = `<div data-controller="copy" ${duration}>
      ${omit !== "source" ? `<pre data-copy-target="source">${text}</pre>` : ""}
      <button data-action="copy#copy">${omit !== "buttonLabel" ? '<span data-copy-target="buttonLabel">Copy</span>' : ""}
      ${omit !== "successIcon" ? '<span data-copy-target="successIcon" class="hidden">Done</span>' : ""}</button>
    </div>`;
    root = document.body.firstElementChild;
    application = startApplication();
    application.register("copy", CopyController);
    await Promise.resolve();
    controller = application.getControllerForElementAndIdentifier(root, "copy");
  }
  afterEach(async () => {
    await stopApplication(application);
  });

  it("copies trimmed text through its action and restores feedback after the default delay", async () => {
    await mount();
    root.querySelector("button").click();
    await Promise.resolve();
    expect(writeText).toHaveBeenCalledWith("contents");
    expect(target("successIcon")).not.toHaveClass("hidden");
    expect(target("buttonLabel")).toHaveClass("sr-only");
    vi.advanceTimersByTime(1999);
    expect(target("successIcon")).not.toHaveClass("hidden");
    vi.advanceTimersByTime(1);
    expect(target("successIcon")).toHaveClass("hidden");
    expect(target("buttonLabel")).not.toHaveClass("sr-only");
  });
  it("restarts feedback for repeated copies", async () => {
    await mount({ duration: 'data-copy-feedback-duration-value="100"' });
    await controller.copy();
    vi.advanceTimersByTime(60);
    await controller.copy();
    vi.advanceTimersByTime(40);
    expect(target("successIcon")).not.toHaveClass("hidden");
    vi.advanceTimersByTime(60);
    expect(target("successIcon")).toHaveClass("hidden");
  });
  it("cancels feedback and restores the reusable element on disconnect", async () => {
    await mount();
    await controller.copy();
    root.remove();
    await Promise.resolve();
    await Promise.resolve();
    expect(vi.getTimerCount()).toBe(0);
    expect(target("successIcon")).toHaveClass("hidden");
    expect(target("buttonLabel")).not.toHaveClass("sr-only");
  });
  it("ignores a copy that resolves after disconnect and reconnection", async () => {
    let resolve;
    writeText.mockReturnValue(
      new Promise((done) => {
        resolve = done;
      }),
    );
    await mount();
    const copying = controller.copy();
    root.remove();
    await Promise.resolve();
    await Promise.resolve();
    document.body.append(root);
    await Promise.resolve();
    resolve();
    await copying;
    expect(target("successIcon")).toHaveClass("hidden");
  });
  it("logs a rejected clipboard write without showing success", async () => {
    const error = new Error("Denied");
    writeText.mockRejectedValue(error);
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    await mount();
    await controller.copy();
    expect(log).toHaveBeenCalledWith("❌ Failed to copy text:", error);
    expect(target("successIcon")).toHaveClass("hidden");
  });
  it("handles an unavailable clipboard", async () => {
    vi.stubGlobal("navigator", {});
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    await mount();
    await controller.copy();
    expect(log).toHaveBeenCalledWith("❌ Clipboard API not available");
  });
  it("does not copy whitespace", async () => {
    const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
    await mount({ text: " \n " });
    await controller.copy();
    expect(writeText).not.toHaveBeenCalled();
    expect(warn).toHaveBeenCalledWith("⚠️ No content available to copy");
  });
  it.each(["source", "buttonLabel", "successIcon"])(
    "diagnoses a missing %s target",
    async (omit) => {
      const warn = vi.spyOn(console, "warn").mockImplementation(() => {});
      const log = vi.spyOn(console, "error").mockImplementation(() => {});
      await mount({ omit });
      expect(warn).toHaveBeenCalledWith(
        `⚠️ Copy controller missing ${omit} target`,
      );
      if (omit === "source") {
        await controller.copy();
        expect(writeText).not.toHaveBeenCalled();
        expect(log).toHaveBeenCalledWith("❌ Source target is missing");
      }
    },
  );
});
