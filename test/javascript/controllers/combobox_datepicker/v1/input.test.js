import { Application } from "@hotwired/stimulus";
import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import InputController from "../../../../../app/javascript/controllers/combobox_datepicker/v1/input_controller.js";
import CalendarController from "../../../../../app/javascript/controllers/combobox_datepicker/v1/calendar_controller.js";
import {
  renderBaseFixture,
  renderMinDate,
  renderMaxDate,
  getMonthSelect,
  getYearInput,
  getDateNode,
} from "./test_helpers.js";

async function startController() {
  const application = Application.start();
  application.register("combobox-datepicker--v1--input", InputController);
  application.register("combobox-datepicker--v1--calendar", CalendarController);
  await Promise.resolve();
  return application;
}

describe("combobox_datepicker input testing", () => {
  let application;

  beforeEach(() => {
    window.requestAnimationFrame = (callback) => setTimeout(callback, 0);
    vi.useFakeTimers();
  });

  afterEach(() => {
    application?.stop();
    vi.useRealTimers();
    document.body.innerHTML = "";
  });

  describe("default datepicker without min or max date", () => {
    it("type date directly into input", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();
      const input = document.getElementById("test_id-input");

      expect(getDateNode("2027-10-10")).toBeNull();
      expect(input.value).toBe("");
      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");

      input.value = "2027-10-10";
      input.dispatchEvent(new Event("change", { bubbles: true }));
      input.click();

      expect(getMonthSelect().value).toBe("October");
      expect(getYearInput().value).toBe("2027");
      expect(getDateNode("2027-10-10")).toHaveClass("bg-primary-700");

      input.value = "01-01-2026";
      input.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Enter",
          bubbles: true,
        }),
      );
      input.click();

      expect(getMonthSelect().value).toBe("October");
      expect(getYearInput().value).toBe("2027");
      expect(getDateNode("2027-10-10")).toHaveClass("bg-primary-700");
    });
  });

  describe("datepicker with min date", () => {
    it("direct input of date before minDate doesn't change calendar", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-04-04");
      application = await startController();
      const input = document.getElementById("test_id-input");

      expect(getDateNode("2026-04-01")).toBeNull();
      expect(input.value).toBe("");
      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");

      input.value = "2026-04-01";
      input.dispatchEvent(new Event("change", { bubbles: true }));
      input.click();

      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");
      expect(getDateNode("2026-04-01")).toBeNull();
      expect(getDateNode("2026-05-07")).not.toBeNull();

      input.value = "2026-04-08";
      input.dispatchEvent(new Event("change", { bubbles: true }));
      input.click();

      expect(getMonthSelect().value).toBe("April");
      expect(getYearInput().value).toBe("2026");
      expect(getDateNode("2026-05-07")).toBeNull();
      expect(getDateNode("2026-04-04")).not.toBeNull();
      expect(getDateNode("2026-04-08")).toHaveClass("bg-primary-700");
    });
  });

  describe("datepicker with max date", () => {
    it("direct input of date past maxDate doesn't change calendar", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2026-06-04");
      application = await startController();
      const input = document.getElementById("test_id-input");

      expect(getDateNode("2026-06-10")).toBeNull();
      expect(input.value).toBe("");
      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");

      input.value = "2026-06-10";
      input.dispatchEvent(new Event("change", { bubbles: true }));
      input.click();

      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");
      expect(getDateNode("2026-06-10")).toBeNull();
      expect(getDateNode("2026-05-07")).not.toBeNull();
    });
  });
});
