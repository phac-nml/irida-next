import { describe, expect, it, vi } from "vitest";
import {
  focusCondition,
  focusConditionField,
} from "../../../app/javascript/utilities/advanced_search_focus.js";

describe("advanced_search_focus utilities", () => {
  describe("focusCondition", () => {
    it("returns early when condition is missing", () => {
      expect(() => focusCondition(null)).not.toThrow();
    });

    it("sets tabindex and focuses when missing", () => {
      const condition = document.createElement("fieldset");
      const focusSpy = vi.spyOn(condition, "focus");

      focusCondition(condition);

      expect(condition.getAttribute("tabindex")).toBe("-1");
      expect(focusSpy).toHaveBeenCalledTimes(1);
    });

    it("keeps an existing tabindex value", () => {
      const condition = document.createElement("fieldset");
      condition.setAttribute("tabindex", "0");
      const focusSpy = vi.spyOn(condition, "focus");

      focusCondition(condition);

      expect(condition.getAttribute("tabindex")).toBe("0");
      expect(focusSpy).toHaveBeenCalledTimes(1);
    });
  });

  describe("focusConditionField", () => {
    it("returns early when condition is missing", () => {
      expect(() => focusConditionField(null)).not.toThrow();
    });

    it("focuses the first available field", () => {
      const condition = document.createElement("fieldset");
      const hiddenType = document.createElement("input");
      hiddenType.type = "hidden";

      const disabledInput = document.createElement("input");
      disabledInput.disabled = true;

      const hiddenInput = document.createElement("input");
      hiddenInput.hidden = true;

      const ariaDisabledInput = document.createElement("input");
      ariaDisabledInput.setAttribute("aria-disabled", "true");

      const inertWrapper = document.createElement("div");
      inertWrapper.setAttribute("inert", "");
      const inertInput = document.createElement("input");
      inertWrapper.append(inertInput);

      const availableSelect = document.createElement("select");
      availableSelect.name =
        "q[groups_attributes][0][conditions_attributes][0][field]";
      const focusSpy = vi.spyOn(availableSelect, "focus");

      condition.append(
        hiddenType,
        disabledInput,
        hiddenInput,
        ariaDisabledInput,
        inertWrapper,
        availableSelect,
      );

      focusConditionField(condition);

      expect(focusSpy).toHaveBeenCalledTimes(1);
    });

    it("no-ops when no available field exists", () => {
      const condition = document.createElement("fieldset");
      const hiddenType = document.createElement("input");
      hiddenType.type = "hidden";
      const inertWrapper = document.createElement("div");
      inertWrapper.setAttribute("inert", "");
      const inertInput = document.createElement("input");
      inertWrapper.append(inertInput);
      condition.append(hiddenType, inertWrapper);

      expect(() => focusConditionField(condition)).not.toThrow();
    });
  });
});
