import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "datepickerInput",
    "backButton",
    "month",
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
    months: Array,
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

  #todaysFullDate = new Date();
  #todaysYear = this.#todaysFullDate.getFullYear();
  #todaysMonthIndex = this.#todaysFullDate.getMonth();
  #todaysDate = this.#todaysFullDate.getDate();
  #todaysFormattedFullDate = `${this.#getFormattedStringDate(this.#todaysYear, this.#todaysMonthIndex, this.#todaysDate)}`;

  #selectedYear = this.#todaysFullDate.getFullYear();
  #selectedMonthIndex = this.#todaysFullDate.getMonth();

  initialize() {
    this.boundAddCalenderTemplate = this.addCalenderTemplate.bind(this);
    this.boundRemoveCalender = this.removeCalendar.bind(this);
  }

  connect() {
    this.datepickerInputTarget.addEventListener(
      "focus",
      this.boundAddCalenderTemplate,
    );

    // this.datepickerInputTarget.addEventListener(
    //   "focusout",
    //   this.boundRemoveCalender,
    // );
  }

  addCalenderTemplate() {
    console.log();
    const calendar = this.calenderTemplateTarget.content.cloneNode(true);
    this.element.appendChild(calendar);
    const inputWindowPosition =
      this.datepickerInputTarget.getBoundingClientRect();
    // console.log(calendar);
    console.log(this.datepickerInputTarget.getBoundingClientRect());
    // this.calendarComponentTarget.style.left = `${inputWindowPosition.left}px`;
    this.calendarComponentTarget.style.left = `0px`;
    console.log("height");
    console.log(window.innerHeight);
    console.log(inputWindowPosition.top);
    // if (window.innerHeight / inputWindowPosition.top < 2) {
    //   console.log("less than 2");
    //   this.calendarComponentTarget.style.top = `${inputWindowPosition.top + 38}px`;
    // } else {
    //   console.log("more that 2");
    //   this.calendarComponentTarget.style.top = `${inputWindowPosition.top - 150}px`;
    // }
    this.calendarComponentTarget.style.top = `0px`;
    console.log();
    // console.log("offsetY: " + ev.offsetY + " height: " + domRect.height);)
    this.idempotentConnect();
  }

  removeCalendar() {
    if (
      !document.activeElement === this.datepickerInputTarget ||
      !document.activeElement === this.calendarComponentTarget
    );
    console.log(document.activeElement);
    this.calendarComponentTarget.remove();
  }

  idempotentConnect() {
    console.log(document.activeElement);
    this.#clearCalendar();
    // set the months dropdown in case we're in the year of the minimum date
    this.#setMonths();
    // set the month and year inputs
    this.monthTarget.value = this.monthsValue[this.#selectedMonthIndex];
    this.yearTarget.value = this.#selectedYear;
    console.log(this.datepickerInputTarget.value);
    this.#selectedDate = this.datepickerInputTarget.value;
    console.log(this.#selectedDate);
    this.#loadCalendar();
  }

  #clearCalendar() {
    this.calendarTarget.innerHTML = "";
  }

  #setMonths() {
    this.monthTarget.innerHTML = "";
    // if 2025 is #selectedYear and minDate = 2025-06-01, we don't want the dropdown to include Jan -> May
    // else if we're not in minDates year, add all months
    if (this.minDateValue && this.minDateValue.includes(this.#selectedYear)) {
      const minDateMonthIndex = new Date(this.minDateValue).getMonth();
      for (let i = minDateMonthIndex; i < 12; i++) {
        this.monthTarget.appendChild(
          this.#createMonthOption(this.monthsValue[i]),
        );
      }
    } else {
      this.monthsValue.forEach((month) => {
        this.monthTarget.appendChild(this.#createMonthOption(month));
      });
    }
  }

  #createMonthOption(month) {
    let option = document.createElement("option");
    option.value = month;
    option.textContent = month;
    return option;
  }

  #setBackButton() {
    // if minimum date exists in the calendar, we're on the first allowable month and want to prevent user from
    // going to previous months
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
    this.#setTabIndex();
    // disable month's 'back' button if we're on first allowable month
    this.#setBackButton();
  }

  #getPreviousMonthsDates() {
    let firstDayOfMonthIndex = new Date(
      `${this.#selectedYear}, ${this.monthsValue[this.#selectedMonthIndex]}, 1`,
    ).getDay();
    // if first day lands on Sunday, we don't need to backfill dates
    if (firstDayOfMonthIndex === 0) {
      return [];
    } else {
      let lastDate;
      // check previous month's last date
      if (this.#selectedMonthIndex == 2) {
        lastDate = this.#checkLeapYear(this.#selectedYear) ? 29 : 28;
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
      thisMonthsLastDate = this.#checkLeapYear(this.#selectedYear) ? 29 : 28;
    } else {
      thisMonthsLastDate = this.#DAYS_IN_MONTH[this.#selectedMonthIndex];
    }

    return this.#getDateRange(1, thisMonthsLastDate);
  }

  #getNextMonthsDates(thisMonthsLastDate) {
    let lastDayOfMonthDay = new Date(
      `${this.#selectedYear}, ${this.monthsValue[this.#selectedMonthIndex]}, ${thisMonthsLastDate}`,
    ).getDay();

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
    // datesAddedCounter incremented each iteration of forEach loop, so every 7 counts (a week), a new tableRow is
    // created for the calendar table
    let datesAddedCounter = 1;
    let tableRow = document.createElement("tr");
    dates.forEach((date) => {
      if (date === 1) {
        inCurrentMonth = !inCurrentMonth;
        if (!inCurrentMonth) {
          relativeMonthPosition = "next";
        }
      }

      if (inCurrentMonth) {
        const inMonthDate =
          this.inMonthDateTemplateTarget.content.cloneNode(true);
        const tableCell = inMonthDate.querySelector("td");
        tableCell.innerText = date;
        tableCell.setAttribute(
          "data-date",
          this.#getFormattedStringDate(
            this.#selectedYear,
            this.#selectedMonthIndex,
            date,
          ),
        );
        tableRow.appendChild(inMonthDate);
      } else {
        const outOfMonthDate =
          this.outOfMonthDateTemplateTarget.content.cloneNode(true);
        const tableCell = outOfMonthDate.querySelector("td");
        tableCell.innerText = date;
        tableCell.setAttribute(
          "data-date",
          this.#getFormattedStringDate(
            this.#selectedYear,
            this.#getRelativeMonthIndex(relativeMonthPosition),
            date,
          ),
        );
        tableRow.appendChild(outOfMonthDate);
      }

      if (datesAddedCounter % 7 === 0) {
        this.calendarTarget.append(tableRow);
        tableRow = document.createElement("tr");
      }

      ++datesAddedCounter;
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

  #checkLeapYear(year) {
    return new Date(year, 1, 29).getDate() === 29;
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
    const selectedDate = this.calendarTarget.querySelector(
      `[data-date='${this.#selectedDate}']`,
    );
    // today's date
    const today = this.calendarTarget.querySelector(
      `[data-date='${this.#todaysFormattedFullDate}']`,
    );

    // minimum date where dates prior will be disabled
    const minDate = this.calendarTarget.querySelector(
      `[data-date='${this.minDateValue}']`,
    );

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
    const today = this.calendarTarget.querySelector(
      `[data-date='${this.#todaysFormattedFullDate}']`,
    );

    const selectedDate = this.calendarTarget.querySelector(
      `[data-date='${this.#selectedDate}']`,
    );

    const minDate = this.calendarTarget.querySelector(
      `[data-date='${this.minDateValue}']`,
    );

    // if minimum date and selected or todays date land on same month/year, check if todays date is selectable based on minDate
    // and if not, set minDate as tab target

    // else if today (and no minDate), check if today is 'inMonth' and not 'outMonth' (eg: if today is
    // July 31st and we're on Aug, it's possible July 31st still exists on the calendar, but we'd set Aug 1st as
    // tabbable)

    // else set the 1st of the month as tab target
    if (minDate) {
      if (selectedDate && this.#selectedDate > this.minDateValue) {
        selectedDate.tabIndex = 0;
      } else if (today && this.#todaysFormattedFullDate > this.minDateValue) {
        today.tabIndex = 0;
      } else {
        minDate.tabIndex = 0;
      }
    } else if (selectedDate) {
      selectedDate.tabIndex = 0;
    } else if (today) {
      if (
        today.getAttribute("data-date-within-month-position") === "outOfMonth"
      ) {
        this.calendarTarget.querySelector(
          '[data-date-within-month-position="inMonth"]',
        ).tabIndex = 0;
      } else {
        today.tabIndex = 0;
      }
    } else {
      this.calendarTarget.querySelector(
        '[data-date-within-month-position="inMonth"]',
      ).tabIndex = 0;
    }
  }

  previousMonth() {
    this.#selectedMonthIndex =
      this.#selectedMonthIndex == 0 ? 11 : this.#selectedMonthIndex - 1;
    this.monthTarget.value = this.monthsValue[this.#selectedMonthIndex];

    if (this.#selectedMonthIndex == 11) {
      --this.#selectedYear;
    }
    this.idempotentConnect();
  }

  nextMonth() {
    this.#selectedMonthIndex =
      this.#selectedMonthIndex == 11 ? 0 : this.#selectedMonthIndex + 1;
    this.monthTarget.value = this.monthsValue[this.#selectedMonthIndex];

    if (this.#selectedMonthIndex == 0) {
      ++this.#selectedYear;
    }
    this.idempotentConnect();
  }

  changeMonth() {
    this.#selectedMonthIndex = this.monthsValue.indexOf(this.monthTarget.value);
    this.idempotentConnect();
  }

  changeYear() {
    // if minDate exists, check if user tried to hard type in a year amount earlier than minDate's year
    if (this.minDateValue) {
      const minDate = new Date(this.minDateValue);
      const minYear = minDate.getFullYear();
      const minMonth = minDate.getMonth();
      if (this.yearTarget.value <= minYear) {
        this.yearTarget.value = minYear;
        // if minDate was 2025-06-01 and user was on January 2026 and changes year to 2025, we want to set the month
        // to June
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
      PageUp: this.#navigateByPageUp.bind(this),
      PageDown: this.#navigateByPageDown.bind(this),
    };
    return handlers[key];
  }

  selectDate(event) {
    this.datepickerInputTarget.value = event.target.getAttribute("data-date");

    if (this.autosubmitValue) {
      this.element.closest("form").requestSubmit();
    }

    this.calendarComponentTarget.remove();
  }

  #handleHorizontalNavigation(event, direction) {
    if (direction === "left") {
      const previousDate = this.calendarTarget.querySelector(
        `[data-date='${this.#getFormattedStringDate(
          this.#selectedYear,
          this.#selectedMonthIndex,
          parseInt(event.target.innerText) - 1,
        )}']`,
      );
      if (previousDate.getAttribute("data-date-disabled")) return;
      if (this.#verifyDateIsInMonth(previousDate)) {
        this.#focusDate(previousDate);
      } else {
        this.previousMonth();
        const allCalenderInMonthDates = this.calendarTarget.querySelectorAll(
          '[data-date-within-month-position="inMonth"]',
        );
        this.#focusDate(
          allCalenderInMonthDates[allCalenderInMonthDates.length - 1],
        );
      }
    } else {
      const nextDate = this.calendarTarget.querySelector(
        `[data-date='${this.#getFormattedStringDate(
          this.#selectedYear,
          this.#selectedMonthIndex,
          parseInt(event.target.innerText) + 1,
        )}']`,
      );
      if (this.#verifyDateIsInMonth(nextDate)) {
        this.#focusDate(nextDate);
      } else {
        this.nextMonth();
        this.#focusDate(
          this.calendarTarget.querySelector(
            '[data-date-within-month-position="inMonth"]',
          ),
        );
      }
    }
  }

  #handleVerticalNavigation(event, direction) {
    const currentWeekNode = event.target.parentNode;
    const currentDayOfWeekIndex = Array.from(currentWeekNode.children).indexOf(
      event.target,
    );
    if (direction === "up") {
      let previousWeek = currentWeekNode.previousElementSibling;

      const targetDate = this.#getFormattedStringDate(
        this.#selectedYear,
        this.#selectedMonthIndex,
        parseInt(event.target.innerText) - 7,
      );
      if (this.minDateValue && this.minDateValue > targetDate) return;
      if (previousWeek) {
        const targetDay = Array.from(previousWeek.children)[
          currentDayOfWeekIndex
        ];
        if (this.#verifyDateIsInMonth(targetDay)) {
          this.#focusDate(
            Array.from(previousWeek.children)[currentDayOfWeekIndex],
          );
        } else {
          this.#focusOnPreviousMonthChange(currentDayOfWeekIndex);
        }
      } else {
        this.#focusOnPreviousMonthChange(currentDayOfWeekIndex);
      }
    } else {
      let nextWeek = currentWeekNode.nextElementSibling;
      if (nextWeek) {
        const targetDay = Array.from(nextWeek.children)[currentDayOfWeekIndex];
        if (this.#verifyDateIsInMonth(targetDay)) {
          this.#focusDate(Array.from(nextWeek.children)[currentDayOfWeekIndex]);
        } else {
          this.#focusOnNextMonthChange(currentDayOfWeekIndex);
        }
      } else {
        this.#focusOnNextMonthChange(currentDayOfWeekIndex);
      }
    }
  }

  #focusDate(date) {
    const currentTabbableDate =
      this.calendarTarget.querySelectorAll('[tabindex="0"]')[0];
    currentTabbableDate.tabIndex = -1;

    date.tabIndex = 0;
    date.focus();
  }

  #focusOnPreviousMonthChange(index) {
    this.previousMonth();
    let previousWeek = this.calendarTarget.lastElementChild;
    while (true) {
      let targetDay = Array.from(previousWeek.children)[index];
      if (this.#verifyDateIsInMonth(targetDay)) {
        this.#focusDate(targetDay);
        break;
      }
      previousWeek = previousWeek.previousElementSibling;
    }
  }

  #focusOnNextMonthChange(index) {
    this.nextMonth();
    let nextWeek = this.calendarTarget.firstElementChild;
    while (true) {
      let targetDay = Array.from(nextWeek.children)[index];
      if (this.#verifyDateIsInMonth(targetDay)) {
        this.#focusDate(targetDay);
        break;
      }
      nextWeek = nextWeek.nextElementSibling;
    }
  }

  #navigateToStart() {
    const firstDate = this.calendarTarget.querySelector(
      '[data-date-within-month-position="inMonth"]',
    );

    if (firstDate.getAttribute("data-date-disabled")) {
      const allDisabledDates = Array.from(
        this.calendarTarget.querySelectorAll('[data-date-disabled="true"]'),
      );
      console.log(allDisabledDates);
      const lastDisabledDate = allDisabledDates[allDisabledDates.length - 1];
      const targetDate = this.#getFormattedStringDate(
        this.#selectedYear,
        this.#selectedMonthIndex,
        parseInt(lastDisabledDate.innerText) + 1,
      );
      this.#focusDate(
        this.calendarTarget.querySelector(`[data-date='${targetDate}']`),
      );
    } else {
      this.#focusDate(firstDate);
    }
  }

  #navigateToEnd() {
    const allMonthDates = Array.from(
      this.calendarTarget.querySelectorAll(
        '[data-date-within-month-position="inMonth"]',
      ),
    );

    this.#focusDate(allMonthDates[allMonthDates.length - 1]);
  }

  #navigateByPageUp() {
    if (this.#preventPreviousMonthNavigation()) return;
    this.previousMonth();

    if (this.minDateValue) {
      const minDateNode = this.calendarTarget.querySelector(
        `[data-date='${this.minDateValue}']`,
      );

      if (minDateNode && this.#verifyDateIsInMonth(minDateNode)) {
        this.#focusDate(minDateNode);
      } else {
        const firstDateNode = this.calendarTarget.querySelector(
          '[data-date-within-month-position="inMonth"]',
        );
        this.#focusDate(firstDateNode);
      }
    }
  }

  #navigateByPageDown() {
    this.nextMonth();
    this.#focusDate(
      this.calendarTarget.querySelector(
        '[data-date-within-month-position="inMonth"]',
      ),
    );
  }

  #verifyDateIsInMonth(date) {
    return date.getAttribute("data-date-within-month-position") === "inMonth";
  }

  #preventPreviousMonthNavigation() {
    if (this.minDateValue) {
      const minDateNode = this.calendarTarget.querySelector(
        `[data-date='${this.minDateValue}']`,
      );

      if (minDateNode && this.#verifyDateIsInMonth(minDateNode)) return true;
    }
    return false;
  }
}
