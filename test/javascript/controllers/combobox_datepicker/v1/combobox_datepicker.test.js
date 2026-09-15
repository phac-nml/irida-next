import { Application } from "@hotwired/stimulus";
import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import FloatingDropdown from "../../../../../app/javascript/utilities/floating_dropdown.js";
import InputController from "../../../../../app/javascript/controllers/combobox_datepicker/v1/input_controller.js";
import CalendarController from "../../../../../app/javascript/controllers/combobox_datepicker/v1/calendar_controller.js";

/* eslint-disable no-useless-escape */
function renderBaseFixture(locale = "en") {
  document.body.innerHTML = `
  <main>
<div id="test_id-datepicker" data-controller="combobox-datepicker--v1--input" data-combobox-datepicker--v1--input-combobox-datepicker--v1--calendar-outlet="#test_id-calendar" data-combobox-datepicker--v1--input-calendar-id-value="test_id-calendar" data-combobox-datepicker--v1--input-date-format-regex-value="^\\\d{4}-\\\d{2}-\\\d{2}$">
  <div aria-live="polite">
    <div>
      <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
        <rect width="256" height="256" fill="none"></rect>
        <rect x="40" y="40" width="176" height="176" rx="8" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></rect>
        <line x1="176" y1="24" x2="176" y2="56" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
        <line x1="80" y1="24" x2="80" y2="56" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
        <line x1="40" y1="88" x2="216" y2="88" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
        <circle cx="128" cy="132" r="12"></circle>
        <circle cx="172" cy="132" r="12"></circle>
        <circle cx="84" cy="172" r="12"></circle>
        <circle cx="128" cy="172" r="12"></circle>
        <circle cx="172" cy="172" r="12"></circle>
      </svg>
    </div>

    <input
      placeholder="YYYY-MM-DD"
      autocomplete="off"
      value=""
      data-combobox-datepicker--v1--input-target="datepickerInput"
      data-action="
        change-&gt;combobox-datepicker--v1--input#handleInputChange
        keydown-&gt;combobox-datepicker--v1--input#handleKeyboardInput
        click-&gt;combobox-datepicker--v1--input#toggleCalendar
      "
      type="text"
      name="test_input_name"
      id="test_id-input"
      role="combobox"
      aria-haspopup="dialog"
      aria-autocomplete="none"
      aria-expanded="true"
      aria-controls="test_id-calendar"
    >

    <div>
      <button
        data-combobox-datepicker--v1--input-target="inputArrow"
        data-action="click-&gt;combobox-datepicker--v1--input#toggleCalendar"
        tabindex="-1"
        type="button"
        aria-label="Choose date"
      >
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
          <rect width="256" height="256" fill="none"></rect>
          <polyline points="208 96 128 176 48 96" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></polyline>
        </svg>
      </button>
    </div>
  </div>

  <template data-combobox-datepicker--v1--input-target="calendarTemplate">
    <div
      id="test_id-calendar"
      hidden="hidden"
      role="dialog"
      aria-modal="true"
      aria-label="Choose date"
      data-controller="combobox-datepicker--v1--calendar"
      data-combobox-datepicker--v1--calendar-combobox-datepicker--v1--input-outlet="#test_id-datepicker"
      data-combobox-datepicker--v1--calendar-months-value="[&quot;January&quot;,&quot;February&quot;,&quot;March&quot;,&quot;April&quot;,&quot;May&quot;,&quot;June&quot;,&quot;July&quot;,&quot;August&quot;,&quot;September&quot;,&quot;October&quot;,&quot;November&quot;,&quot;December&quot;]"
      data-combobox-datepicker--v1--calendar-locale-value="${locale}"
    >
      <div>
        <div>
          <button
            type="button"
            data-action="click-&gt;combobox-datepicker--v1--calendar#previousMonth"
            data-combobox-datepicker--v1--calendar-target="backButton"
            aria-label="Navigate to previous month"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
              <rect width="256" height="256" fill="none"></rect>
              <line x1="216" y1="128" x2="40" y2="128" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
              <polyline points="112 56 40 128 112 200" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></polyline>
            </svg>
          </button>

          <div data-combobox-datepicker--v1--calendar-target="monthSelectContainer"></div>

          <div>
            <input
              data-combobox-datepicker--v1--calendar-target="year"
              data-action="change-&gt;combobox-datepicker--v1--calendar#changeYear"
              type="number"
              autocomplete="off"
              max="9999"
              min="1"
              aria-label="Select year"
              name="year-select"
            >
          </div>

          <button
            type="button"
            data-action="click-&gt;combobox-datepicker--v1--calendar#nextMonth"
            data-combobox-datepicker--v1--calendar-target="forwardButton"
            aria-label="Navigate to next month"
          >
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 256 256">
              <rect width="256" height="256" fill="none"></rect>
              <line x1="40" y1="128" x2="216" y2="128" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></line>
              <polyline points="144 56 216 128 144 200" fill="none" stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="16"></polyline>
            </svg>
          </button>

          <div
            data-combobox-datepicker--v1--calendar-target="headerAriaLive"
            id="test_id-calendar-header"
            aria-live="polite"
          ></div>
        </div>

        <template data-combobox-datepicker--v1--calendar-target="monthSelectTemplate">
          <select
            data-combobox-datepicker--v1--calendar-target="monthSelect"
            data-action="change-&gt;combobox-datepicker--v1--calendar#changeMonth"
            aria-label="Select month"
            name="month-select"
          >
            <option value="January">January</option>
            <option value="February">February</option>
            <option value="March">March</option>
            <option value="April">April</option>
            <option value="May">May</option>
            <option value="June">June</option>
            <option value="July">July</option>
            <option value="August">August</option>
            <option value="September">September</option>
            <option value="October">October</option>
            <option value="November">November</option>
            <option value="December">December</option>
          </select>
        </template>

        <div>
          <table role="grid" aria-label="Calendar" aria-labelledby="test_id-calendar-header">
            <thead>
              <tr>
                <th scope="col" aria-label="Sunday">Sun</th>
                <th scope="col" aria-label="Monday">Mon</th>
                <th scope="col" aria-label="Tuesday">Tue</th>
                <th scope="col" aria-label="Wednesday">Wed</th>
                <th scope="col" aria-label="Thursday">Thu</th>
                <th scope="col" aria-label="Friday">Fri</th>
                <th scope="col" aria-label="Saturday">Sat</th>
              </tr>
            </thead>

            <tbody data-combobox-datepicker--v1--calendar-target="calendar"></tbody>
          </table>
        </div>

        <template data-combobox-datepicker--v1--calendar-target="inMonthDateTemplate">
          <td
            data-date-within-month-position="inMonth"
            data-action="
              keydown-&gt;combobox-datepicker--v1--calendar#navigateCalendar
              click-&gt;combobox-datepicker--v1--calendar#selectDate
            "
            class="
      relative w-8 rounded-lg border-0 text-center text-sm leading-9 font-semibold not-aria-disabled:cursor-pointer
      not-aria-disabled:text-slate-900 not-aria-disabled:hover:bg-slate-100 aria-disabled:cursor-not-allowed
      aria-disabled:text-slate-500 aria-disabled:line-through not-aria-disabled:dark:text-white
      not-aria-disabled:dark:hover:bg-slate-600 aria-disabled:dark:text-slate-300
    "
            role="gridcell"
          ></td>
        </template>

        <template data-combobox-datepicker--v1--calendar-target="outOfMonthDateTemplate">
          <td
            data-date-within-month-position="outOfMonth"
            data-action="
              keydown-&gt;combobox-datepicker--v1--calendar#navigateCalendar
              click-&gt;combobox-datepicker--v1--calendar#selectDate
            "
            class="
              relative w-8 rounded-lg border-0 text-center text-sm leading-9 font-semibold not-aria-disabled:cursor-pointer
              not-aria-disabled:text-slate-500 not-aria-disabled:hover:bg-slate-100 aria-disabled:cursor-not-allowed
              aria-disabled:text-slate-500 aria-disabled:line-through not-aria-disabled:dark:text-slate-300
              not-aria-disabled:dark:hover:bg-slate-600 aria-disabled:dark:text-slate-300
            "
            role="gridcell"
          ></td>
        </template>

        <div>
          <div>
            <button
              type="button"
              data-action="click-&gt;combobox-datepicker--v1--calendar#showToday"
              aria-label="Show today"
            >
              Show Today
            </button>

            <button
              type="button"
              data-action="click-&gt;combobox-datepicker--v1--calendar#clearSelection"
              data-combobox-datepicker--v1--calendar-target="clearButton"
              aria-label="Clear date selection"
            >
              Clear selection
            </button>
          </div>
        </div>
      </div>
    </div>
  </template>
</div>
</main>
`;
}
/* eslint-enable no-useless-escape */

