import { Controller } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../../helpers/stimulus.js";

describe("dialog trigger controller", () => {
  let application, updateTrigger, DialogTriggerController;
  beforeEach(async () => {
    vi.resetModules();
    DialogTriggerController = (
      await import("../../../../app/javascript/controllers/viral/dialog_trigger_controller.js")
    ).default;
    updateTrigger = vi.fn();
  });
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount() {
    document.body.innerHTML = `<button data-controller="viral--dialog-trigger" data-viral--dialog-trigger-target="button"
      data-action="viral--dialog-trigger#open" data-viral--dialog-trigger-viral--dialog-outlet=".dialog">Open</button>`;
    class DialogOutlet extends Controller {
      updateTrigger(button) {
        updateTrigger(button);
      }
    }
    application = startApplication();
    application.register("viral--dialog", DialogOutlet);
    application.register("viral--dialog-trigger", DialogTriggerController);
    await Promise.resolve();
  }
  async function insertDialog() {
    const dialog = document.createElement("div");
    dialog.className = "dialog";
    dialog.setAttribute("data-controller", "viral--dialog");
    document.body.append(dialog);
    await Promise.resolve();
    await Promise.resolve();
    return dialog;
  }
  it("supplies no trigger when an outlet appears before any click", async () => {
    await mount();
    await insertDialog();
    expect(updateTrigger).toHaveBeenCalledWith(null);
  });
  it("hands the clicked button to a subsequently connected dialog outlet", async () => {
    await mount();
    const button = document.querySelector("button");
    button.click();
    await insertDialog();
    expect(updateTrigger).toHaveBeenCalledWith(button);
  });
  it("retains the originating button across replacement of the trigger controller", async () => {
    await mount();
    const original = document.querySelector("button");
    original.click();
    const replacement = original.cloneNode(true);
    original.replaceWith(replacement);
    await Promise.resolve();
    const dialog = await insertDialog();
    expect(updateTrigger).toHaveBeenLastCalledWith(original);
    dialog.remove();
    await Promise.resolve();
    replacement.click();
    await insertDialog();
    expect(updateTrigger).toHaveBeenLastCalledWith(replacement);
  });
});
