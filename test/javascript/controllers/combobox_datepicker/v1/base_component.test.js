import { Application } from "@hotwired/stimulus";
import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import InputController from "../../../../../app/javascript/controllers/combobox_datepicker/v1/input_controller.js";
import CalendarController from "../../../../../app/javascript/controllers/combobox_datepicker/v1/calendar_controller.js";
import {
  renderBaseFixture,
  renderMinDate,
  renderMaxDate,
  getBackButton,
  getForwardButton,
  getMonthSelect,
  getYearInput,
  getDateNode,
  getApril2026Dates,
  getMay2026Dates,
  getJune2026Dates,
  assertCalendarLayout,
  keypressOnDateNode,
  openCalendarByInputArrow,
  assertMonthSelectOptions,
} from "./test_helpers.js";

async function startController() {
  const application = Application.start();
  application.register("combobox-datepicker--v1--input", InputController);
  application.register("combobox-datepicker--v1--calendar", CalendarController);
  await Promise.resolve();
  return application;
}

describe("combobox_datepicker", () => {
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
    it("datepicker layout", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      expect(getBackButton().getAttribute("aria-disabled")).toBe("false");
      expect(getForwardButton().getAttribute("aria-disabled")).toBe("false");
      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");
      // validate today's date has specific styling (green dot under date)
      expect(getDateNode("2026-05-07")).toHaveClass("after:bg-primary-700");
      assertCalendarLayout(getMay2026Dates());

      assertMonthSelectOptions();
    });

    it("datepicker layout in a dialog", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();

      const main = document.querySelector("main");
      const datepicker = document.getElementById("test_id-datepicker");

      const dialog = document.createElement("dialog");
      main.appendChild(dialog);
      dialog.appendChild(datepicker);

      application = await startController();
      await vi.runOnlyPendingTimersAsync();

      const calendar = document.getElementById("test_id-calendar");

      await vi.runOnlyPendingTimersAsync();

      expect(calendar).toBeInTheDocument();
      expect(calendar.parentElement).toBe(dialog);

      expect(getBackButton().getAttribute("aria-disabled")).toBe("false");
      expect(getForwardButton().getAttribute("aria-disabled")).toBe("false");
      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");
      // validate today's date has specific styling (green dot under date)
      expect(getDateNode("2026-05-07")).toHaveClass("after:bg-primary-700");
      assertCalendarLayout(getMay2026Dates());

      assertMonthSelectOptions();

      openCalendarByInputArrow();
      expect(calendar.hidden).toBe(false);
      keypressOnDateNode("2026-05-07", "Escape");
      expect(calendar.hidden).toBe(true);
    });

    it("show/hide functionality", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      // calendar is hidden
      const calendar = document.getElementById("test_id-calendar");
      const input = document.getElementById("test_id-input");
      const inputArrowSvg = document
        .querySelector(
          '[data-combobox-datepicker--v1--input-target="inputArrow"]',
        )
        .querySelector("svg");

      expect(calendar.hidden).toBe(true);
      expect(inputArrowSvg).not.toHaveClass("rotate-180");

      // open by clicking input
      input.click();
      expect(calendar.hidden).toBe(false);
      expect(inputArrowSvg).toHaveClass("rotate-180");
      // toggle close by re-clicking input
      input.click();
      expect(calendar.hidden).toBe(true);
      expect(inputArrowSvg).not.toHaveClass("rotate-180");

      // "keyboard focus" element and open with ArrowDown, expect currentDate to be focused
      input.focus();
      input.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "ArrowDown",
          code: "ArrowDown",
          bubbles: true,
        }),
      );
      expect(calendar.hidden).toBe(false);
      expect(inputArrowSvg).toHaveClass("rotate-180");
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      // toggle close with Escape on Calendar
      keypressOnDateNode("2026-05-07", "Escape");
      expect(calendar.hidden).toBe(true);
      expect(inputArrowSvg).not.toHaveClass("rotate-180");

      input.click();
      expect(calendar.hidden).toBe(false);
      expect(inputArrowSvg).toHaveClass("rotate-180");

      input.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Escape",
          code: "Escape",
          bubbles: true,
        }),
      );
      expect(calendar.hidden).toBe(true);
      expect(inputArrowSvg).not.toHaveClass("rotate-180");

      // click arrow button on input, and expect focus on currentDate
      openCalendarByInputArrow();
      expect(calendar.hidden).toBe(false);
      expect(inputArrowSvg).toHaveClass("rotate-180");
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      input.click();
      input.click();
      expect(calendar.hidden).toBe(false);
      expect(inputArrowSvg).toHaveClass("rotate-180");
      input.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Tab",
          code: "Tab",
          bubbles: true,
        }),
      );
      expect(calendar.hidden).toBe(true);
      expect(inputArrowSvg).not.toHaveClass("rotate-180");
    });

    it("forward and back button functionality", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();
      const input = document.getElementById("test_id-input");
      const backButton = getBackButton();
      const forwardButton = getForwardButton();

      input.click();
      forwardButton.click();

      expect(getMonthSelect().value).toBe("June");
      expect(getYearInput().value).toBe("2026");
      assertCalendarLayout(getJune2026Dates());

      backButton.click();
      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");
      assertCalendarLayout(getMay2026Dates());

      backButton.click();

      expect(getMonthSelect().value).toBe("April");
      expect(getYearInput().value).toBe("2026");
      assertCalendarLayout(getApril2026Dates());
    });

    it("show today button", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();
      const input = document.getElementById("test_id-input");
      const forwardButton = getForwardButton();
      const showTodayButton = document.querySelector(
        'button[aria-label="Show today"]',
      );

      input.click();
      forwardButton.click();
      forwardButton.click();

      expect(getMonthSelect().value).toBe("July");
      expect(getYearInput().value).toBe("2026");

      showTodayButton.click();

      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");
      assertCalendarLayout(getMay2026Dates());
    });

    it("select date functionality", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();
      const calendar = document.getElementById("test_id-calendar");
      const input = document.getElementById("test_id-input");

      expect(calendar.hidden).toBe(true);
      input.click();
      expect(calendar.hidden).toBe(false);

      await vi.runOnlyPendingTimersAsync();

      expect(getDateNode("2026-05-20")).not.toHaveClass("bg-primary-700");
      getDateNode("2026-05-20").click();
      expect(calendar.hidden).toBe(true);
      expect(input.value).toBe("2026-05-20");

      input.click();
      await vi.runOnlyPendingTimersAsync();
      expect(calendar.hidden).toBe(false);
      // must re-query to get accurate class
      expect(getDateNode("2026-05-20")).toHaveClass("bg-primary-700");

      getDateNode("2026-05-30").dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Enter",
          bubbles: true,
        }),
      );

      expect(input.value).toBe("2026-05-30");
      expect(calendar.hidden).toBe(true);

      input.click();
      await vi.runOnlyPendingTimersAsync();
      expect(calendar.hidden).toBe(false);
      expect(getDateNode("2026-05-20")).not.toHaveClass("bg-primary-700");
      expect(getDateNode("2026-05-30")).toHaveClass("bg-primary-700");

      getDateNode("2026-05-10").dispatchEvent(
        new KeyboardEvent("keydown", {
          key: " ",
          bubbles: true,
        }),
      );

      await vi.runOnlyPendingTimersAsync();
      expect(getDateNode("2026-05-30")).not.toHaveClass("bg-primary-700");
      expect(getDateNode("2026-05-10")).toHaveClass("bg-primary-700");
      expect(input.value).toBe("2026-05-10");
      expect(calendar.hidden).toBe(false);
    });

    it("clear selection button", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();
      const calendar = document.getElementById("test_id-calendar");
      const input = document.getElementById("test_id-input");
      const clearSelectionButton = document.querySelector(
        'button[aria-label="Clear date selection"]',
      );
      input.click();
      await vi.runOnlyPendingTimersAsync();

      getDateNode("2026-05-10").dispatchEvent(
        new KeyboardEvent("keydown", {
          key: " ",
          bubbles: true,
        }),
      );

      expect(getDateNode("2026-05-10")).toHaveClass("bg-primary-700");
      expect(input.value).toBe("2026-05-10");
      expect(calendar.hidden).toBe(false);

      clearSelectionButton.click();

      expect(calendar.hidden).toBe(true);
      expect(input.value).toBe("");
    });

    it("contained tab logic on calendar", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();
      const backButton = getBackButton();
      const clearSelectionButton = document.querySelector(
        'button[aria-label="Clear date selection"]',
      );

      openCalendarByInputArrow();

      expect(document.activeElement).toBe(
        document.querySelector('[data-date="2026-05-07"]'),
      );

      clearSelectionButton.focus();

      expect(document.activeElement).toBe(clearSelectionButton);
      // await vi.runOnlyPendingTimersAsync();
      clearSelectionButton.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Tab",
          bubbles: true,
        }),
      );
      expect(document.activeElement).toBe(backButton);

      backButton.dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "Tab",
          bubbles: true,
          shiftKey: true,
        }),
      );

      expect(document.activeElement).toBe(clearSelectionButton);
    });

    it("month select", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();
      const monthSelect = getMonthSelect();
      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(monthSelect.value).toBe("May");

      monthSelect.value = "June";
      monthSelect.dispatchEvent(new Event("change", { bubbles: true }));
      await vi.runOnlyPendingTimersAsync();
      expect(monthSelect.value).toBe("June");
      assertCalendarLayout(getJune2026Dates());
    });

    it("year input", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();
      const calendar = document.getElementById("test_id-calendar");
      const yearInput = getYearInput();
      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(yearInput.value).toBe("2026");

      yearInput.value = "2027";
      yearInput.dispatchEvent(new Event("change", { bubbles: true }));
      await vi.runOnlyPendingTimersAsync();
      expect(yearInput.value).toBe("2027");
      expect(calendar.querySelector('[data-date="2026-05-06"]')).toBeNull();
      expect(calendar.querySelector('[data-date="2027-05-06"]')).not.toBeNull();
    });

    it("fr formatted aria-label on date", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture("fr");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      // Month is translated and passed in through backend, so in prod May would be mai
      expect(getDateNode("2026-05-07")).toHaveAttribute(
        "aria-label",
        "7 May, 2026",
      );
    });
  });

  describe("datepicker with min date", () => {
    it("datepicker layout with min date", async () => {
      vi.setSystemTime(new Date("2026-04-30T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-05-01");
      application = await startController();

      expect(getBackButton().getAttribute("aria-disabled")).toBe("true");
      expect(getForwardButton().getAttribute("aria-disabled")).toBe("false");
      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");
      expect(getDateNode("2026-04-30")).toHaveClass("after:bg-primary-700");

      assertMonthSelectOptions({ minMonth: "May" });

      assertCalendarLayout(getMay2026Dates(), { minDate: "2026-05-01" });

      getBackButton().click();
      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");
      expect(getDateNode("2026-04-30")).toHaveClass("after:bg-primary-700");
      assertCalendarLayout(getMay2026Dates());

      getForwardButton().click();
      await vi.runOnlyPendingTimersAsync();
      expect(getMonthSelect().value).toBe("June");
      expect(getYearInput().value).toBe("2026");
      expect(getBackButton().getAttribute("aria-disabled")).toBe("false");
      expect(getForwardButton().getAttribute("aria-disabled")).toBe("false");
      assertCalendarLayout(getJune2026Dates());
    });

    it("navigate back through year input onto a month/year before minDate", async () => {
      vi.setSystemTime(new Date("2027-02-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-05-04");
      application = await startController();
      const yearInput = getYearInput();
      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2027-02-07"));

      expect(yearInput.value).toBe("2027");
      assertMonthSelectOptions();

      yearInput.value = "2024";

      yearInput.dispatchEvent(new Event("change", { bubbles: true }));
      await vi.runOnlyPendingTimersAsync();

      assertMonthSelectOptions({ minMonth: "May" });
      expect(yearInput.value).toBe("2026");

      expect(getDateNode("2027-02-07")).toBeNull();
      expect(getDateNode("2026-05-04")).not.toBeNull();
    });

    it("show today button when minDate is last day of month on saturday renders next month", async () => {
      vi.setSystemTime(new Date("2026-10-31T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-11-01");
      application = await startController();
      const showTodayButton = document.querySelector(
        'button[aria-label="Show today"]',
      );
      openCalendarByInputArrow();
      await vi.runOnlyPendingTimersAsync();

      expect(getDateNode("2026-10-31")).toBeNull();
      expect(getMonthSelect().value).toBe("November");
      expect(getYearInput().value).toBe("2026");

      getForwardButton().click();
      await vi.runOnlyPendingTimersAsync();

      expect(getMonthSelect().value).toBe("December");
      expect(getYearInput().value).toBe("2026");

      showTodayButton.click();
      await vi.runOnlyPendingTimersAsync();

      expect(getMonthSelect().value).toBe("November");
      expect(getYearInput().value).toBe("2026");
    });

    it("show today button when minDate is last day of month on saturday renders next month - feb edge case", async () => {
      vi.setSystemTime(new Date("2026-02-28T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-03-01");
      application = await startController();
      const showTodayButton = document.querySelector(
        'button[aria-label="Show today"]',
      );
      openCalendarByInputArrow();
      await vi.runOnlyPendingTimersAsync();

      expect(getDateNode("2026-02-28")).toBeNull();
      expect(getMonthSelect().value).toBe("March");
      expect(getYearInput().value).toBe("2026");

      getForwardButton().click();
      await vi.runOnlyPendingTimersAsync();

      expect(getMonthSelect().value).toBe("April");
      expect(getYearInput().value).toBe("2026");

      showTodayButton.click();
      await vi.runOnlyPendingTimersAsync();

      expect(getMonthSelect().value).toBe("March");
      expect(getYearInput().value).toBe("2026");
    });
  });

  describe("datepicker with max date", () => {
    it("datepicker layout", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2026-06-04");
      application = await startController();

      expect(getBackButton().getAttribute("aria-disabled")).toBe("false");
      expect(getForwardButton().getAttribute("aria-disabled")).toBe("false");
      expect(getMonthSelect().value).toBe("May");
      expect(getYearInput().value).toBe("2026");
      expect(getDateNode("2026-05-07")).toHaveClass("after:bg-primary-700");

      assertMonthSelectOptions({ maxMonth: "June" });

      assertCalendarLayout(getMay2026Dates());

      getForwardButton().click();
      await vi.runOnlyPendingTimersAsync();
      expect(getMonthSelect().value).toBe("June");
      expect(getYearInput().value).toBe("2026");
      assertCalendarLayout(getJune2026Dates());

      getForwardButton().click();
      await vi.runOnlyPendingTimersAsync();
      expect(getMonthSelect().value).toBe("June");
      expect(getYearInput().value).toBe("2026");
      expect(getBackButton().getAttribute("aria-disabled")).toBe("false");
      expect(getForwardButton().getAttribute("aria-disabled")).toBe("true");
      assertCalendarLayout(getJune2026Dates(), { maxDate: "2026-06-04" });
    });

    it("navigate forward a year through year input onto a month/year after maxDate", async () => {
      vi.setSystemTime(new Date("2026-10-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2027-05-04");
      application = await startController();
      const yearInput = getYearInput();
      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-10-07"));

      expect(yearInput.value).toBe("2026");
      assertMonthSelectOptions();

      yearInput.value = "2030";

      yearInput.dispatchEvent(new Event("change", { bubbles: true }));
      await vi.runOnlyPendingTimersAsync();

      assertMonthSelectOptions({ maxMonth: "May" });
      expect(yearInput.value).toBe("2027");

      expect(getDateNode("2027-10-07")).toBeNull();
      expect(getDateNode("2027-05-04")).not.toBeNull();
    });

    it("navigate forward a year through year input onto a month/year after maxDate", async () => {
      vi.setSystemTime(new Date("2026-10-10T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-10-15");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-10-15"));
    });

    it("inputting same year doesn't change calendar state", async () => {
      vi.setSystemTime(new Date("2026-05-10T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();
      const yearInput = getYearInput();
      const monthSelect = getMonthSelect();
      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(yearInput.value).toBe("2026");
      expect(monthSelect.value).toBe("May");
      assertCalendarLayout(getMay2026Dates());

      yearInput.value = "2026";
      yearInput.dispatchEvent(new Event("change", { bubbles: true }));
      await vi.runOnlyPendingTimersAsync();
      expect(yearInput.value).toBe("2026");
      expect(monthSelect.value).toBe("May");
      assertCalendarLayout(getMay2026Dates());
    });

    it("selecting disabled date doesn't fill input", async () => {
      vi.setSystemTime(new Date("2026-05-10T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-05-08");
      application = await startController();

      const input = document.getElementById("test_id-input");
      expect(input.value).toBe("");

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      getDateNode("2026-05-01").click();

      expect(input.value).toBe("");

      getDateNode("2026-05-30").click();

      expect(input.value).toBe("2026-05-30");
    });
  });
});
