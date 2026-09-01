import { Application } from "@hotwired/stimulus";
import { beforeEach, afterEach, describe, expect, it, vi } from "vitest";
import InputController from "../../../../../app/javascript/controllers/combobox_datepicker/v1/input_controller.js";
import CalendarController from "../../../../../app/javascript/controllers/combobox_datepicker/v1/calendar_controller.js";
import FloatingDropdown from "../../../../../app/javascript/utilities/floating_dropdown.js";

function renderFixture() {
  document.body.innerHTML = `
  <main>
<div id="test_id-datepicker" data-controller="combobox-datepicker--v1--input" data-combobox-datepicker--v1--input-combobox-datepicker--v1--calendar-outlet="#test_id-calendar" data-combobox-datepicker--v1--input-calendar-id-value="test_id-calendar" data-combobox-datepicker--v1--input-date-format-regex-value="^\d{4}-\d{2}-\d{2}$">
  <div data-combobox-datepicker--v1--input-target="minDate">
  <time datetime="2026-08-30">2026-08-30</time>
</div>

<div data-combobox-datepicker--v1--input-target="maxDate">
  <time datetime="2027-08-30">2027-08-30</time>
</div>

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
      data-combobox-datepicker--v1--calendar-locale-value="en"
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
              max="2027"
              min="2026"
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
  });

  afterEach(() => {
    application?.stop();
    vi.useRealTimers();
  });

  it("combobox_datepicker", async () => {
    renderFixture();
    application = await startController();
    await new Promise((resolve) => setTimeout(resolve, 0));
    // expect(list("available-list")).toHaveAttribute("tabindex", "0");
    // expect(list("available-list")).not.toHaveAttribute("aria-activedescendant");
    // expect(list("selected-list")).not.toHaveAttribute("aria-activedescendant");

    // list("available-list").focus();
    // expect(activeId(list("available-list"))).toBe("available-alpha");

    // list("selected-list").focus();
    // expect(activeId(list("selected-list"))).toBe("selected-two");
  });
});
