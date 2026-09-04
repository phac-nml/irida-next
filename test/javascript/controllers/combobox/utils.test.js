import { describe, it, expect } from "vitest";
import {
  isComboboxDisabled,
  isOptionDisabled,
  isPrintableCharacter,
  getLowercaseContent,
  highlightOption,
  setActiveDescendant,
} from "../../../../app/javascript/controllers/combobox/utils.js";

describe("combobox utils", () => {
  describe("isPrintableCharacter", () => {
    it("returns a truthy match for a single printable character", () => {
      expect(isPrintableCharacter("a")).toBeTruthy();
      expect(isPrintableCharacter(" ")).toBeTruthy();
    });

    it("returns false for multi-character or empty strings", () => {
      expect(isPrintableCharacter("ab")).toBe(false);
      expect(isPrintableCharacter("")).toBe(false);
    });

    it("returns null for a single non-printable character", () => {
      expect(isPrintableCharacter("\n")).toBeNull();
    });
  });

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

  describe("getLowercaseContent", () => {
    it("uses the data-label attribute when present", () => {
      const node = document.createElement("div");
      node.setAttribute("data-label", "Alpha");
      node.textContent = "ignored";

      expect(getLowercaseContent(node)).toBe("alpha");
    });

    it("falls back to textContent when no data-label is set", () => {
      const node = document.createElement("div");
      node.textContent = "BETA";

      expect(getLowercaseContent(node)).toBe("beta");
    });
  });

  describe("highlightOption", () => {
    it("returns the option unchanged when no filter is provided", () => {
      const option = document.createElement("div");
      option.textContent = "Sample";

      expect(highlightOption(option, "")).toBe(option);
      expect(option.querySelector("mark")).toBeNull();
    });

    it("wraps matching text in a mark element", () => {
      const option = document.createElement("div");
      option.textContent = "Sample";

      highlightOption(option, "amp");

      const mark = option.querySelector("mark");
      expect(mark).not.toBeNull();
      expect(mark.textContent).toBe("amp");
    });

    it("escapes regex metacharacters in the filter", () => {
      const option = document.createElement("div");
      option.textContent = "a.b";

      highlightOption(option, ".");

      expect(option.querySelector("mark").textContent).toBe(".");
    });

    it("leaves text without a match untouched", () => {
      const option = document.createElement("div");
      option.textContent = "Sample";

      highlightOption(option, "zzz");

      expect(option.querySelector("mark")).toBeNull();
      expect(option.textContent).toBe("Sample");
    });

    it("preserves leading and trailing text around a match", () => {
      const option = document.createElement("div");
      option.textContent = "xxAyy";

      highlightOption(option, "A");

      expect(option.textContent).toBe("xxAyy");
      expect(option.querySelector("mark").textContent).toBe("A");
    });

    it("skips empty text nodes", () => {
      const option = document.createElement("div");
      option.appendChild(document.createTextNode(""));
      option.appendChild(document.createTextNode("Sample"));

      highlightOption(option, "Sam");

      expect(option.querySelector("mark").textContent).toBe("Sam");
    });

    it("highlights a match at the end of the text", () => {
      const option = document.createElement("div");
      option.textContent = "Sample";

      highlightOption(option, "ple");

      expect(option.querySelector("mark").textContent).toBe("ple");
      expect(option.textContent).toBe("Sample");
    });
  });

  describe("setActiveDescendant", () => {
    it("sets aria-activedescendant to the option id", () => {
      const option = document.createElement("div");
      option.id = "option-1";
      const combobox = document.createElement("input");

      setActiveDescendant(option, combobox);

      expect(combobox.getAttribute("aria-activedescendant")).toBe("option-1");
    });

    it("removes aria-activedescendant when no option is given", () => {
      const combobox = document.createElement("input");
      combobox.setAttribute("aria-activedescendant", "option-1");

      setActiveDescendant(null, combobox);

      expect(combobox.hasAttribute("aria-activedescendant")).toBe(false);
    });
  });
});
