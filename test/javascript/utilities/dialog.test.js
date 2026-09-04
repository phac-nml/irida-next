import { describe, it, expect, vi } from "vitest";
import {
  closeDialog,
  openDialog,
  ensureDialog,
} from "../../../app/javascript/utilities/dialog.js";

function renderDialogFixture() {
  document.body.innerHTML = `
    <section data-controller="viral--dialog" id="dialog-host">
      <button id="dialog-trigger" type="button">Open</button>
      <div data-viral--dialog-target="dialog" id="dialog-element"></div>
    </section>
  `;

  return {
    host: document.getElementById("dialog-host"),
    trigger: document.getElementById("dialog-trigger"),
    dialogElement: document.getElementById("dialog-element"),
  };
}

function buildApplication(controller = null) {
  return {
    getControllerForElementAndIdentifier: vi.fn(() => controller),
  };
}

describe("dialog", () => {
  describe("closeDialog", () => {
    it("is a no-op when no viral dialog host exists", () => {
      const button = document.createElement("button");
      const application = buildApplication();

      closeDialog(button, application);

      expect(
        application.getControllerForElementAndIdentifier,
      ).not.toHaveBeenCalled();
    });

    it("prefers the viral dialog controller close action", () => {
      const { host, trigger, dialogElement } = renderDialogFixture();
      dialogElement.close = vi.fn();
      const close = vi.fn();
      const application = buildApplication({ close });

      closeDialog(trigger, application);

      expect(
        application.getControllerForElementAndIdentifier,
      ).toHaveBeenCalledWith(host, "viral--dialog");
      expect(close).toHaveBeenCalledTimes(1);
      expect(dialogElement.close).not.toHaveBeenCalled();
    });

    it("falls back to the native dialog close method", () => {
      const { trigger, dialogElement } = renderDialogFixture();
      dialogElement.close = vi.fn();

      closeDialog(trigger, buildApplication());

      expect(dialogElement.close).toHaveBeenCalledTimes(1);
    });

    it("does not throw when fallback target has no close method", () => {
      const { trigger } = renderDialogFixture();

      expect(() => closeDialog(trigger, buildApplication())).not.toThrow();
    });
  });

  describe("openDialog", () => {
    it("is a no-op when no viral dialog host exists", () => {
      const button = document.createElement("button");
      const application = buildApplication();

      openDialog(button, application);

      expect(
        application.getControllerForElementAndIdentifier,
      ).not.toHaveBeenCalled();
    });

    it("prefers the viral dialog controller open action", () => {
      const { host, trigger } = renderDialogFixture();
      const open = vi.fn();
      const application = buildApplication({ open });

      openDialog(trigger, application);

      expect(
        application.getControllerForElementAndIdentifier,
      ).toHaveBeenCalledWith(host, "viral--dialog");
      expect(open).toHaveBeenCalledTimes(1);
      expect(trigger.getAttribute("data-viral--dialog-open-value")).toBeNull();
    });

    it("falls back to setting the open value attribute on the element", () => {
      const { trigger } = renderDialogFixture();

      openDialog(trigger, buildApplication());

      expect(trigger.getAttribute("data-viral--dialog-open-value")).toBe(
        "true",
      );
    });
  });

  describe("ensureDialog", () => {
    it("returns null when operation id is missing", () => {
      expect(
        ensureDialog({
          _operationId: null,
          identifier: "test",
        }),
      ).toBeNull();
    });

    it("creates a dialog from template when absent", () => {
      const template = document.createElement("template");
      template.innerHTML =
        '<div data-viral--dialog-target="dialog">Dialog</div>';
      const controller = {
        _operationId: "456",
        identifier: "samples",
        dialogTemplateTarget: template,
      };

      const dialog = ensureDialog(controller);

      expect(dialog).toBeInTheDocument();
      expect(dialog.id).toBe("samples-dialog-456");
    });

    it("returns an existing dialog instead of creating a new one", () => {
      const existing = document.createElement("div");
      existing.id = "samples-dialog-999";
      document.body.appendChild(existing);

      const template = document.createElement("template");
      template.innerHTML =
        '<div data-viral--dialog-target="dialog">Dialog</div>';

      const dialog = ensureDialog({
        _operationId: "999",
        identifier: "samples",
        dialogTemplateTarget: template,
      });

      expect(dialog).toBe(existing);
      expect(document.querySelectorAll("#samples-dialog-999")).toHaveLength(1);
    });
  });
});
