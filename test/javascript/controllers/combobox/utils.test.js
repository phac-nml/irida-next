import { describe, it, expect } from "vitest";
import {
  isComboboxDisabled,
  isOptionDisabled,
} from "../../../../app/javascript/controllers/combobox/utils.js";

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

  describe("isComboboxDisabled", () => {
    it("returns true when aria-disabled is true", () => {
      const combobox = document.createElement("input");
      combobox.setAttribute("aria-disabled", "true");

      expect(isComboboxDisabled(combobox)).toBe(true);
    });

    it("returns false when aria-disabled is absent or false", () => {
      const enabledCombobox = document.createElement("input");
      const falseCombobox = document.createElement("input");
      falseCombobox.setAttribute("aria-disabled", "false");

      expect(isComboboxDisabled(enabledCombobox)).toBe(false);
      expect(isComboboxDisabled(falseCombobox)).toBe(false);
      expect(isComboboxDisabled(null)).toBe(false);
    });
  });
});
