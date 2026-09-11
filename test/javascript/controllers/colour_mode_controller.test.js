import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import ColourModeController from "../../../app/javascript/controllers/colour_mode_controller.js";
import { announce } from "utilities/live_region";
vi.mock("utilities/live_region", () => ({ announce: vi.fn() }));

describe("colour mode controller", () => {
  let application, element, originalClass;
  beforeEach(() => {
    originalClass = document.documentElement.className;
  });
  afterEach(async () => {
    await stopApplication(application);
    document.documentElement.className = originalClass;
  });
  async function mount({ saved, dark = false, messages = "" } = {}) {
    if (saved !== undefined) localStorage.setItem("theme", saved);
    vi.spyOn(window, "matchMedia").mockReturnValue({ matches: dark });
    document.body.innerHTML = `<div data-controller="colour-mode" ${messages}>
      ${["system", "light", "dark"].map((theme) => `<input type="radio" name="theme" value="${theme}" data-colour-mode-target="${theme}" data-action="change->colour-mode#toggleTheme">`).join("")}
    </div>`;
    element = document.body.firstElementChild;
    application = startApplication();
    application.register("colour-mode", ColourModeController);
    await Promise.resolve();
  }
  function change(theme) {
    const input = element.querySelector(`[value="${theme}"]`);
    input.checked = true;
    input.dispatchEvent(new Event("change", { bubbles: true }));
  }
  it.each([
    [undefined, true, "system", true],
    ["invalid", true, "system", true],
    ["system", false, "system", false],
    ["system", true, "system", true],
    ["dark", false, "dark", true],
    ["light", true, "light", false],
  ])(
    "restores %s with system dark=%s",
    async (saved, dark, selected, expectedDark) => {
      await mount({ saved, dark });
      expect(element.querySelector(":checked").value).toBe(selected);
      expect(document.documentElement.classList.contains("dark")).toBe(
        expectedDark,
      );
      expect(document.documentElement.classList.contains("light")).toBe(
        !expectedDark,
      );
      expect(announce).not.toHaveBeenCalled();
    },
  );
  it("falls back to the system preference when storage cannot be read", async () => {
    const error = new DOMException("Storage blocked", "SecurityError");
    vi.spyOn(Storage.prototype, "getItem").mockImplementation(() => {
      throw error;
    });
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    await mount({ dark: true });
    expect(element.querySelector(":checked").value).toBe("system");
    expect(document.documentElement.classList.contains("dark")).toBe(true);
    expect(log).toHaveBeenCalledWith("Failed to initialize theme:", error);
  });
  it.each([
    ["", "Theme changed to dark"],
    ['data-changed-text=""', "Theme changed to dark"],
    [
      'data-changed-text="Now %{theme}" data-dark-text="Dark mode"',
      "Now Dark mode",
    ],
    [
      'data-changed-text="Selected" data-dark-text="Dark mode"',
      "Selected Dark mode",
    ],
  ])(
    "persists and announces a theme change with %s",
    async (messages, expected) => {
      await mount({ messages });
      change("dark");
      expect(localStorage.getItem("theme")).toBe("dark");
      expect(document.documentElement.classList.contains("dark")).toBe(true);
      expect(announce).toHaveBeenCalledWith(expected, {
        element: document.querySelector('[aria-live="polite"]'),
      });
      change("light");
      expect(document.documentElement.classList.contains("dark")).toBe(false);
      expect(localStorage.getItem("theme")).toBe("light");
    },
  );
  it("resolves the system setting when selected", async () => {
    await mount({
      saved: "light",
      dark: true,
      messages: 'data-system-text="System preference"',
    });
    change("system");
    expect(localStorage.getItem("theme")).toBe("system");
    expect(document.documentElement.classList.contains("dark")).toBe(true);
    expect(announce).toHaveBeenCalledWith(
      "Theme changed to System preference",
      expect.any(Object),
    );
  });
  it.each([
    ["", "Unable to change theme. Please try again."],
    ['data-error-text="Try later"', "Try later"],
  ])("announces storage failures with %s", async (messages, expected) => {
    await mount({ saved: "light", messages });
    const error = new DOMException("Storage full", "QuotaExceededError");
    vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw error;
    });
    const log = vi.spyOn(console, "error").mockImplementation(() => {});
    change("dark");
    expect(document.documentElement.classList.contains("light")).toBe(true);
    expect(announce).toHaveBeenCalledWith(expected, expect.any(Object));
    expect(log).toHaveBeenCalledWith("Failed to toggle theme:", error);
  });
  it("removes its live region on disconnect and creates just one on reconnect", async () => {
    await mount();
    const region = document.querySelector('[aria-live="polite"]');
    expect(region.getAttribute("aria-atomic")).toBe("true");
    expect(region.classList.contains("sr-only")).toBe(true);
    element.remove();
    await Promise.resolve();
    expect(region.isConnected).toBe(false);
    document.body.append(element);
    await Promise.resolve();
    expect(document.querySelectorAll('[aria-live="polite"]')).toHaveLength(1);
  });
});
