/* eslint-disable no-useless-escape */
export function renderBaseFixture(locale = "en") {
  document.body.innerHTML = `
  <main>
<div id="test_id-datepicker" data-controller="combobox-datepicker--v1--input" data-combobox-datepicker--v1--input-combobox-datepicker--v1--calendar-outlet="#test_id-calendar" data-combobox-datepicker--v1--input-calendar-id-value="test_id-calendar" data-combobox-datepicker--v1--input-date-format-regex-value="^\\\d{4}-\\\d{2}-\\\d{2}$">
  <div aria-live="polite">
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
        <svg>
          Open Arrow Button
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
           <span>Previous Month</span>
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
            <span>Next Month</span>
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
            </button>

            <button
              type="button"
              data-action="click-&gt;combobox-datepicker--v1--calendar#clearSelection"
              data-combobox-datepicker--v1--calendar-target="clearButton"
              aria-label="Clear date selection"
            >
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

export function renderMinDate(date) {
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

export function renderMaxDate(date) {
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

export function getBackButton() {
  return document
    .getElementById("test_id-calendar")
    .querySelector(
      '[data-combobox-datepicker--v1--calendar-target="backButton"]',
    );
}

export function getForwardButton() {
  return document
    .getElementById("test_id-calendar")
    .querySelector(
      '[data-combobox-datepicker--v1--calendar-target="forwardButton"]',
    );
}

export function getMonthSelect() {
  return document
    .getElementById("test_id-calendar")
    .querySelector(
      '[data-combobox-datepicker--v1--calendar-target="monthSelect"]',
    );
}

export function getYearInput() {
  return document
    .getElementById("test_id-calendar")
    .querySelector('[data-combobox-datepicker--v1--calendar-target="year"]');
}

export function getDateNode(date) {
  return document
    .getElementById("test_id-calendar")
    .querySelector(`[data-date="${date}"]`);
}

export function getApril2026Dates() {
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

export function getMay2026Dates() {
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

export function getJune2026Dates() {
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

export function assertCalendarLayout(dates, { minDate, maxDate } = {}) {
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

export function keypressOnDateNode(date, key, shiftKey = false) {
  getDateNode(date).dispatchEvent(
    new KeyboardEvent("keydown", {
      key: key,
      bubbles: true,
      shiftKey: shiftKey,
    }),
  );
}

export function openCalendarByInputArrow() {
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

export function assertMonthSelectOptions({ minMonth, maxMonth } = {}) {
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

export function inputControllerInstance(app) {
  return app.getControllerForElementAndIdentifier(
    document.querySelector(
      '[data-controller~="combobox-datepicker--v1--input"]',
    ),
    "combobox-datepicker--v1--input",
  );
}

export async function expectKeyboardNavigation(steps) {
  for (const [startDate, expectedDate, key, shiftKey = false] of steps) {
    keypressOnDateNode(startDate, key, shiftKey);

    await vi.runOnlyPendingTimersAsync();

    expect(document.activeElement).toBe(getDateNode(expectedDate));
  }
}
