import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";
import { createFocusTrap } from "focus-trap";
vi.mock("focus-trap", () => ({ createFocusTrap: vi.fn() }));

describe("dialog controller", () => {
  let application, element, dialog, trigger, controller, DialogController;
  beforeEach(async () => {
    vi.resetModules();
    DialogController = (
      await import("../../../../app/javascript/controllers/viral/dialog_controller.js")
    ).default;
    createFocusTrap.mockImplementation((_element, options) => {
      let active = false;
      return {
        activate: vi.fn(() => {
          if (!active) {
            active = true;
            options.onActivate();
          }
        }),
        deactivate: vi.fn(() => {
          if (active) {
            active = false;
            options.onDeactivate();
          }
        }),
      };
    });
  });
  afterEach(async () => {
    await stopApplication(application);
  });
  function fixture({
    open = false,
    withTrigger = true,
    close = "visible",
  } = {}) {
    const root = document.createElement("div");
    root.setAttribute("data-controller", "viral--dialog");
    root.setAttribute("data-viral--dialog-open-value", String(open));
    root.innerHTML = `${withTrigger ? '<button data-viral--dialog-target="trigger" data-action="viral--dialog#open">Open</button>' : ""}
      <dialog data-viral--dialog-target="dialog" data-action="keydown.esc->viral--dialog#handleEsc">
        ${close !== "absent" ? `<button data-viral--dialog-target="closeButton" data-action="viral--dialog#handleClose" ${close === "hidden" ? "hidden" : ""}>Close</button>` : ""}<input></dialog>`;
    const modal = root.querySelector("dialog");
    // jsdom has no modal top layer. Model only the browser method boundary.
    modal.showModal = vi.fn(() => {
      modal.open = true;
    });
    modal.close = vi.fn(() => {
      modal.open = false;
    });
    return root;
  }
  async function mount(options) {
    element = fixture(options);
    document.body.append(element);
    dialog = element.querySelector("dialog");
    trigger = element.querySelector('[data-viral--dialog-target="trigger"]');
    application = startApplication();
    application.register("viral--dialog", DialogController);
    await Promise.resolve();
    controller = application.getControllerForElementAndIdentifier(
      element,
      "viral--dialog",
    );
  }
  async function open() {
    trigger.click();
    await Promise.resolve();
  }
  function escape() {
    const event = new KeyboardEvent("keydown", {
      key: "Escape",
      bubbles: true,
      cancelable: true,
    });
    dialog.dispatchEvent(event);
    return event;
  }
  it("opens from a trigger, traps focus, and restores focus on close", async () => {
    await mount();
    expect(element.dataset.controllerConnected).toBe("true");
    expect(dialog.open).toBe(false);
    expect(createFocusTrap).not.toHaveBeenCalled();
    await open();
    expect(dialog.open).toBe(true);
    expect(element.hasAttribute("data-turbo-permanent")).toBe(true);
    expect(dialog.classList.contains("focus-trap")).toBe(true);
    expect(createFocusTrap).toHaveBeenCalledWith(
      dialog,
      expect.objectContaining({ escapeDeactivates: false }),
    );
    dialog.querySelector("button").click();
    await Promise.resolve();
    expect(dialog.open).toBe(false);
    expect(element.hasAttribute("data-turbo-permanent")).toBe(false);
    expect(dialog.classList.contains("focus-trap")).toBe(false);
    expect(document.activeElement).toBe(trigger);
    await open();
    expect(createFocusTrap).toHaveBeenCalledOnce();
  });
  it("opens server-rendered dialogs without a local trigger", async () => {
    await mount({ open: true, withTrigger: false });
    expect(dialog.open).toBe(true);
    expect(escape().defaultPrevented).toBe(true);
    expect(dialog.open).toBe(false);
  });
  it("cleans up a removed open dialog without a trigger", async () => {
    await mount({ open: true, withTrigger: false });
    element.remove();
    await Promise.resolve();
    expect(dialog.open).toBe(false);
    expect(dialog.classList.contains("focus-trap")).toBe(false);
  });
  it("responds to external open-value changes", async () => {
    await mount();
    element.setAttribute("data-viral--dialog-open-value", "true");
    await Promise.resolve();
    expect(dialog.open).toBe(true);
    element.setAttribute("data-viral--dialog-open-value", "false");
    await Promise.resolve();
    expect(dialog.open).toBe(false);
  });
  it("allows clients to cancel a close request", async () => {
    await mount();
    await open();
    const cancel = vi.fn((event) => event.preventDefault());
    element.addEventListener("viral--dialog:close", cancel, { once: true });
    escape();
    expect(cancel).toHaveBeenCalledOnce();
    expect(dialog.open).toBe(true);
    escape();
    expect(dialog.open).toBe(false);
  });
  it.each(["absent", "hidden"])(
    "blocks native Escape dismissal with a %s close button",
    async (close) => {
      await mount({ open: true, close });
      expect(escape().defaultPrevented).toBe(true);
      expect(dialog.open).toBe(true);
    },
  );
  it("updates Escape handling when the close target is replaced", async () => {
    await mount({ open: true });
    const button = dialog.querySelector("button");
    button.remove();
    await Promise.resolve();
    escape();
    expect(dialog.open).toBe(true);
    dialog.append(button);
    await Promise.resolve();
    escape();
    expect(dialog.open).toBe(false);
  });
  it("toggles close-button visibility and Escape handling together", async () => {
    await mount({ open: true });
    controller.setClosable({ params: { closable: false } });
    expect(dialog.querySelector("button").hidden).toBe(true);
    escape();
    expect(dialog.open).toBe(true);
    controller.setClosable({ params: { closable: true } });
    expect(dialog.querySelector("button").hidden).toBe(false);
    escape();
    expect(dialog.open).toBe(false);
  });
  it("ignores non-keyboard events passed to the Escape action", async () => {
    await mount({ open: true });
    const event = new Event("cancel", { cancelable: true });
    controller.handleEsc(event);
    expect(event.defaultPrevented).toBe(true);
    expect(dialog.open).toBe(true);
  });
  it("restores focus to an external trigger supplied by an outlet", async () => {
    await mount({ open: true, withTrigger: false });
    const external = document.createElement("button");
    document.body.append(external);
    controller.updateTrigger(external);
    controller.handleClose();
    expect(document.activeElement).toBe(external);
  });
  it("deactivates a removed modal and focuses its replacement trigger", async () => {
    await mount();
    await open();
    element.remove();
    await Promise.resolve();
    expect(dialog.open).toBe(false);
    expect(dialog.classList.contains("focus-trap")).toBe(false);
    const replacement = fixture();
    document.body.append(replacement);
    await Promise.resolve();
    expect(document.activeElement).toBe(replacement.querySelector("button"));
  });
  it("handles a replacement with no trigger after an open dialog was removed", async () => {
    await mount();
    await open();
    element.remove();
    await Promise.resolve();
    const replacement = fixture({ withTrigger: false });
    document.body.append(replacement);
    await Promise.resolve();
    expect(replacement.dataset.controllerConnected).toBe("true");
  });
  it("does not refocus on reconnect after a normal close", async () => {
    await mount();
    await open();
    controller.handleClose();
    await Promise.resolve();
    element.remove();
    await Promise.resolve();
    const outside = document.createElement("button");
    document.body.append(outside);
    outside.focus();
    document.body.append(element);
    await Promise.resolve();
    expect(document.activeElement).toBe(outside);
  });
});
