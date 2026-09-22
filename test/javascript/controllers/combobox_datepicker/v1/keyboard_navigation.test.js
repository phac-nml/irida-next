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
  openCalendarByInputArrow,
  assertMonthSelectOptions,
  expectKeyboardNavigation,
} from "./test_helpers.js";

async function startController() {
  const application = Application.start();
  application.register("combobox-datepicker--v1--input", InputController);
  application.register("combobox-datepicker--v1--calendar", CalendarController);
  await Promise.resolve();
  return application;
}

describe("combobox_datepicker keyboard navigation testing", () => {
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
    it("Arrow key navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      await expectKeyboardNavigation([
        ["2026-05-07", "2026-05-08", "ArrowRight"],
        ["2026-05-08", "2026-05-07", "ArrowLeft"],
        ["2026-05-07", "2026-05-14", "ArrowDown"],
        ["2026-05-14", "2026-05-07", "ArrowUp"],
      ]);
    });

    it("Home/End navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      await expectKeyboardNavigation([
        ["2026-05-07", "2026-05-09", "End"],
        ["2026-05-09", "2026-05-03", "Home"],
        ["2026-05-02", "2026-05-01", "Home"],
        ["2026-05-01", "2026-05-02", "End"],
      ]);

      getDateNode("2026-05-31").focus();

      await expectKeyboardNavigation([
        ["2026-05-31", "2026-05-31", "End"],
        ["2026-05-31", "2026-05-31", "Home"],
      ]);
    });

    it("Page Up and Down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      await expectKeyboardNavigation([
        ["2026-05-07", "2026-06-07", "PageDown"],
        ["2026-06-07", "2026-05-07", "PageUp"],
      ]);

      getDateNode("2026-05-31").focus();

      await expectKeyboardNavigation([
        ["2026-05-31", "2026-04-30", "PageUp"],
        ["2026-04-30", "2026-05-30", "PageDown"],
        ["2026-05-31", "2026-06-30", "PageDown"],
      ]);
    });

    it("Shift Page Up/Down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      await expectKeyboardNavigation([
        ["2026-05-07", "2027-05-07", "PageDown", true],
        ["2027-05-07", "2026-05-07", "PageUp", true],
      ]);
    });

    it("Page up and down navigation for February edge cases including leap year", async () => {
      vi.setSystemTime(new Date("2028-02-29T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2028-02-29"));

      await expectKeyboardNavigation([
        ["2028-02-29", "2028-03-29", "PageDown"],
        ["2028-03-29", "2028-03-30", "ArrowRight"],
        ["2028-03-30", "2028-02-29", "PageUp"],
        ["2028-02-29", "2028-01-29", "PageUp"],
        ["2028-01-29", "2028-01-30", "ArrowRight"],
        ["2028-01-30", "2028-02-29", "PageDown"],
        ["2028-02-29", "2029-02-28", "PageDown", true],
        ["2029-02-28", "2028-02-28", "PageUp", true],
        ["2028-02-28", "2028-02-29", "ArrowRight"],
        ["2028-02-29", "2027-02-28", "PageUp", true],
      ]);
    });

    it("keyboard navigation between Dec and Jan updates year", async () => {
      vi.setSystemTime(new Date("2026-12-31T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      await expectKeyboardNavigation([
        ["2026-12-31", "2027-01-01", "ArrowRight"],
        ["2027-01-01", "2026-12-25", "ArrowUp"],
      ]);

      expect(getMonthSelect().value).toBe("December");
      expect(getYearInput().value).toBe("2026");
    });

    it("ArrowLeft from 1st of month goes to previous month", async () => {
      vi.setSystemTime(new Date("2026-11-01T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2026-11-01"));

      await expectKeyboardNavigation([
        ["2026-11-01", "2026-10-31", "ArrowLeft"],
      ]);
    });

    it("ArrowDown from last week of month goes to next month", async () => {
      vi.setSystemTime(new Date("2026-11-29T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2026-11-29"));

      await expectKeyboardNavigation([
        ["2026-11-29", "2026-12-06", "ArrowDown"],
      ]);
    });

    it("non-navigation key does not change date focus or calendar state", async () => {
      vi.setSystemTime(new Date("2026-11-29T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2026-11-29"));

      expect(getMonthSelect().value).toBe("November");
      expect(getYearInput().value).toBe("2026");

      await expectKeyboardNavigation([["2026-11-29", "2026-11-29", "a"]]);

      expect(getMonthSelect().value).toBe("November");
      expect(getYearInput().value).toBe("2026");
    });
  });

  describe("default datepicker with min date", () => {
    it("Home, End and arrow key navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-05-04");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      await expectKeyboardNavigation([
        ["2026-05-07", "2026-05-07", "ArrowUp"],
        ["2026-05-07", "2026-05-04", "Home"],
        ["2026-05-04", "2026-05-04", "ArrowLeft"],
      ]);

      getDateNode("2026-05-07").focus();

      await expectKeyboardNavigation([["2026-05-07", "2026-05-09", "End"]]);
    });

    it("Page up and down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-05-04");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      await expectKeyboardNavigation([
        ["2026-05-07", "2026-05-07", "PageUp"],
        ["2026-05-07", "2026-06-07", "PageDown"],
      ]);

      getDateNode("2026-06-02").focus();

      await expectKeyboardNavigation([["2026-06-02", "2026-05-04", "PageUp"]]);
    });

    it("shift Page up and down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-05-04");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      await expectKeyboardNavigation([
        ["2026-05-07", "2026-05-07", "PageUp", true],
        ["2026-05-07", "2027-05-07", "PageDown", true],
      ]);

      assertMonthSelectOptions();

      getDateNode("2027-05-02").focus();

      await expectKeyboardNavigation([
        ["2027-05-02", "2026-05-04", "PageUp", true],
      ]);

      assertMonthSelectOptions({ minMonth: "May" });
    });

    it("arrow navigation when minDate is on a saturday and does not appear on calendar", async () => {
      vi.setSystemTime(new Date("2026-11-01T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-11-01");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      assertMonthSelectOptions({ minMonth: "November" });
      expect(document.activeElement).toBe(getDateNode("2026-11-01"));

      await expectKeyboardNavigation([
        ["2026-11-01", "2026-11-01", "ArrowLeft"],
        ["2026-11-01", "2026-11-01", "ArrowUp"],
      ]);
    });
  });

  describe("datepicker with max date", () => {
    it("Home, End and arrow key navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2026-05-08");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      await expectKeyboardNavigation([
        ["2026-05-07", "2026-05-07", "ArrowDown"],
        ["2026-05-07", "2026-05-03", "Home"],
        ["2026-05-03", "2026-05-08", "End"],
        ["2026-05-08", "2026-05-08", "ArrowRight"],
      ]);
    });

    it("Page up and down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2026-05-08");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      await expectKeyboardNavigation([["2026-05-07", "2026-04-07", "PageUp"]]);

      getDateNode("2026-04-30").focus();

      await expectKeyboardNavigation([
        ["2026-04-30", "2026-05-08", "PageDown"],
        ["2026-05-08", "2026-05-08", "PageDown"],
      ]);
    });

    it("shift Page up and down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2026-05-08");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      await expectKeyboardNavigation([
        ["2026-05-07", "2025-05-07", "PageUp", true],
      ]);

      getDateNode("2025-05-31").focus();

      await expectKeyboardNavigation([
        ["2025-05-31", "2026-05-08", "PageDown", true],
        ["2026-05-08", "2026-05-08", "PageDown", true],
      ]);
    });

    it("arrow navigation when maxDate is on a Sunday and does not appear on calendar", async () => {
      vi.setSystemTime(new Date("2026-10-31T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2026-10-31");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2026-10-31"));

      await expectKeyboardNavigation([
        ["2026-10-31", "2026-10-31", "ArrowRight"],
        ["2026-10-31", "2026-10-31", "ArrowDown"],
      ]);
    });
  });
});
