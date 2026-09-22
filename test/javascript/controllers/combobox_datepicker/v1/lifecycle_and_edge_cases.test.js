import { Application } from "@hotwired/stimulus";
import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import FloatingDropdown from "../../../../../app/javascript/utilities/floating_dropdown.js";
import InputController from "../../../../../app/javascript/controllers/combobox_datepicker/v1/input_controller.js";
import CalendarController from "../../../../../app/javascript/controllers/combobox_datepicker/v1/calendar_controller.js";
import { renderBaseFixture, inputControllerInstance } from "./test_helpers.js";

async function startController() {
  const application = Application.start();
  application.register("combobox-datepicker--v1--input", InputController);
  application.register("combobox-datepicker--v1--calendar", CalendarController);
  await Promise.resolve();
  return application;
}

describe("combobox_datepicker lifecycle, edge case, and error handling", () => {
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

  describe("error and catch handling", () => {
    it("cleans up listeners and the dropdown on disconnect", async () => {
      renderBaseFixture();
      application = await startController();
      const calendar = document.getElementById("test_id-calendar");
      expect(calendar).toBeTruthy();
      inputControllerInstance(application).disconnect();
      await vi.runOnlyPendingTimersAsync();
      expect(calendar).not.toBeInTheDocument();

      inputControllerInstance(application).disconnect();
    });

    it("logs an error when the calendar cannot be found", async () => {
      const consoleErrorSpy = vi
        .spyOn(console, "error")
        .mockImplementation(() => {});

      vi.spyOn(document, "getElementById").mockImplementation((id) => {
        if (id === "test_id-calendar") return null;

        return document.querySelector(`#${id}`);
      });

      renderBaseFixture();

      application = await startController();
      await vi.runOnlyPendingTimersAsync();

      expect(consoleErrorSpy).toHaveBeenCalledWith(
        "Failed to find calendar after appending to DOM",
      );

      vi.restoreAllMocks();
    });

    it("logs an error when adding the calendar template fails", async () => {
      const consoleErrorSpy = vi
        .spyOn(console, "error")
        .mockImplementation(() => {});

      const error = new Error("Something went wrong");

      renderBaseFixture();

      const template = document.querySelector(
        '[data-combobox-datepicker--v1--input-target="calendarTemplate"]',
      );

      vi.spyOn(template.content, "cloneNode").mockImplementation(() => {
        throw error;
      });

      application = await startController();
      await vi.runOnlyPendingTimersAsync();

      expect(consoleErrorSpy).toHaveBeenCalledWith(
        "Error adding calendar template:",
        error,
      );

      vi.restoreAllMocks();
    });

    it("datepicker within dialog and scrollBy logic", async () => {
      renderBaseFixture();

      const main = document.querySelector("main");
      const datepicker = document.getElementById("test_id-datepicker");

      const dialog = document.createElement("dialog");
      const dialogContents = document.createElement("div");
      dialogContents.className = "dialog--contents";
      dialog.appendChild(dialogContents);
      main.appendChild(dialog);
      dialog.appendChild(datepicker);

      application = await startController();
      await vi.runOnlyPendingTimersAsync();

      const calendar = document.getElementById("test_id-calendar");

      expect(calendar).toBeInTheDocument();
      expect(calendar.parentElement).toBe(dialog);

      // jsdom doesn't calculate layout, so mock the values we need.
      Object.defineProperty(dialog, "offsetHeight", {
        configurable: true,
        value: 500,
      });

      const focusedElement = document.createElement("button");
      calendar.appendChild(focusedElement);

      vi.spyOn(focusedElement, "getBoundingClientRect").mockReturnValue({
        top: 600,
        height: 50,
        bottom: 650,
        left: 0,
        right: 0,
        width: 0,
        x: 0,
        y: 600,
        toJSON: () => {},
      });

      const scrollBy = vi.fn();
      dialogContents.scrollBy = scrollBy;

      const controller = application.getControllerForElementAndIdentifier(
        document.getElementById("test_id-datepicker"),
        "combobox-datepicker--v1--input",
      );

      controller.handleCalendarFocus({
        target: focusedElement,
      });

      await vi.runOnlyPendingTimersAsync(20);

      expect(scrollBy).toHaveBeenCalledWith(0, 600);
    });

    it("does not scroll when focused element is in view", async () => {
      renderBaseFixture();

      const main = document.querySelector("main");
      const datepicker = document.getElementById("test_id-datepicker");

      const dialog = document.createElement("dialog");
      const dialogContents = document.createElement("div");
      dialogContents.className = "dialog--contents";
      dialog.appendChild(dialogContents);
      main.appendChild(dialog);
      dialog.appendChild(datepicker);

      application = await startController();
      await vi.runOnlyPendingTimersAsync();

      const calendar = document.getElementById("test_id-calendar");

      expect(calendar).toBeInTheDocument();
      expect(calendar.parentElement).toBe(dialog);

      // jsdom doesn't calculate layout, so mock the values we need.
      Object.defineProperty(dialog, "offsetHeight", {
        configurable: true,
        value: 500,
      });

      const focusedElement = document.createElement("button");
      calendar.appendChild(focusedElement);

      vi.spyOn(focusedElement, "getBoundingClientRect").mockReturnValue({
        top: 100,
        height: 50,
        bottom: 150,
        left: 0,
        right: 0,
        width: 0,
        x: 0,
        y: 100,
        toJSON: () => {},
      });

      const scrollBy = vi.fn();
      dialogContents.scrollBy = scrollBy;

      const controller = application.getControllerForElementAndIdentifier(
        document.getElementById("test_id-datepicker"),
        "combobox-datepicker--v1--input",
      );

      controller.handleCalendarFocus({
        target: focusedElement,
      });

      await vi.runOnlyPendingTimersAsync(20);

      expect(scrollBy).not.toHaveBeenCalled();
    });

    it("error handling when floatingDropdown hide fails", async () => {
      const error = new Error("Failed to hide dropdown");

      const consoleErrorSpy = vi
        .spyOn(console, "error")
        .mockImplementation(() => {});

      vi.spyOn(FloatingDropdown.prototype, "hide").mockImplementation(() => {
        throw error;
      });

      renderBaseFixture();
      application = await startController();

      await vi.runOnlyPendingTimersAsync();

      const controller = application.getControllerForElementAndIdentifier(
        document.getElementById("test_id-datepicker"),
        "combobox-datepicker--v1--input",
      );

      controller.hideCalendar();

      expect(consoleErrorSpy).toHaveBeenCalledWith(
        "Combobox-Datepicker--V1--InputController error in hideDropdown:",
        error,
      );
    });

    it("input idempotentconnect doesn't append calendar twice", async () => {
      renderBaseFixture();
      application = await startController();

      await vi.runOnlyPendingTimersAsync();

      expect(document.querySelectorAll("#test_id-calendar")).toHaveLength(1);

      inputControllerInstance(application).idempotentConnect();

      expect(document.querySelectorAll("#test_id-calendar")).toHaveLength(1);
    });

    it("hideCalendar is a safe no-op after disconnect", async () => {
      renderBaseFixture();
      application = await startController();
      await vi.runOnlyPendingTimersAsync();

      const controller = inputControllerInstance(application);
      controller.disconnect();

      // #floatingDropdown is now null; hideCalendar should not throw.
      expect(() => controller.hideCalendar()).not.toThrow();
    });
  });
});
