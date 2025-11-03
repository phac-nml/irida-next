import { Controller } from "@hotwired/stimulus";
import {
  DAYS_IN_MONTH,
  CALENDAR_CLASSES,
} from "controllers/pathogen/datepicker/constants";

import {
  getDayOfWeek,
  verifyDateIsInMonth,
  getDateNode,
  getFirstOfMonthNode,
  parseDate,
} from "controllers/pathogen/datepicker/utils";

export default class extends Controller {
  static outlets = ["pathogen--datepicker--input"];
  static targets = [
    "backButton",
    "monthsArray",
    "monthSelect",
    "monthSelectContainer",
    "monthSelectTemplate",
    "year",
    "calendar",
    "inMonthDateTemplate",
    "outOfMonthDateTemplate",
    "disabledDateTemplate",
    "closeButton",
    "minDateMessage",
    "ariaLive",
  ];

  static values = {
    months: Array,
    ariaControlLabels: Object,
  };

  // today's date attributes for quick access
  #todaysYear;
  #todaysMonthIndex;
  #todaysDate;
  #todaysFormattedFullDate;

  // the currently displayed year/month on datepicker
  #selectedDate;
  #selectedYear;
  #selectedMonthIndex;

  #minDate;
  #minDateMessage;

  idempotentConnect() {
    // set the months dropdown in case we're in the year of the minimum date
    this.setMonths();

    this.#generateCalendarButtonAriaLabel();
    // set the month and year inputs
    this.monthSelectTarget.value = this.monthsValue[this.#selectedMonthIndex];
    this.yearTarget.value = this.#selectedYear;
    if (this.hasMinDateMessageTarget) {
      this.minDateMessageTarget.innerText = this.#minDateMessage;
    }
    this.#loadCalendar();
  }

  setMonths() {
    this.monthSelectContainerTarget.innerHTML = "";
    const monthSelectTemplate =
      this.monthSelectTemplateTarget.content.cloneNode(true);
    const monthSelect = monthSelectTemplate.querySelector("select");
    // if 2025 is #selectedYear and minDate = 2025-06-01, we remove Jan -> May from select template and append
    if (this.#minDate && this.#minDate.includes(this.#selectedYear)) {
      const minDateMonthIndex = new Date(this.#minDate).getUTCMonth();
      for (let i = 0; i < minDateMonthIndex; i++) {
        monthSelect.firstElementChild.remove();
      }
      // if current calendar is Feb 2026 and our minDate is July 2025, if the user clicks 'down' on year input to go to
      // Feb 2025, we need to check that Feb index is less than July index, and if true, set index to July
      if (this.#selectedMonthIndex < minDateMonthIndex) {
        this.#selectedMonthIndex = minDateMonthIndex;
      }
    }
    this.monthSelectContainerTarget.appendChild(monthSelect);
  }

  #generateCalendarButtonAriaLabel() {
    let ariaLabel = "";
    if (this.#selectedDate) {
      let year, month, day;
      [year, month, day] = parseDate(this.#selectedDate);
      ariaLabel = `${this.ariaControlLabelsValue["change_date"]} ${this.monthsValue[month]} ${day}, ${year}`;
    } else {
      ariaLabel = this.ariaControlLabelsValue["choose_date"];
    }

    this.pathogenDatepickerInputOutlet.setCalendarButtonAriaAttributes(
      ariaLabel,
      this.element.id,
    );
  }

  // receive shared params from pathogen/datepicker/input_controller.js upon connection of this controller
  shareParamsWithCalendarByInput(params) {
    this.#todaysYear = params["todaysYear"];
    this.#todaysMonthIndex = params["todaysMonthIndex"];
    this.#todaysDate = params["todaysDate"];
    this.#todaysFormattedFullDate = params["todaysFormattedFullDate"];
    this.#selectedDate = params["selectedDate"];
    this.#selectedYear = params["selectedYear"];
    this.#selectedMonthIndex = params["selectedMonthIndex"];
    this.#minDate = params["minDate"];
    this.#minDateMessage = params["minDateMessage"];
    this.#todaysFormattedFullDate = `${this.#getFormattedStringDate(this.#todaysYear, this.#todaysMonthIndex, this.#todaysDate)}`;
    this.idempotentConnect();
  }

  #loadCalendar() {
    this.calendarTarget.innerHTML = "";
    // fullCalendar will contain all the current month's dates and any previous/next months dates to 'fill-out' the
    // first and last week of dates
    let fullCalendar = [];

    // add last month's dates to fill first week (eg: if the 1st lands on a Tuesday, we'll add Sunday 30th, Monday 31st)
    fullCalendar.push(...this.#getPreviousMonthsDates());
    // get all of this months dates
    fullCalendar.push(...this.#getThisMonthsDates());
    // add all next month's dates to fill out last week of calendar
    fullCalendar.push(
      ...this.#getNextMonthsDates(fullCalendar[fullCalendar.length - 1]),
    );
    this.#fillCalendarWithDates(fullCalendar);

    // style date <td> based on if they're inMonth, outOfMonth, today's date, selected date or disabled due to minDate
    this.#addStylingToDates();
    // only 1 date is tabbable (either the currently selected date, today's date, or the 1st)
    this.#setTabIndex();
    // disable month's 'back' button if we're on first allowable month
    this.#setBackButton();
  }

  #getPreviousMonthsDates() {
    let firstDayOfMonthIndex = getDayOfWeek(
      this.#selectedYear,
      this.#selectedMonthIndex,
      1,
    );

    // if first day lands on Sunday, we don't need to backfill dates
    if (firstDayOfMonthIndex === 0) {
      return [];
    } else {
      let lastDate;
      // check previous month's last date
      if (this.#selectedMonthIndex == 2) {
        lastDate = this.#getFebLastDate(this.#selectedYear);
      } else {
        const previousMonthIndex =
          this.#selectedMonthIndex == 0 ? 11 : this.#selectedMonthIndex - 1;
        lastDate = DAYS_IN_MONTH[previousMonthIndex];
      }

      // add 1 to starting date to offset real date vs index
      return this.#getDateRange(lastDate - firstDayOfMonthIndex + 1, lastDate);
    }
  }

  // return full range of selected month's dates (1st to last date)
  #getThisMonthsDates() {
    let thisMonthsLastDate;

    // if february, check for leap year
    if (this.#selectedMonthIndex == 1) {
      thisMonthsLastDate = this.#getFebLastDate(this.#selectedYear);
    } else {
      thisMonthsLastDate = DAYS_IN_MONTH[this.#selectedMonthIndex];
    }

    return this.#getDateRange(1, thisMonthsLastDate);
  }

  #getNextMonthsDates(thisMonthsLastDate) {
    let lastDayOfMonthDay = getDayOfWeek(
      this.#selectedYear,
      this.#selectedMonthIndex,
      thisMonthsLastDate,
    );

    // if lastDay == 6, last day is on a saturday and we don't need to fill out the rest of the week
    if (lastDayOfMonthDay === 6) {
      return [];
    } else {
      // 6 - lastDay and not 7 because of index offset
      // example: if last date lands on thursday (index = 4), we want 2 more dates (6 - 4), starting from date 1
      return this.#getDateRange(1, 6 - lastDayOfMonthDay);
    }
  }

  /**
   * 🗓️ Fill the calendar grid with table rows and date cells for the given sequence of day numbers.
   *
   * Contract
   * - Input: dates = number[] (length divisible by 7), composed of:
   *   [tail of previous month], [1..last day of current month], [head of next month]
   * - Side effects: Appends <tr> elements with <td> date cells into this.calendarTarget.
   * - Each <td> gets data-date="YYYY-MM-DD" computed against the correct year/month:
   *   previous month, current month, or next month.
   *
   * How it works
   * - 🔎 Find the first 1 (start of current month) and the next 1 (start of next month, if any).
   * - 🧭 Classify each day as prev/current/next via indices—no boolean toggling.
   * - 🧱 Build rows of 7 cells per week to keep the grid predictable and accessible.
   *
   * Edge cases
   * - If the month starts on Sunday, there’s no “previous” tail (first 1 at index 0).
   * - If the month ends on Saturday, there’s no “next” head (no second 1).
   *
   * Accessibility and semantics
   * - We only construct structure here; styling/ARIA states are applied elsewhere.
   * - Rows are appended after every 7 cells to mirror the visual week grid.
   *
   * Input example
   * - For May 2025 starting on Thursday:
   *   dates might look like [27, 28, 29, 30, 1, 2, 3, ..., 31, 1, 2, 3, 4, 5, 6]
   *   → first 1 marks the start of May; the next 1 marks the start of June.
   */
  #fillCalendarWithDates(dates) {
    // 🎯 Identify boundaries between previous/current/next month segments.
    const firstCurrentIdx = dates.indexOf(1); // start of the current month
    const secondOneIdx =
      firstCurrentIdx === -1 ? -1 : dates.indexOf(1, firstCurrentIdx + 1); // start of the next month (if any)

    // 📅 Resolve year/month for out-of-month cells once.
    const prevYM = this.#getRelativeYearAndMonth("previous");
    const nextYM = this.#getRelativeYearAndMonth("next");

    // 🛠️ Helper to render and append a date cell from a <template>.
    const appendCell = (
      row,
      templateTarget,
      year,
      monthIndex,
      day,
      ariaLabel,
    ) => {
      const fragment = templateTarget.content.cloneNode(true);
      const cell = fragment.querySelector("td");
      cell.innerText = day;
      cell.setAttribute(
        "data-date",
        this.#getFormattedStringDate(year, monthIndex, day),
      );
      cell.setAttribute("aria-label", ariaLabel);
      row.appendChild(fragment);
    };

    let row = document.createElement("tr");

    dates.forEach((day, i) => {
      // 🧩 Classify this index into prev/current/next.
      const isPrev = firstCurrentIdx !== -1 && i < firstCurrentIdx;
      const isCurrent =
        firstCurrentIdx !== -1 &&
        (secondOneIdx === -1
          ? i >= firstCurrentIdx
          : i >= firstCurrentIdx && i < secondOneIdx);
      // 👉 If it's neither prev nor current, it's in the "next" segment.

      if (isCurrent) {
        appendCell(
          row,
          this.inMonthDateTemplateTarget,
          this.#selectedYear,
          this.#selectedMonthIndex,
          day,
          `${this.monthsValue[this.#selectedMonthIndex]} ${day}, ${this.#selectedYear}`,
        );
      } else if (isPrev) {
        appendCell(
          row,
          this.outOfMonthDateTemplateTarget,
          prevYM.year,
          prevYM.month,
          day,
          `${this.monthsValue[prevYM.month]} ${day}, ${prevYM.year}`,
        );
      } else {
        appendCell(
          row,
          this.outOfMonthDateTemplateTarget,
          nextYM.year,
          nextYM.month,
          day,
          `${this.monthsValue[nextYM.month]} ${day}, ${nextYM.year}`,
        );
      }

      // 📆 Commit the row every 7 cells to form a full week.
      if ((i + 1) % 7 === 0) {
        this.calendarTarget.append(row);
        row = document.createElement("tr");
      }
    });
  }

