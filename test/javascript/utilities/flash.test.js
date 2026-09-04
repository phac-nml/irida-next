import { describe, it, expect } from "vitest";
import { ensureFlash } from "../../../app/javascript/utilities/flash.js";

function buildController() {
  const template = document.createElement("template");
  template.innerHTML = '<div class="flash">Saved</div>';

  return {
    _operationId: "123",
    identifier: "samples",
    flashTemplateTarget: template,
  };
}

describe("flash", () => {
  describe("ensureFlash", () => {
    it("returns null when operation id is missing", () => {
      const controller = buildController();
      controller._operationId = null;

      expect(ensureFlash(controller)).toBeNull();
    });

    it("returns an existing flash element when present", () => {
      const controller = buildController();
      const existing = document.createElement("div");
      existing.id = "samples-flash-123";
      document.body.appendChild(existing);

      expect(ensureFlash(controller)).toBe(existing);
    });

    it("creates and appends a flash inside #flashes", () => {
      document.body.innerHTML = '<div id="flashes"></div>';
      const controller = buildController();

      ensureFlash(controller);

      const flash = document.getElementById("samples-flash-123");
      expect(flash).toBeInTheDocument();
      expect(flash.textContent).toContain("Saved");
    });

    it("returns null when the flashes container does not exist", () => {
      const controller = buildController();

      expect(ensureFlash(controller)).toBeNull();
      expect(document.getElementById("samples-flash-123")).toBeNull();
    });
  });
});