function renderMinDate(date) {
  const datepickerContainer = document.getElementById("test_id-datepicker");
  datepickerContainer.insertAdjacentHTML(
    "afterbegin",
    `
      <div data-combobox-datepicker--v1--input-target="minDate">
        <time datetime="${date}">${date}</time>
      </div>
    `,
  );
}

function renderMaxDate(date) {
  const datepickerContainer = document.getElementById("test_id-datepicker");
  datepickerContainer.insertAdjacentHTML(
    "afterbegin",
    `
      <div data-combobox-datepicker--v1--input-target="maxDate">
        <time datetime="${date}">${date}</time>
      </div>
    `,
  );
}

function getBackButton() {
  return document
    .getElementById("test_id-calendar")
    .querySelector(
      '[data-combobox-datepicker--v1--calendar-target="backButton"]',
    );
}

function getForwardButton() {
  return document
    .getElementById("test_id-calendar")
    .querySelector(
      '[data-combobox-datepicker--v1--calendar-target="forwardButton"]',
    );
}

function getMonthSelect() {
  return document
    .getElementById("test_id-calendar")
    .querySelector(
      '[data-combobox-datepicker--v1--calendar-target="monthSelect"]',
    );
}

function getYearInput() {
  return document
    .getElementById("test_id-calendar")
    .querySelector('[data-combobox-datepicker--v1--calendar-target="year"]');
}