  // returns date range
  // if startingDate = 27; endingDate = 30; returns [27, 28, 29, 30]
  #getDateRange = (startingDate, endingDate) => {
    return Array.from(
      { length: (endingDate - startingDate) / 1 + 1 },
      (_, index) => startingDate + index * 1,
    );
  };

  // get February's last date based on leap year
  #getFebLastDate(year) {
    return new Date(year, 1, 29).getDate() === 29 ? 29 : 28;
  }

  #getRelativeYearAndMonth(relativePosition) {
    let year = this.#selectedYear;
    let month = this.#selectedMonthIndex;
    // if relativePosition === 'previous', check if we're in January to pass back December and previous year
    // else pass previous month and same year
    if (relativePosition === "previous") {
      if (this.#selectedMonthIndex === 0) {
        year--;
        month = 11;
        // return { year: this.#selectedYear - 1, month: 11 };
      } else {
        month--;
      }
      // else, check if we're in December, and pass back January and next year, else pass next month and same year
    } else {
      if (this.#selectedMonthIndex === 11) {
        year++;
        month = 0;
      } else {
        month++;
      }
    }
    return { year: year, month: month };
  }

  #getFormattedStringDate(year, monthIndex, date) {
    // new Date will parse monthIndex into correct month (month index == 0 will return january (ie: month 01))
    // ISOString returns YYYY-MM-DDTHH:mm:ss.sssZ, so we split off T as we only want YYYY-MM-DD
    return new Date(year, monthIndex, date).toISOString().split("T")[0];
  }

  #addStylingToDates() {
    // already selected date (if a date selection already exists)
    const selectedDate = getDateNode(this.calendarTarget, this.#selectedDate);
    // today's date
    const today = getDateNode(
      this.calendarTarget,
      this.#todaysFormattedFullDate,
    );

    // minimum date where dates prior will be disabled
    const minDate = getDateNode(this.calendarTarget, this.#minDate);

    if (selectedDate) {
      this.#replaceDateStyling(selectedDate, CALENDAR_CLASSES["SELECTED_DATE"]);
    }

    // don't need to add 'today' styling if today == selectedDate
    if (today && selectedDate != today) {
      this.#replaceDateStyling(today, CALENDAR_CLASSES["TODAYS_DATE"]);
    }

    if (minDate) {
      // get all the date nodes within current calendar, and all dates prior the minDate index will be disabled
      const allDates = Array.from(
        this.calendarTarget.querySelectorAll("[data-date]"),
      );
      for (let i = 0; i < allDates.indexOf(minDate); i++) {
        this.#replaceDateStyling(
          allDates[i],
          CALENDAR_CLASSES["DISABLED_DATE"],
        );
        allDates[i].setAttribute("aria-disabled", true);
      }
      // if minDate and today are on calendar and today is before the minDate, remove the hover classes
      if (today && this.#minDate > this.#todaysFormattedFullDate) {
        today.classList.remove(...CALENDAR_CLASSES["TODAYS_HOVER"]);
      }
    }
  }

  // handles changing the date styling (today, selected and disabled dates)
  #replaceDateStyling(date, classes, removePreviousClasses = null) {
    if (verifyDateIsInMonth(date) && !removePreviousClasses) {
      date.classList.remove(...CALENDAR_CLASSES["IN_MONTH"]);
    } else {
      date.classList.remove(...CALENDAR_CLASSES["OUT_OF_MONTH"]);
    }

    if (removePreviousClasses) {
      date.classList.remove(...removePreviousClasses);
    }
    date.classList.add(...classes);
  }

  // set the tab index to a single date
  #setTabIndex() {
    const today = getDateNode(
      this.calendarTarget,
      this.#todaysFormattedFullDate,
    );
    const selectedDate = getDateNode(this.calendarTarget, this.#selectedDate);
    const minDate = getDateNode(this.calendarTarget, this.#minDate);
    // if minimum date and selected or todays date land on same calendar (year/month),
    // prioritize selectedDate > todaysDate > minDate as tabbable

    // else check if selected then todays dates are on the calendar and within the current selected month and year

    // else set the 1st of the month as tab target
    if (minDate) {
      if (selectedDate && this.#selectedDate > this.#minDate) {
        selectedDate.tabIndex = 0;
      } else if (today && this.#todaysFormattedFullDate > this.#minDate) {
        today.tabIndex = 0;
      } else {
        minDate.tabIndex = 0;
      }
    } else if (selectedDate && verifyDateIsInMonth(selectedDate)) {
      selectedDate.tabIndex = 0;
    } else if (today && verifyDateIsInMonth(today)) {
      today.tabIndex = 0;
    } else {
      getFirstOfMonthNode(this.calendarTarget).tabIndex = 0;
    }
  }

  #setBackButton() {
    const backButton = this.backButtonTarget;
    const backArrow = backButton.firstElementChild;
    // if minimum date exists in the current selected month (eg: any previous month should be unselectable)
    // we disable the back button so user can't navigate further back
    if (this.#preventPreviousMonthNavigation()) {
      backButton.disabled = true;
      backArrow.classList.remove(...CALENDAR_CLASSES["BACK_BUTTON_ENABLED"]);
      backArrow.classList.add(...CALENDAR_CLASSES["BACK_BUTTON_DISABLED"]);
    } else {
      backButton.disabled = false;
      backArrow.classList.add(...CALENDAR_CLASSES["BACK_BUTTON_ENABLED"]);
      backArrow.classList.remove(...CALENDAR_CLASSES["BACK_BUTTON_DISABLED"]);
    }
  }

  // navigate to previous month by back button on calendar
  previousMonth() {
    this.#selectedMonthIndex =
      this.#selectedMonthIndex == 0 ? 11 : this.#selectedMonthIndex - 1;
    this.monthSelectTarget.value = this.monthsValue[this.#selectedMonthIndex];

    if (this.#selectedMonthIndex == 11) {
      --this.#selectedYear;
    }
    this.idempotentConnect();
  }

  // navigate to next month by next button on calendar
  nextMonth() {
    this.#selectedMonthIndex =
      this.#selectedMonthIndex == 11 ? 0 : this.#selectedMonthIndex + 1;
    this.monthSelectTarget.value = this.monthsValue[this.#selectedMonthIndex];

    if (this.#selectedMonthIndex == 0) {
      ++this.#selectedYear;
    }
    this.idempotentConnect();
  }

  // change calendar via month select dropdown
  changeMonth() {
    this.#selectedMonthIndex = this.monthsValue.indexOf(
      this.monthSelectTarget.value,
    );
    this.idempotentConnect();
    this.monthSelectTarget.focus();
  }

  // change year via year input
  changeYear() {
    // if minDate exists, check if user tried to hard type in a year amount earlier than minDate's year
    if (this.#minDate) {
      const minDate = new Date(this.#minDate);
      const minYear = minDate.getFullYear();
      const minMonth = minDate.getUTCMonth();
      if (this.yearTarget.value < minYear) {
        this.yearTarget.value = minYear;
        // if minDate was 2025-06-01 and user was on January 2026 and changes year to 2025, since we don't want
        // January 2025 to be selectable, we want to set the month to June
        if (this.#selectedMonthIndex < minMonth) {
          this.#selectedMonthIndex = minMonth;
        }
      }
    }
    this.#selectedYear = this.yearTarget.value;
    this.idempotentConnect();
  }

  // handles Shift+Tab from first tabbable element to close button (eg: stay within datepicker)
  tabBackToCloseButton(event) {
    if (event.key !== "Tab" || !event.shiftKey) return;
    // if we're on the back button, or on the month select when back button is disabled, tab to the close button
    if (
      event.target === this.backButtonTarget ||
      (event.target === this.monthSelectTarget &&
        this.backButtonTarget.disabled)
    ) {
      event.preventDefault();
      this.closeButtonTarget.focus();
    }
  }

  handleCloseByClick(event) {
    event.preventDefault();
    this.pathogenDatepickerInputOutlet.hideCalendar();
  }

  handleKeydownOnCloseButton(event) {
    // when tabbing from close button, focus first focusable element in datepicker (back button or month select)
    if (event.key === "Tab" && !event.shiftKey) {
      event.preventDefault();
      this.getFirstFocusableElement().focus();
      return;
    }

    if (event.key === " " || event.key === "Enter") {
      event.preventDefault();
      this.pathogenDatepickerInputOutlet.hideCalendar();
      return;
    }
  }

  // handles keyboard inputs on the calendar
  navigateCalendar(event) {
    const handler = this.#getKeyboardHandler(event.key);
    if (handler) {
      if (event.key !== "Tab") event.preventDefault();
      handler.call(this, event);
    }
  }

  #getKeyboardHandler(key) {
    const handlers = {
      " ": this.selectDate.bind(this),
      Enter: this.selectDate.bind(this),
      ArrowLeft: (event) => this.#handleHorizontalNavigation(event, "left"),
      ArrowRight: (event) => this.#handleHorizontalNavigation(event, "right"),
      ArrowUp: (event) => this.#handleVerticalNavigation(event, "up"),
      ArrowDown: (event) => this.#handleVerticalNavigation(event, "down"),
      Home: this.#navigateToStart.bind(this),
      End: this.#navigateToEnd.bind(this),
      PageUp: this.#previousMonthByPageUp.bind(this),
      PageDown: this.#nextMonthByPageDown.bind(this),
    };
    return handlers[key];
  }

  // select date either by click or Enter/Space
  // By click: clicked date is selected and calendar is hidden
  // By keydown: When date is selected, calendar is not closed, and instead the user is able to select date
  // multiple times. Calendar is hidden and selection finalized when they select the close button or Escape out
  selectDate(event) {
    const selectedDate = event.target;
    // return if disabled date is selected (failsafe as they already shouldn't be selectable)
    if (selectedDate.getAttribute("aria-disabled")) return;
    // fill date input value to the selected date
    const selectedDateString = selectedDate.getAttribute("data-date");
    this.pathogenDatepickerInputOutlet.setInputValue(selectedDateString);
    if (event.type === "click") {
      this.pathogenDatepickerInputOutlet.hideCalendar();
    } else if (event.type === "keydown") {
      // move the selected date styling to the current selected date
      this.#removeSelectedDateAttributes();
      this.#replaceDateStyling(selectedDate, CALENDAR_CLASSES["SELECTED_DATE"]);
      this.#selectedDate = selectedDateString;
      this.#generateCalendarButtonAriaLabel();
    }
  }

  // clear selection by clicking clear button
  // datepicker input value is cleared and calendar hidden
  handleClearSelectionByClick() {
    this.pathogenDatepickerInputOutlet.setInputValue("");
    this.pathogenDatepickerInputOutlet.hideCalendar();
  }

  // datepicker input is cleared but calendar remains open
  handleClearSelectionByKeydown(event) {
    if (event.key === "Enter" || event.key === " ") {
      event.preventDefault();
      this.#removeSelectedDateAttributes();
      this.pathogenDatepickerInputOutlet.setInputValue("");
    }
  }

  // when navigating and selecting by keyboard, selected classes will be added to newly selected dates prior to submission
  #removeSelectedDateAttributes() {
    const oldSelectedDate = getDateNode(
      this.calendarTarget,
      this.#selectedDate,
    );
    if (oldSelectedDate) {
      const defaultClasses = verifyDateIsInMonth(oldSelectedDate)
        ? CALENDAR_CLASSES["IN_MONTH"]
        : CALENDAR_CLASSES["OUT_OF_MONTH"];
      this.#replaceDateStyling(
        oldSelectedDate,
        defaultClasses,
        CALENDAR_CLASSES["SELECTED_DATE"],
      );
    }
  }

  // handles ArrowLeft/Right keyboard navigation
  #handleHorizontalNavigation(event, direction) {
    let targetDate;
    let currentDate = parseInt(event.target.innerText);

    if (direction === "left") {
      targetDate = currentDate - 1;
    } else {
      targetDate = currentDate + 1;
    }

    const targetFullDate = this.#getFormattedStringDate(
      this.#selectedYear,
      this.#selectedMonthIndex,
      targetDate,
    );

    // if navigating 'left', check if the minimum date is higher than the target date to prevent navigation
    if (
      direction === "left" &&
      this.#minDate &&
      this.#minDate > targetFullDate
    ) {
      return;
    }

    // try to retrieve the target date node, and if the dateNode doesn't exist or is not inMonth (eg: we're on the 1st
    // and navigating back/Arrowleft), change the month based on direction and re-assign dateNode
    let targetDateNode = getDateNode(this.calendarTarget, targetFullDate);
    if (!verifyDateIsInMonth(targetDateNode)) {
      direction === "left" ? this.previousMonth() : this.nextMonth();
      targetDateNode = getDateNode(this.calendarTarget, targetFullDate);
    }
    this.#focusDate(this.calendarTarget, targetDateNode);
  }

  // handle ArrowUp/Down keyboard navigation
  #handleVerticalNavigation(event, direction) {
    let targetWeek;
    let targetDate;
    const currentWeek = event.target.parentNode;
    let currentDate = parseInt(event.target.innerText);

    // find previous/next week and deduct/add 7 days since we're navigating by week with vertical navigation
    if (direction === "up") {
      targetWeek = currentWeek.previousElementSibling;
      targetDate = currentDate - 7;
    } else {
      targetWeek = currentWeek.nextElementSibling;
      targetDate = currentDate + 7;
    }

    // target date is the date we'd like to 'end' on after keypress0
    const targetFullDate = this.#getFormattedStringDate(
      this.#selectedYear,
      this.#selectedMonthIndex,
      targetDate,
    );

    // if navigating 'up', check if the minimum date is higher than the target date to prevent navigation
    if (direction === "up" && this.#minDate && this.#minDate > targetFullDate) {
      return;
    }

    // try to retrieve the target date node, and if target week is non-existant (eg: we're going up and we're already
    // currently on the first week), or the dateNode doesn't exist or is not inMonth, change the month based on
    // direction and re-assign dateNode
    let targetDateNode = getDateNode(this.calendarTarget, targetFullDate);
    if (!targetWeek || !verifyDateIsInMonth(targetDateNode)) {
      direction === "up" ? this.previousMonth() : this.nextMonth();
      targetDateNode = getDateNode(this.calendarTarget, targetFullDate);
    }
    this.#focusDate(this.calendarTarget, targetDateNode);
  }

  // handles Home keypress
  #navigateToStart() {
    // if firstDateNode is disabled, means minDate is on the current calendar, and we can focus that (the first
    // node we're allowed to navigate to)
    const firstDateNode = getFirstOfMonthNode(this.calendarTarget);

    if (firstDateNode.getAttribute("aria-disabled")) {
      this.#focusDate(
        this.calendarTarget,
        getDateNode(this.calendarTarget, this.#minDate),
      );
    } else {
      this.#focusDate(this.calendarTarget, firstDateNode);
    }
  }

  // handles End keypress
  #navigateToEnd() {
    // get all date nodes that are 'inMonth' and focus the last node
    const allInMonthDatesNodes = Array.from(
      this.calendarTarget.querySelectorAll(
        '[data-date-within-month-position="inMonth"]',
      ),
    );

    this.#focusDate(
      this.calendarTarget,
      allInMonthDatesNodes[allInMonthDatesNodes.length - 1],
    );
  }

  #previousMonthByPageUp() {
    // if we're on the earliest allowed month based on minDate, don't allow us to navigate to the previous month
    if (this.#preventPreviousMonthNavigation()) return;
    // load previous month onto calendar
    this.previousMonth();

    // if minDate exists, check if it's date node is present and focus that, else focus 1st of the month
    if (this.#minDate) {
      const minDateNode = getDateNode(this.calendarTarget, this.#minDate);
      // if there's a minimum date and it exists in the calendar, focus that
      // else focus 1st
      if (minDateNode && verifyDateIsInMonth(minDateNode)) {
        this.#focusDate(this.calendarTarget, minDateNode);
        return;
      }
    }
    this.#focusDate(
      this.calendarTarget,
      getFirstOfMonthNode(this.calendarTarget),
    );
  }

  // load next month and focus 1st of the month
  #nextMonthByPageDown() {
    this.nextMonth();
    this.#focusDate(
      this.calendarTarget,
      getFirstOfMonthNode(this.calendarTarget),
    );
  }

  // check if minDate is currently on calendar, and if so, don't allow navigating to previous month by
  // back button click or Home keypress
  #preventPreviousMonthNavigation() {
    if (this.#minDate) {
      const minDateNode = getDateNode(this.calendarTarget, this.#minDate);
      if (minDateNode && verifyDateIsInMonth(minDateNode)) return true;
    }
    return false;
  }

  // getFirst/LastFocusableElement is used for Tab logic
  getFirstFocusableElement() {
    return this.backButtonTarget.disabled
      ? this.monthSelectTarget
      : this.backButtonTarget;
  }

  // used by input_controller to set focus when datepicker is opened
  setFocusOnTabbableDate() {
    this.calendarTarget.querySelectorAll("[tabindex='0']")[0].focus();
  }

  #focusDate(calendar, dateNode) {
    // find current tabbable node, and remove tabIndex
    const currentTabbableDate = calendar.querySelectorAll('[tabindex="0"]')[0];
    currentTabbableDate.tabIndex = -1;

    // assign tabindex and focus to the current target date
    dateNode.tabIndex = 0;
    dateNode.focus();
    this.ariaLiveTarget.innerText = "";
    this.ariaLiveTarget.innerText = dateNode.getAttribute("aria-label");
  }
}
