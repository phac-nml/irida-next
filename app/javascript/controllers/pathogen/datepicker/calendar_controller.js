import { Controller } from "@hotwired/stimulus";

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
    "clearButton",
  ];

  static values = {
    months: Array,
  };

  #DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  #selectedDateClasses = [
    "bg-primary-700",
    "text-white",
    "hover:bg-primary-800",
    "dark:text-white",
    "dark:bg-primary-600",
    "dark:hover:bg-primary-700",
    "dark:border-primary-900",
    "dark:hover:bg-primary-700",
    "cursor-pointer",
  ];

  #inMonthClasses = [
    "text-slate-900",
    "hover:bg-slate-100",
    "dark:hover:bg-slate-600",
    "dark:text-white",
    "cursor-pointer",
  ];

  #outOfMonthClasses = [
    "hover:bg-slate-100",
    "dark:hover:bg-slate-600",
    "text-slate-500",
    "dark:text-slate-300",
    "cursor-pointer",
  ];

  #todaysDateClasses = [
    "text-primary-700",
    "bg-slate-100",
    "hover:bg-slate-200",
    "dark:bg-slate-600",
    "dark:hover:bg-slate-500",
    "dark:text-primary-300",
    "cursor-pointer",
  ];

  #disabledDateClasses = [
    "line-through",
    "cursor-not-allowed",
    "text-slate-500",
    "dark:text-slate-300",
  ];

  #backButtonDisabledClasses = ["text-slate-400", "dark:text-slate-500"];
  #backButtonEnabledClasses = ["text-slate-900", "dark:text-slate-100"];

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
  #autosubmit;

  idempotentConnect() {
    // set the months dropdown in case we're in the year of the minimum date
    this.setMonths();
    // set the month and year inputs
    this.monthSelectTarget.value = this.monthsValue[this.#selectedMonthIndex];
    this.yearTarget.value = this.#selectedYear;
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

  // receive shared params from pathogen/datepicker/input_controller.js upon connection of this controller
  initializeCalendarByInput(params) {
    this.#todaysYear = params["todaysYear"];
    this.#todaysMonthIndex = params["todaysMonthIndex"];
    this.#todaysDate = params["todaysDate"];
    this.#todaysFormattedFullDate = params["todaysFormattedFullDate"];
    this.#selectedDate = params["selectedDate"];
    this.#selectedYear = params["selectedYear"];
    this.#selectedMonthIndex = params["selectedMonthIndex"];
    this.#minDate = params["minDate"];
    this.#autosubmit = params["autosubmit"];
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
    let firstDayOfMonthIndex = this.#getDayOfWeek(
      `${this.#selectedYear}, ${this.monthsValue[this.#selectedMonthIndex]}, 1`,
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
        lastDate = this.#DAYS_IN_MONTH[previousMonthIndex];
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
      thisMonthsLastDate = this.#DAYS_IN_MONTH[this.#selectedMonthIndex];
    }

    return this.#getDateRange(1, thisMonthsLastDate);
  }

  #getNextMonthsDates(thisMonthsLastDate) {
    let lastDayOfMonthDay = this.#getDayOfWeek(
      `${this.#selectedYear}, ${this.monthsValue[this.#selectedMonthIndex]}, ${thisMonthsLastDate}`,
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

  #fillCalendarWithDates(dates) {
    // inCurrentMonth checks which styling of date to use; false = faded text; true = 'normal' text;
    // this will flip each time we cross date == 1, so a calendar with 30, 31, 1...30, 1, 2.
    // Flip to true at first 1st (inCurrentMonth == true); flip back at next 1st (inCurrentMonth == false)
    let inCurrentMonth = false;
    // relativeMonthPosition flips from previous to next based on similar logic to inCurrentMonth, so we know which
    // month/year to add for the 'data-date' attribute
    let relativeMonthPosition = "previous";
    let tableRow = document.createElement("tr");

    for (let i = 0; i < dates.length; i++) {
      if (dates[i] === 1) {
        inCurrentMonth = !inCurrentMonth;
        if (!inCurrentMonth) {
          relativeMonthPosition = "next";
        }
      }

      if (inCurrentMonth) {
        const inMonthDate =
          this.inMonthDateTemplateTarget.content.cloneNode(true);
        const tableCell = inMonthDate.querySelector("td");
        tableCell.innerText = dates[i];
        tableCell.setAttribute(
          "data-date",
          this.#getFormattedStringDate(
            this.#selectedYear,
            this.#selectedMonthIndex,
            dates[i],
          ),
        );
        tableRow.appendChild(inMonthDate);
      } else {
        // set year to the current selected year. if month is jan (index == 0) or dec (index == 11), we need to set
        // year back or forward, respectively, dependent on the relativeMonthPosition (before or after)
        let year = this.#selectedYear;
        const relativeMonthIndex = this.#getRelativeMonthIndex(
          relativeMonthPosition,
        );
        if (relativeMonthIndex === 0) {
          year++;
        } else if (relativeMonthIndex === 11) {
          year--;
        }

        const outOfMonthDate =
          this.outOfMonthDateTemplateTarget.content.cloneNode(true);
        const tableCell = outOfMonthDate.querySelector("td");
        tableCell.innerText = dates[i];

        tableCell.setAttribute(
          "data-date",
          this.#getFormattedStringDate(year, relativeMonthIndex, dates[i]),
        );
        tableRow.appendChild(outOfMonthDate);
      }

      // i is offset by 1 so we add 1 to check if we've done a full week
      if ((i + 1) % 7 === 0) {
        this.calendarTarget.append(tableRow);
        tableRow = document.createElement("tr");
      }
    }
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

  #getRelativeMonthIndex(relativePosition) {
    // if relativePosition === 'previous', check if we're in January to pass back December, else pass previous month
    if (relativePosition === "previous") {
      if (this.#selectedMonthIndex === 0) {
        return 11;
      } else {
        return this.#selectedMonthIndex - 1;
      }
      //  else, check if we're in December, and pass back January, else pass next month
    } else {
      if (this.#selectedMonthIndex === 11) {
        return 0;
      } else {
        return this.#selectedMonthIndex + 1;
      }
    }
  }

  #getFormattedStringDate(year, monthIndex, date) {
    // new Date will parse monthIndex into correct month (month index == 0 will return january (ie: month 01))
    // ISOString returns YYYY-MM-DDTHH:mm:ss.sssZ, so we split off T as we only want YYYY-MM-DD
    return new Date(year, monthIndex, date).toISOString().split("T")[0];
  }

  #addStylingToDates() {
    // already selected date (if a date selection already exists)
    const selectedDate = this.#getDateNode(this.#selectedDate);
    // today's date
    const today = this.#getDateNode(this.#todaysFormattedFullDate);

    // minimum date where dates prior will be disabled
    const minDate = this.#getDateNode(this.#minDate);

    if (selectedDate) {
      this.#replaceDateStyling(selectedDate, this.#selectedDateClasses);
    }

    // don't need to add 'today' styling if today == selectedDate
    if (today && selectedDate != today) {
      this.#replaceDateStyling(today, this.#todaysDateClasses);
    }

    if (minDate) {
      // get all the date nodes within current calendar, and all dates prior the minDate index will be disabled
      const allDates = Array.from(
        this.calendarTarget.querySelectorAll("[data-date]"),
      );
      for (let i = 0; i < allDates.indexOf(minDate); i++) {
        this.#replaceDateStyling(allDates[i], this.#disabledDateClasses);
        allDates[i].setAttribute("data-date-disabled", true);
      }
    }
  }

  // handles changing the date styling (today, selected and disabled dates)
  #replaceDateStyling(date, classes) {
    if (this.#verifyDateIsInMonth(date)) {
      date.classList.remove(...this.#inMonthClasses);
    } else {
      date.classList.remove(...this.#outOfMonthClasses);
    }
    date.classList.add(...classes);
  }

  // set the tab index to a single date
  #setTabIndex() {
    const today = this.#getDateNode(this.#todaysFormattedFullDate);
    const selectedDate = this.#getDateNode(this.#selectedDate);
    const minDate = this.#getDateNode(this.#minDate);
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
    } else if (selectedDate && this.#verifyDateIsInMonth(selectedDate)) {
      selectedDate.tabIndex = 0;
    } else if (today && this.#verifyDateIsInMonth(today)) {
      today.tabIndex = 0;
    } else {
      this.#getFirstOfMonthNode().tabIndex = 0;
    }
  }

  #setBackButton() {
    const backButton = this.backButtonTarget;
    const backArrow = backButton.firstElementChild;
    // if minimum date exists in the current selected month (eg: any previous month should be unselectable)
    // we disable the back button so user can't navigate further back
    if (this.#preventPreviousMonthNavigation()) {
      backButton.disabled = true;
      backArrow.classList.remove(...this.#backButtonEnabledClasses);
      backArrow.classList.add(...this.#backButtonDisabledClasses);
    } else {
      backButton.disabled = false;
      backArrow.classList.add(...this.#backButtonEnabledClasses);
      backArrow.classList.remove(...this.#backButtonDisabledClasses);
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

  // show today on calendar via show today button
  showToday() {
    this.#selectedYear = this.#todaysYear;
    this.#selectedMonthIndex = this.#todaysMonthIndex;
    this.idempotentConnect();
  }

  // handles Shift+Tab out of calendar into datepicker input
  tabBackToInput(event) {
    if (event.key !== "Tab" || !event.shiftKey) return;
    // if we're on the back button, or on the month select when back button is disabled, tab to the datepicker input
    if (
      event.target === this.backButtonTarget ||
      (event.target === this.monthSelectTarget &&
        this.backButtonTarget.disabled)
    ) {
      event.preventDefault();
      this.pathogenDatepickerInputOutlet.focusDatepickerInput();
      this.pathogenDatepickerInputOutlet.hideCalendar();
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
  selectDate(event) {
    const selectedDate = event.target;
    // return if disabled date is selected (failsafe as they already shouldn't be selectable)
    if (selectedDate.getAttribute("data-date-disabled")) return;
    // fill date input value to the selected date
    this.pathogenDatepickerInputOutlet.setInputValue(
      selectedDate.getAttribute("data-date"),
    );

    // submit upon click/keyboard interaction if autosubmit is true (ie: on member/group tables)
    if (this.#autosubmit) {
      this.pathogenDatepickerInputOutlet.submitDate();
    }

    this.pathogenDatepickerInputOutlet.hideCalendar();
  }

  // clear selection by clicking clear button
  clearSelection() {
    this.pathogenDatepickerInputOutlet.setInputValue("");

    if (this.#autosubmit) {
      this.pathogenDatepickerInputOutlet.submitDate();
    }

    this.pathogenDatepickerInputOutlet.hideCalendar();
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
    let targetDateNode = this.#getDateNode(targetFullDate);
    if (!this.#verifyDateIsInMonth(targetDateNode)) {
      direction === "left" ? this.previousMonth() : this.nextMonth();
      targetDateNode = this.#getDateNode(targetFullDate);
    }
    this.#focusDate(targetDateNode);
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
    let targetDateNode = this.#getDateNode(targetFullDate);
    if (!targetWeek || !this.#verifyDateIsInMonth(targetDateNode)) {
      direction === "up" ? this.previousMonth() : this.nextMonth();
      targetDateNode = this.#getDateNode(targetFullDate);
    }
    this.#focusDate(targetDateNode);
  }

  #focusDate(dateNode) {
    // find current tabbable node, and remove tabIndex
    const currentTabbableDate =
      this.calendarTarget.querySelectorAll('[tabindex="0"]')[0];
    currentTabbableDate.tabIndex = -1;

    // assign tabindex and focus to the current target date
    dateNode.tabIndex = 0;
    dateNode.focus();
  }

  // handles Home keypress
  #navigateToStart() {
    // if firstDateNode is disabled, means minDate is on the current calendar, and we can focus that (the first
    // node we're allowed to navigate to)
    const firstDateNode = this.#getFirstOfMonthNode();

    if (firstDateNode.getAttribute("data-date-disabled")) {
      this.#focusDate(this.#getDateNode(this.#minDate));
    } else {
      this.#focusDate(firstDateNode);
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

    this.#focusDate(allInMonthDatesNodes[allInMonthDatesNodes.length - 1]);
  }

  #previousMonthByPageUp() {
    // if we're on the earliest allowed month based on minDate, don't allow us to navigate to the previous month
    if (this.#preventPreviousMonthNavigation()) return;
    // load previous month onto calendar
    this.previousMonth();

    // if minDate exists, check if it's date node is present and focus that, else focus 1st of the month
    if (this.#minDate) {
      const minDateNode = this.#getDateNode(this.#minDate);
      // if there's a minimum date and it exists in the calendar, focus that
      // else focus 1st
      if (minDateNode && this.#verifyDateIsInMonth(minDateNode)) {
        this.#focusDate(minDateNode);
        return;
      }
    }
    this.#focusDate(this.#getFirstOfMonthNode());
  }

  // load next month and focus 1st of the month
  #nextMonthByPageDown() {
    this.nextMonth();
    this.#focusDate(this.#getFirstOfMonthNode());
  }

  // check if minDate is currently on calendar, and if so, don't allow navigating to previous month by
  // back button click or Home keypress
  #preventPreviousMonthNavigation() {
    if (this.#minDate) {
      const minDateNode = this.#getDateNode(this.#minDate);
      if (
        this.#getDateNode(this.#minDate) &&
        this.#verifyDateIsInMonth(minDateNode)
      )
        return true;
    }
    return false;
  }

  // check if date is inMonth (eg: if calendar is on July but contains June 30, June 30 is 'outOfMonth')
  #verifyDateIsInMonth(node) {
    return node.getAttribute("data-date-within-month-position") === "inMonth";
  }

  #getDayOfWeek(date) {
    return new Date(date).getDay();
  }

  #getDateNode(date) {
    return this.calendarTarget.querySelector(`[data-date='${date}']`);
  }

  #getFirstOfMonthNode() {
    return this.calendarTarget.querySelector(
      '[data-date-within-month-position="inMonth"]',
    );
  }

  // getFirst/LastFocussableElement is used by pathogen/datepicker/input_controller.js for Tab logic
  getFirstFocussableElement() {
    return this.backButtonTarget.disabled
      ? this.monthSelectTarget
      : this.backButtonTarget;
  }

  getLastFocussableElement() {
    return this.clearButtonTarget;
  }
}