function getDateNode(date) {
  return document
    .getElementById("test_id-calendar")
    .querySelector(`[data-date="${date}"]`);
}

function getApril2026Dates() {
  const expectedApril2026Dates = [
    [
      ["2026-03-29", "outOfMonth"],
      ["2026-03-30", "outOfMonth"],
      ["2026-03-31", "outOfMonth"],
      ["2026-04-01", "inMonth"],
      ["2026-04-02", "inMonth"],
      ["2026-04-03", "inMonth"],
      ["2026-04-04", "inMonth"],
    ],
    [
      ["2026-04-05", "inMonth"],
      ["2026-04-06", "inMonth"],
      ["2026-04-07", "inMonth"],
      ["2026-04-08", "inMonth"],
      ["2026-04-09", "inMonth"],
      ["2026-04-10", "inMonth"],
      ["2026-04-11", "inMonth"],
    ],
    [
      ["2026-04-12", "inMonth"],
      ["2026-04-13", "inMonth"],
      ["2026-04-14", "inMonth"],
      ["2026-04-15", "inMonth"],
      ["2026-04-16", "inMonth"],
      ["2026-04-17", "inMonth"],
      ["2026-04-18", "inMonth"],
    ],
    [
      ["2026-04-19", "inMonth"],
      ["2026-04-20", "inMonth"],
      ["2026-04-21", "inMonth"],
      ["2026-04-22", "inMonth"],
      ["2026-04-23", "inMonth"],
      ["2026-04-24", "inMonth"],
      ["2026-04-25", "inMonth"],
    ],
    [
      ["2026-04-26", "inMonth"],
      ["2026-04-27", "inMonth"],
      ["2026-04-28", "inMonth"],
      ["2026-04-29", "inMonth"],
      ["2026-04-30", "inMonth"],
      ["2026-05-01", "outOfMonth"],
      ["2026-05-02", "outOfMonth"],
    ],
  ];

  return expectedApril2026Dates;
}

