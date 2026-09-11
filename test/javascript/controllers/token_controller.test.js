import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import TokenController from "../../../app/javascript/controllers/token_controller.js";

describe("token controls", () => {
  let application, root, controller, writeText;
  const target = (name) => root.querySelector(`[data-token-target="${name}"]`);
  beforeEach(() => {
    vi.useFakeTimers();
    writeText = vi.fn().mockResolvedValue(undefined);
    vi.stubGlobal("navigator", { clipboard: { writeText } });
  });
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount() {
    document.body.innerHTML = `<div id="access-token-section" data-controller="token" data-token-item-value="secret">
      <input data-token-target="input" value="******">
      <button data-token-target="maskButton" data-action="token#toggleVisibility">Show</button>
      <span data-token-target="hide">Hide</span><span class="hidden" data-token-target="view">View</span>
      <button data-action="token#copyToClipboard"><span data-token-target="initial">Copy</span><span class="hidden" data-token-target="copied">Copied</span></button>
    </div>`;
    root = document.body.firstElementChild;
    application = startApplication();
    application.register("token", TokenController);
    await Promise.resolve();
    controller = application.getControllerForElementAndIdentifier(
      root,
      "token",
    );
  }
  it("reveals and remasks the complete token with matching pressed state", async () => {
    await mount();
    expect(root).toHaveAttribute("data-controller-connected", "true");
    expect(target("maskButton")).toHaveAttribute("aria-pressed", "false");
    target("maskButton").click();
    expect(target("input")).toHaveValue("secret");
    expect(target("maskButton")).toHaveAttribute("aria-pressed", "true");
    expect(target("hide")).toHaveClass("hidden");
    expect(target("view")).not.toHaveClass("hidden");
    target("maskButton").click();
    expect(target("input")).toHaveValue("******");
    expect(target("maskButton")).toHaveAttribute("aria-pressed", "false");
    expect(target("hide")).not.toHaveClass("hidden");
    expect(target("view")).toHaveClass("hidden");
  });
  it("shows success only once the clipboard write completes", async () => {
    let resolve;
    writeText.mockReturnValue(
      new Promise((done) => {
        resolve = done;
      }),
    );
    await mount();
    const copying = controller.copyToClipboard();
    expect(writeText).toHaveBeenCalledWith("secret");
    expect(target("copied")).toHaveClass("hidden");
    resolve();
    await copying;
    expect(target("copied")).not.toHaveClass("hidden");
    expect(target("initial")).toHaveClass("hidden");
    vi.advanceTimersByTime(2000);
    expect(target("copied")).toHaveClass("hidden");
    expect(target("initial")).not.toHaveClass("hidden");
  });
  it("restarts feedback on repeated copies and cancels it on removal", async () => {
    await mount();
    await controller.copyToClipboard();
    vi.advanceTimersByTime(1500);
    await controller.copyToClipboard();
    vi.advanceTimersByTime(500);
    expect(target("copied")).not.toHaveClass("hidden");
    root.remove();
    await Promise.resolve();
    await Promise.resolve();
    expect(vi.getTimerCount()).toBe(0);
    expect(target("copied")).toHaveClass("hidden");
  });
  it("ignores a pending copy from an earlier connection", async () => {
    let resolve;
    writeText.mockReturnValue(
      new Promise((done) => {
        resolve = done;
      }),
    );
    await mount();
    const copying = controller.copyToClipboard();
    root.remove();
    await Promise.resolve();
    await Promise.resolve();
    document.body.append(root);
    await Promise.resolve();
    resolve();
    await copying;
    expect(target("copied")).toHaveClass("hidden");
  });
  it("remasks a revealed token when reconnecting", async () => {
    await mount();
    target("maskButton").click();
    root.remove();
    await Promise.resolve();
    await Promise.resolve();
    document.body.append(root);
    await Promise.resolve();
    expect(target("input")).toHaveValue("******");
    expect(target("maskButton")).toHaveAttribute("aria-pressed", "false");
  });
  it("handles rejected writes without false success", async () => {
    writeText.mockRejectedValue(new Error("Denied"));
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    await mount();
    await controller.copyToClipboard();
    expect(log).toHaveBeenCalled();
    expect(target("copied")).toHaveClass("hidden");
  });
  it("handles an unavailable clipboard", async () => {
    vi.stubGlobal("navigator", {});
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    await mount();
    await controller.copyToClipboard();
    expect(log).toHaveBeenCalledWith("Clipboard API not available");
    expect(target("copied")).toHaveClass("hidden");
  });
  it("removes an existing token panel and tolerates an already removed panel", async () => {
    await mount();
    controller.removeTokenPanel();
    expect(document.querySelector("#access-token-section")).toBeNull();
    expect(() => controller.removeTokenPanel()).not.toThrow();
  });
});
