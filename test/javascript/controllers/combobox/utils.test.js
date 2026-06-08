import { describe, it, expect } from "vitest";
import { isOptionDisabled } from "../../../../app/javascript/controllers/combobox/utils.js";

describe("combobox utils", () => {
  describe("isOptionDisabled", () => {
    it("returns true when aria-disabled is true", () => {
      const option = document.createElement("div");
      option.setAttribute("aria-disabled", "true");

      expect(isOptionDisabled(option)).toBe(true);
    });

    it("returns false when aria-disabled is absent or false", () => {
      const enabledOption = document.createElement("div");
      const falseOption = document.createElement("div");
      falseOption.setAttribute("aria-disabled", "false");

      expect(isOptionDisabled(enabledOption)).toBe(false);
      expect(isOptionDisabled(falseOption)).toBe(false);
      expect(isOptionDisabled(null)).toBe(false);
    });
  });
});