function getMay2026Dates() {
  const expectedMay2026Dates = [
    [
      ["2026-04-26", "outOfMonth"],
      ["2026-04-27", "outOfMonth"],
      ["2026-04-28", "outOfMonth"],
      ["2026-04-29", "outOfMonth"],
      ["2026-04-30", "outOfMonth"],
      ["2026-05-01", "inMonth"],
      ["2026-05-02", "inMonth"],
    ],
    [
      ["2026-05-03", "inMonth"],
      ["2026-05-04", "inMonth"],
      ["2026-05-05", "inMonth"],
      ["2026-05-06", "inMonth"],
      ["2026-05-07", "inMonth"],
      ["2026-05-08", "inMonth"],
      ["2026-05-09", "inMonth"],
    ],
    [
      ["2026-05-10", "inMonth"],
      ["2026-05-11", "inMonth"],
      ["2026-05-12", "inMonth"],
      ["2026-05-13", "inMonth"],
      ["2026-05-14", "inMonth"],
      ["2026-05-15", "inMonth"],
      ["2026-05-16", "inMonth"],
    ],
    [
      ["2026-05-17", "inMonth"],
      ["2026-05-18", "inMonth"],
      ["2026-05-19", "inMonth"],
      ["2026-05-20", "inMonth"],
      ["2026-05-21", "inMonth"],
      ["2026-05-22", "inMonth"],
      ["2026-05-23", "inMonth"],
    ],
    [
      ["2026-05-24", "inMonth"],
      ["2026-05-25", "inMonth"],
      ["2026-05-26", "inMonth"],
      ["2026-05-27", "inMonth"],
      ["2026-05-28", "inMonth"],
      ["2026-05-29", "inMonth"],
      ["2026-05-30", "inMonth"],
    ],
    [
      ["2026-05-31", "inMonth"],
      ["2026-06-01", "outOfMonth"],
      ["2026-06-02", "outOfMonth"],
      ["2026-06-03", "outOfMonth"],
      ["2026-06-04", "outOfMonth"],
      ["2026-06-05", "outOfMonth"],
      ["2026-06-06", "outOfMonth"],
    ],
  ];
  return expectedMay2026Dates;
}

function getJune2026Dates() {
  const expectedJune2026Dates = [
    [
      ["2026-05-31", "outOfMonth"],
      ["2026-06-01", "inMonth"],
      ["2026-06-02", "inMonth"],
      ["2026-06-03", "inMonth"],
      ["2026-06-04", "inMonth"],
      ["2026-06-05", "inMonth"],
      ["2026-06-06", "inMonth"],
    ],
    [
      ["2026-06-07", "inMonth"],
      ["2026-06-08", "inMonth"],
      ["2026-06-09", "inMonth"],
      ["2026-06-10", "inMonth"],
      ["2026-06-11", "inMonth"],
      ["2026-06-12", "inMonth"],
      ["2026-06-13", "inMonth"],
    ],
    [
      ["2026-06-14", "inMonth"],
      ["2026-06-15", "inMonth"],
      ["2026-06-16", "inMonth"],
      ["2026-06-17", "inMonth"],
      ["2026-06-18", "inMonth"],
      ["2026-06-19", "inMonth"],
      ["2026-06-20", "inMonth"],
    ],
    [
      ["2026-06-21", "inMonth"],
      ["2026-06-22", "inMonth"],
      ["2026-06-23", "inMonth"],
      ["2026-06-24", "inMonth"],
      ["2026-06-25", "inMonth"],
      ["2026-06-26", "inMonth"],
      ["2026-06-27", "inMonth"],
    ],
    [
      ["2026-06-28", "inMonth"],
      ["2026-06-29", "inMonth"],
      ["2026-06-30", "inMonth"],
      ["2026-07-01", "outOfMonth"],
      ["2026-07-02", "outOfMonth"],
      ["2026-07-03", "outOfMonth"],
      ["2026-07-04", "outOfMonth"],
    ],
  ];

  return expectedJune2026Dates;
}

