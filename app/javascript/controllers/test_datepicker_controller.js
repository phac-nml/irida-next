import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "datepickerInput",
    "backButton",
    "monthsArray",
    "monthSelect",
    "monthSelectContainer",
    "monthSelectTemplate",
    "year",
    "calendar",
    "calendarComponent",
    "calenderTemplate",
    "inMonthDateTemplate",
    "outOfMonthDateTemplate",
    "disabledDateTemplate",
  ];

  static values = {
    minDate: String,
    autosubmit: Boolean,
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
    "dark:text-slate-600",
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
    "dark:text-slate-600",
  ];

  #selectedDate;
  #months;

  // today's date attributes for quick access
  #todaysFullDate = new Date();
  #todaysYear = this.#todaysFullDate.getFullYear();
  #todaysMonthIndex = this.#todaysFullDate.getMonth();
  #todaysDate = this.#todaysFullDate.getDate();
  #todaysFormattedFullDate = `${this.#getFormattedStringDate(this.#todaysYear, this.#todaysMonthIndex, this.#todaysDate)}`;

  // the currently displayed year/month on datepicker
  #selectedYear = this.#todaysYear;
  #selectedMonthIndex = this.#todaysMonthIndex;

  initialize() {
    this.boundAddCalenderTemplate = this.addCalenderTemplate.bind(this);
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this);
    this.boundHandleKeydown = this.handleKeydown.bind(this);
    this.boundHandleDatepickerInputFocusOut =
      this.handleDatepickerInputFocusOut.bind(this);
    this.boundHandleCalendarFocusOut = this.handleCalendarFocusOut.bind(this);
    // Since datepicker controller call is handled outside of the component, rather than having to add a monthsValue,
    // every time the datepicker is called, we'll sneak the months array in via HTML within the component,
    // assign the array to a global var here, and then remove the HTML
    this.#months = JSON.parse(this.monthsArrayTarget.innerHTML);
    this.monthsArrayTarget.remove();

    // Track calendar open state
    this.isCalendarOpen = false;
  }

  connect() {
    this.datepickerInputTarget.addEventListener(
      "focus",
      this.boundAddCalenderTemplate,
    );
    this.datepickerInputTarget.addEventListener(
      "click",
      this.boundAddCalenderTemplate,
    );
  }

  idempotentConnect() {
    // console.log(document.activeElement);
    this.#clearCalendar();
    // set the months dropdown in case we're in the year of the minimum date
    this.#setMonths();
    // set the month and year inputs
    this.monthSelectTarget.value = this.#months[this.#selectedMonthIndex];
    this.yearTarget.value = this.#selectedYear;
    this.#selectedDate = this.datepickerInputTarget.value;
    this.#loadCalendar();
  }

  disconnect() {
    this.datepickerInputTarget.removeEventListener(
      "focus",
      this.boundAddCalenderTemplate,
    );
    this.datepickerInputTarget.removeEventListener(
      "click",
      this.boundAddCalenderTemplate,
    );
    this.removeCalendarListeners();
  }

  addCalenderTemplate(event) {
    console.log(event);
    // Don't add calendar if it's already open
    if (this.isCalendarOpen) return;

    // Add the calendar template to the DOM
    const calendar = this.calenderTemplateTarget.content.cloneNode(true);
    this.element.appendChild(calendar);

    // Position the calendar (implement proper positioning logic here)
    // const inputRect = this.datepickerInputTarget.getBoundingClientRect();
    // this.calendarComponentTarget.style.left = `${inputRect.left}px`;

    // // Calculate if calendar should appear above or below input
    // const spaceBelow = window.innerHeight - inputRect.bottom;
    // const calendarHeight = 300; // Estimate height or calculate from actual rendered element
    // if (spaceBelow < calendarHeight && inputRect.top > calendarHeight) {
    //   // Position above the input if there's not enough space below
    //   this.calendarComponentTarget.style.top = `${inputRect.top - calendarHeight}px`;
    //   // this.calendarComponentTarget.classList.add("datepicker-orient-top");
    //   // this.calendarComponentTarget.classList.remove("datepicker-orient-bottom");
    // } else {
    //   // Position below the input
    //   this.calendarComponentTarget.style.top = `${inputRect.bottom}px`;
    //   // this.calendarComponentTarget.classList.add("datepicker-orient-bottom");
    //   // this.calendarComponentTarget.classList.remove("datepicker-orient-top");
    // }
    this.idempotentConnect();

    // Add global event listeners for outside clicks and keyboard events
    document.addEventListener("click", this.boundHandleOutsideClick);
    document.addEventListener("keydown", this.boundHandleKeydown);
    this.isCalendarOpen = true;

    // Set ARIA attributes for accessibility
    this.datepickerInputTarget.setAttribute("aria-expanded", "true");
    this.calendarComponentTarget.setAttribute("aria-hidden", "false");

    this.datepickerInputTarget.addEventListener(
      "focusout",
      this.boundHandleDatepickerInputFocusOut,
    );
    this.calendarComponentTarget.addEventListener(
      "focusout",
      this.boundHandleCalendarFocusOut,
    );
  }

  handleDatepickerInputFocusOut(event) {
    // timeout allows click/keyboard triggers to occur before focus out triggers, otherwise the focus out will
    // override potential selection triggers
    setTimeout(() => {
      if (!this.isCalendarOpen) return;
      if (
        this.calendarComponentTarget &&
        !this.calendarComponentTarget.contains(event.relatedTarget)
      ) {
        this.closeCalendar();
      }
    }, 50);
  }

  handleCalendarFocusOut(event) {
    // timeout allows click/keyboard triggers to occur before focus out triggers, otherwise the focus out will
    // override potential selection triggers
    setTimeout(() => {
      if (!this.isCalendarOpen) return;
      if (
        !this.calendarComponentTarget.contains(event.relatedTarget) &&
        // !this.calendarComponentTarget.contains(event.target) &&
        !event.target.isEqualNode(this.monthSelectTarget)
      ) {
        this.closeCalendar();
      }
    }, 50);
  }

  // Handle clicks outside the datepicker component
  handleOutsideClick(event) {
    console.log("handle outside click");
    const clickedInsideComponent = this.element.contains(event.target);

    if (!clickedInsideComponent) {
      this.closeCalendar();
    }
  }

  // Close calendar and clean up listeners
  closeCalendar() {
    console.log("close calendar");
    if (!this.isCalendarOpen) return;

    this.removeCalendarListeners();

    if (this.calendarComponentTarget) {
      this.calendarComponentTarget.remove();
    }

    this.isCalendarOpen = false;
    this.datepickerInputTarget.setAttribute("aria-expanded", "false");
  }

  // Remove global event listeners
  removeCalendarListeners() {
    document.removeEventListener("click", this.boundHandleOutsideClick);
    document.removeEventListener("keydown", this.boundHandleKeydown);
  }

  // Handle keyboard events (especially Escape)
  handleKeydown(event) {
    if (event.key === "Escape") {
      this.closeCalendar();
      this.datepickerInputTarget.focus();
    }
  }

  #clearCalendar() {
    this.calendarTarget.innerHTML = "";
  }

  #setMonths() {
    this.monthSelectContainerTarget.innerHTML = "";
    const monthSelectTemplate =
      this.monthSelectTemplateTarget.content.cloneNode(true);
    const monthSelect = monthSelectTemplate.querySelector("select");
    // if 2025 is #selectedYear and minDate = 2025-06-01, we remove Jan -> May from select template and append
    if (this.minDateValue && this.minDateValue.includes(this.#selectedYear)) {
      const minDateMonthIndex = new Date(this.minDateValue).getMonth();
      for (let i = 0; i < minDateMonthIndex; i++) {
        monthSelect.firstElementChild.remove();
      }
    }
    this.monthSelectContainerTarget.appendChild(monthSelect);
  }

  #setBackButton() {
    // if minimum date exists in the current selected month (eg: any previous month should be unselectable)
    // we disable the back button so user can't navigate further back
    this.backButtonTarget.disabled = this.#preventPreviousMonthNavigation();
  }

  #loadCalendar() {
    // fullCalendar will contain all the current month's dates and any previous/next months dates to 'fill-out' the
    // first and last week of dates
    let fullCalendar = [];

    // add last month's dates to fill first week (eg: if the 1st lands on a Tuesday, we'll add Sunday 30th, Monday 31st)
    fullCalendar.push(...this.#getPreviousMonthsDates());
    fullCalendar.push(...this.#getThisMonthsDates());
    fullCalendar.push(
      ...this.#getNextMonthsDates(fullCalendar[fullCalendar.length - 1]),
    );

    this.#fillCalendarWithDates(fullCalendar);

    this.#addStylingToDates();
    // only 1 date is tabbable (either the currently selected date, today's date, or the 1st)
    this.#setTabIndex();
    // disable month's 'back' button if we're on first allowable month
    this.#setBackButton();
  }

  #getPreviousMonthsDates() {
    let firstDayOfMonthIndex = this.#getDayOfWeek(
      `${this.#selectedYear}, ${this.#months[this.#selectedMonthIndex]}, 1`,
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

  // return full range of selected month's dates (1 to last date)
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
      `${this.#selectedYear}, ${this.#months[this.#selectedMonthIndex]}, ${thisMonthsLastDate}`,
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
    // month to add for the 'data-date' attribute
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
        const outOfMonthDate =
          this.outOfMonthDateTemplateTarget.content.cloneNode(true);
        const tableCell = outOfMonthDate.querySelector("td");
        tableCell.innerText = dates[i];
        tableCell.setAttribute(
          "data-date",
          this.#getFormattedStringDate(
            this.#selectedYear,
            this.#getRelativeMonthIndex(relativeMonthPosition),
            dates[i],
          ),
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

  // checks leap year
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
    const minDate = this.#getDateNode(this.minDateValue);

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
    const minDate = this.#getDateNode(this.minDateValue);

    // if minimum date and selected or todays date land on same month/year,
    // prioritize selectedDate > todaysDate > minDate as tabbable

    // else check if selected then todays dates are on the calendar and within the current selected month and year

    // else set the 1st of the month as tab target
    if (minDate) {
      if (selectedDate && this.#selectedDate > this.minDateValue) {
        selectedDate.tabIndex = 0;
      } else if (today && this.#todaysFormattedFullDate > this.minDateValue) {
        today.tabIndex = 0;
      } else {
        minDate.tabIndex = 0;
      }
    } else if (selectedDate && this.#verifyDateIsInMonth(today)) {
      selectedDate.tabIndex = 0;
    } else if (today && this.#verifyDateIsInMonth(today)) {
      today.tabIndex = 0;
    } else {
      this.#getFirstOfMonthNode().tabIndex = 0;
    }
  }

  previousMonth() {
    this.#selectedMonthIndex =
      this.#selectedMonthIndex == 0 ? 11 : this.#selectedMonthIndex - 1;
    this.monthSelectTarget.value = this.#months[this.#selectedMonthIndex];

    if (this.#selectedMonthIndex == 11) {
      --this.#selectedYear;
    }
    this.idempotentConnect();
  }

  nextMonth() {
    this.#selectedMonthIndex =
      this.#selectedMonthIndex == 11 ? 0 : this.#selectedMonthIndex + 1;
    this.monthSelectTarget.value = this.#months[this.#selectedMonthIndex];

    if (this.#selectedMonthIndex == 0) {
      ++this.#selectedYear;
    }
    this.idempotentConnect();
  }

  changeMonth() {
    this.#selectedMonthIndex = this.#months.indexOf(
      this.monthSelectTarget.value,
    );
    this.idempotentConnect();
    this.monthSelectTarget.focus();
  }

  changeYear() {
    // if minDate exists, check if user tried to hard type in a year amount earlier than minDate's year
    if (this.minDateValue) {
      const minDate = new Date(this.minDateValue);
      const minYear = minDate.getFullYear();
      const minMonth = minDate.getMonth();
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

  showToday() {
    this.#selectedYear = this.#todaysYear;
    this.#selectedMonthIndex = this.#todaysMonthIndex;
    this.idempotentConnect();
  }

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

  selectDate(event) {
    console.log("select date");
    console.log(event);
    console.log(event.target);
    this.datepickerInputTarget.value = event.target.getAttribute("data-date");
    console.log(event.target.getAttribute("data-date"));
    if (this.autosubmitValue) {
      this.#submitDate();
    }

    this.closeCalendar();

    this.datepickerInputTarget.focus();
  }

  clearSelection() {
    this.datepickerInputTarget.value = "";

    if (this.autosubmitValue) {
      this.#submitDate();
    }

    this.closeCalendar();
  }

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
      this.minDateValue &&
      this.minDateValue > targetFullDate
    ) {
      return;
    }

    // try to retrieve the target date node, and if the dateNode doesn't exist or is not inMonth,
    // change the month based on direction and re-assign dateNode
    let targetDateNode = this.#getDateNode(targetFullDate);
    if (!this.#verifyDateIsInMonth(targetDateNode)) {
      direction === "left" ? this.previousMonth() : this.nextMonth();
      targetDateNode = this.#getDateNode(targetFullDate);
    }
    this.#focusDate(targetDateNode);
  }

  #handleVerticalNavigation(event, direction) {
    let targetWeek;
    let targetDate;
    const currentWeek = event.target.parentNode;
    let currentDate = parseInt(event.target.innerText);

    if (direction === "up") {
      targetWeek = currentWeek.previousElementSibling;
      targetDate = currentDate - 7;
    } else {
      targetWeek = currentWeek.nextElementSibling;
      targetDate = currentDate + 7;
    }

    const targetFullDate = this.#getFormattedStringDate(
      this.#selectedYear,
      this.#selectedMonthIndex,
      targetDate,
    );

    // if navigating 'up', check if the minimum date is higher than the target date to prevent navigation
    if (
      direction === "up" &&
      this.minDateValue &&
      this.minDateValue > targetFullDate
    ) {
      return;
    }

    // try to retrieve the target date node, and if target week is non-existant (eg: we're going up and we're currently
    // on the first week), or the dateNode doesn't exist or is not inMonth, change the month based on direction and
    // re-assign dateNode
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

    // assign tabindex and focus
    dateNode.tabIndex = 0;
    dateNode.focus();
  }

  #navigateToStart() {
    // if firstDateNode is disabled, means minDate is on the current calendar, and we can focus that (the first
    // node we allow navigation to)
    const firstDateNode = this.#getFirstOfMonthNode();

    if (firstDateNode.getAttribute("data-date-disabled")) {
      this.#focusDate(this.#getDateNode(this.minDateValue));
    } else {
      this.#focusDate(firstDateNode);
    }
  }

  #navigateToEnd() {
    const allInMonthDatesNodes = Array.from(
      this.calendarTarget.querySelectorAll(
        '[data-date-within-month-position="inMonth"]',
      ),
    );

    this.#focusDate(allInMonthDatesNodes[allInMonthDatesNodes.length - 1]);
  }

  #previousMonthByPageUp() {
    if (this.#preventPreviousMonthNavigation()) return;
    this.previousMonth();

    if (this.minDateValue) {
      const minDateNode = this.#getDateNode(this.minDateValue);
      // if there's a minimum date and it exists in the calendar, focus that
      // else focus 1st
      if (minDateNode && this.#verifyDateIsInMonth(minDateNode)) {
        this.#focusDate(minDateNode);
      } else {
        this.#focusDate(this.#getFirstOfMonthNode());
      }
    }
  }

  #nextMonthByPageDown() {
    this.nextMonth();
    this.#focusDate(this.#getFirstOfMonthNode());
  }

  #preventPreviousMonthNavigation() {
    if (this.minDateValue) {
      const minDateNode = this.#getDateNode(this.minDateValue);
      if (
        this.#getDateNode(this.minDateValue) &&
        this.#verifyDateIsInMonth(minDateNode)
      )
        return true;
    } else {
      return false;
    }
  }

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

  inputChange() {
    if (this.autosubmitValue) {
      this.#submitDate();
    }
  }

  #submitDate() {
    this.element.closest("form").requestSubmit();
  }
}
