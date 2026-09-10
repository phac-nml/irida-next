import { describe, expect, it } from "vitest";
import { FIELD_CLASSES } from "../../../app/javascript/utilities/styles.js";

describe("styles", () => {
  it("contains the red error classes used by form validation", () => {
    expect(FIELD_CLASSES.ERROR).toEqual([
      "bg-slate-50",
      "border",
      "border-red-500",
      "text-slate-900",
      "text-sm",
      "rounded-lg",
      "block",
      "w-full",
      "p-2.5",
      "dark:bg-slate-700",
      "dark:border-slate-600",
      "dark:placeholder-slate-400",
      "dark:text-white",
    ]);
    expect(FIELD_CLASSES.ERROR_SPAN).toEqual(["text-red-500"]);
  });

  it("contains the default valid styling classes", () => {
    expect(FIELD_CLASSES.VALID).toEqual([
      "bg-slate-50",
      "border",
      "border-slate-300",
      "text-slate-900",
      "text-sm",
      "rounded-lg",
      "block",
      "w-full",
      "p-2.5",
      "dark:bg-slate-700",
      "dark:border-slate-600",
      "dark:placeholder-slate-400",
      "dark:text-white",
    ]);
  });
});