function assertCalendarLayout(dates, { minDate, maxDate } = {}) {
  const calendar = document.getElementById("test_id-calendar");
  const rows = calendar.querySelectorAll("tbody tr");

  // validates calendar layout (# of rows, date positions, and date styling (inMonth vs outOfMonth))
  expect(rows).toHaveLength(dates.length);

  rows.forEach((row, rowIndex) => {
    const cells = row.querySelectorAll("td");

    expect(cells).toHaveLength(7);
    cells.forEach((cell, cellIndex) => {
      const [date, position] = dates[rowIndex][cellIndex];
      assertCalendarDateNodes(cell, date, position, minDate, maxDate);
    });
  });
}

function assertCalendarDateNodes(
  cell,
  expectedDate,
  expectedPosition,
  minDate = null,
  maxDate = null,
) {
  expect(cell).toHaveAttribute("data-date", expectedDate);
  expect(cell).toHaveAttribute(
    "data-date-within-month-position",
    expectedPosition,
  );

  const expectedClass =
    expectedPosition === "outOfMonth"
      ? "not-aria-disabled:text-slate-500"
      : "not-aria-disabled:text-slate-900";

  expect(cell).toHaveClass(expectedClass);

  if (
    (minDate && expectedDate < minDate) ||
    (maxDate && expectedDate > maxDate)
  ) {
    expect(cell).toHaveAttribute("aria-disabled", "true");
  }
}

function keypressOnDateNode(date, key, shiftKey = false) {
  getDateNode(date).dispatchEvent(
    new KeyboardEvent("keydown", {
      key: key,
      bubbles: true,
      shiftKey: shiftKey,
    }),
  );
}

function openCalendarByInputArrow() {
  document
    .querySelector('[data-combobox-datepicker--v1--input-target="inputArrow"]')
    .click();
}

const months = [
  "January",
  "February",
  "March",
  "April",
  "May",
  "June",
  "July",
  "August",
  "September",
  "October",
  "November",
  "December",
];

function assertMonthSelectOptions({ minMonth, maxMonth } = {}) {
  const monthSelect = getMonthSelect();
  const minIndex = minMonth ? months.indexOf(minMonth) : 0;
  const maxIndex = maxMonth ? months.indexOf(maxMonth) : months.length - 1;

  const expectedMonths = months.slice(minIndex, maxIndex + 1);
  const monthOptions = [...monthSelect.getElementsByTagName("option")];

  expect(monthOptions).toHaveLength(expectedMonths.length);
  expect(monthOptions.map((month) => month.textContent)).toEqual(
    expectedMonths,
  );
}

function inputControllerInstance(app) {
  return app.getControllerForElementAndIdentifier(
    document.querySelector(
      '[data-controller~="combobox-datepicker--v1--input"]',
    ),
    "combobox-datepicker--v1--input",
  );
}

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

    it("basic arrow key navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      getDateNode("2026-05-07").dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "ArrowRight",
          bubbles: true,
          shiftKey: true,
        }),
      );

      expect(document.activeElement).toBe(getDateNode("2026-05-08"));

      getDateNode("2026-05-08").dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "ArrowLeft",
          bubbles: true,
          shiftKey: true,
        }),
      );

      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      getDateNode("2026-05-07").dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "ArrowDown",
          bubbles: true,
          shiftKey: true,
        }),
      );

      expect(document.activeElement).toBe(getDateNode("2026-05-14"));

      getDateNode("2026-05-14").dispatchEvent(
        new KeyboardEvent("keydown", {
          key: "ArrowUp",
          bubbles: true,
          shiftKey: true,
        }),
      );

      expect(document.activeElement).toBe(getDateNode("2026-05-07"));
    });

    it("Home and End navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      keypressOnDateNode("2026-05-07", "End");

      expect(document.activeElement).toBe(getDateNode("2026-05-09"));

      keypressOnDateNode("2026-05-09", "Home");

      expect(document.activeElement).toBe(getDateNode("2026-05-03"));

      // Test bounds of Home/End when part of the week is "outOfMonth"
      getDateNode("2026-05-02").focus();
      keypressOnDateNode("2026-05-02", "Home");

      expect(document.activeElement).toBe(getDateNode("2026-05-01"));

      keypressOnDateNode("2026-05-01", "End");
      expect(document.activeElement).toBe(getDateNode("2026-05-02"));

      getDateNode("2026-05-31").focus();
      keypressOnDateNode("2026-05-31", "End");

      expect(document.activeElement).toBe(getDateNode("2026-05-31"));

      keypressOnDateNode("2026-05-31", "Home");

      expect(document.activeElement).toBe(getDateNode("2026-05-31"));
    });

    it("Page Up and Down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      keypressOnDateNode("2026-05-07", "PageDown");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-06-07"));

      keypressOnDateNode("2026-06-07", "PageUp");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      // tests starting on 31st goes to last day of month of next/previous month that is not 31 (eg: May 31 to June 30)
      getDateNode("2026-05-31").focus();
      keypressOnDateNode("2026-05-31", "PageUp");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-04-30"));

      keypressOnDateNode("2026-04-30", "PageDown");

      await vi.runOnlyPendingTimersAsync();

      getDateNode("2026-05-31").focus();
      keypressOnDateNode("2026-05-31", "PageDown");

      expect(document.activeElement).toBe(getDateNode("2026-06-30"));
    });

    it("Shift Page Up and Down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      keypressOnDateNode("2026-05-07", "PageDown", true);

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2027-05-07"));

      keypressOnDateNode("2027-05-07", "PageUp", true);
      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));
    });

    it("Shift Page Up and Down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      keypressOnDateNode("2026-05-07", "PageDown", true);

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2027-05-07"));

      keypressOnDateNode("2027-05-07", "PageUp", true);
      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));
    });

    it("Page up and down navigation for February edge cases including leap year", async () => {
      vi.setSystemTime(new Date("2028-02-29T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      expect(document.activeElement).toBe(getDateNode("2028-02-29"));
      keypressOnDateNode("2028-02-29", "PageDown");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2028-03-29"));

      keypressOnDateNode("2028-03-29", "ArrowRight");
      keypressOnDateNode("2028-03-30", "PageUp");
      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2028-02-29"));
      keypressOnDateNode("2028-02-29", "PageUp");
      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2028-01-29"));
      keypressOnDateNode("2028-01-29", "ArrowRight");
      keypressOnDateNode("2028-01-30", "PageDown");
      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2028-02-29"));
      keypressOnDateNode("2028-02-29", "PageDown", true);
      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2029-02-28"));
      keypressOnDateNode("2029-02-28", "PageUp", true);
      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2028-02-28"));
      keypressOnDateNode("2028-02-28", "ArrowRight");
      keypressOnDateNode("2028-02-29", "PageUp", true);
      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2027-02-28"));
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

    it("keyboard navigation between Dec and Jan updates year", async () => {
      vi.setSystemTime(new Date("2026-12-31T09:00:00-05:00"));
      renderBaseFixture();
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();

      keypressOnDateNode("2026-12-31", "ArrowRight");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2027-01-01"));
      expect(getMonthSelect().value).toBe("January");
      expect(getYearInput().value).toBe("2027");

      keypressOnDateNode("2027-01-01", "ArrowUp");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-12-25"));
      expect(getMonthSelect().value).toBe("December");
      expect(getYearInput().value).toBe("2026");
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

  describe("default datepicker with min date", () => {
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

    it("Home, End and arrow key navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-05-04");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      keypressOnDateNode("2026-05-07", "ArrowUp");

      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      keypressOnDateNode("2026-05-07", "Home");

      expect(document.activeElement).toBe(getDateNode("2026-05-04"));

      keypressOnDateNode("2026-05-04", "ArrowLeft");

      expect(document.activeElement).toBe(getDateNode("2026-05-04"));

      keypressOnDateNode("2026-05-07", "End");

      expect(document.activeElement).toBe(getDateNode("2026-05-09"));
    });

    it("Page up and down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-05-04");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      keypressOnDateNode("2026-05-07", "PageUp");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      keypressOnDateNode("2026-05-07", "PageDown");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-06-07"));

      getDateNode("2026-06-02").focus();
      keypressOnDateNode("2026-06-02", "PageUp");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-04"));
    });

    it("shift Page up and down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMinDate("2026-05-04");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      keypressOnDateNode("2026-05-07", "PageUp", true);

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      keypressOnDateNode("2026-05-07", "PageDown", true);

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2027-05-07"));

      assertMonthSelectOptions();
      getDateNode("2027-05-02").focus();
      keypressOnDateNode("2027-05-02", "PageUp", true);

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-04"));

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

      keypressOnDateNode("2026-11-01", "ArrowLeft");

      expect(document.activeElement).toBe(getDateNode("2026-11-01"));

      keypressOnDateNode("2026-11-01", "ArrowUp");

      expect(document.activeElement).toBe(getDateNode("2026-11-01"));
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

  describe("default datepicker with max date", () => {
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

    it("Home, End and arrow key navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2026-05-08");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      keypressOnDateNode("2026-05-07", "ArrowDown");

      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      keypressOnDateNode("2026-05-07", "Home");

      expect(document.activeElement).toBe(getDateNode("2026-05-03"));

      keypressOnDateNode("2026-05-03", "End");

      expect(document.activeElement).toBe(getDateNode("2026-05-08"));

      keypressOnDateNode("2026-05-08", "ArrowRight");

      expect(document.activeElement).toBe(getDateNode("2026-05-08"));
    });

    it("Page up and down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2026-05-08");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      keypressOnDateNode("2026-05-07", "PageUp");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-04-07"));

      getDateNode("2026-04-30").focus();
      keypressOnDateNode("2026-04-30", "PageDown");

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-08"));

      keypressOnDateNode("2026-05-08", "PageDown");

      expect(document.activeElement).toBe(getDateNode("2026-05-08"));
    });

    it("shift Page up and down navigation", async () => {
      vi.setSystemTime(new Date("2026-05-07T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2026-05-08");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-07"));

      keypressOnDateNode("2026-05-07", "PageUp", true);

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2025-05-07"));
      getDateNode("2025-05-31").focus();
      keypressOnDateNode("2025-05-31", "PageDown", true);

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-05-08"));

      keypressOnDateNode("2026-05-08", "PageDown", true);

      expect(document.activeElement).toBe(getDateNode("2026-05-08"));
    });

    it("arrow navigation when maxDate is on a Sunday and does not appear on calendar", async () => {
      vi.setSystemTime(new Date("2026-10-31T09:00:00-05:00"));
      renderBaseFixture();
      renderMaxDate("2026-10-31");
      application = await startController();

      openCalendarByInputArrow();

      await vi.runOnlyPendingTimersAsync();
      expect(document.activeElement).toBe(getDateNode("2026-10-31"));

      keypressOnDateNode("2026-10-31", "ArrowRight");

      expect(document.activeElement).toBe(getDateNode("2026-10-31"));

      keypressOnDateNode("2026-10-31", "ArrowDown");

      expect(document.activeElement).toBe(getDateNode("2026-10-31"));
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
  });
});
