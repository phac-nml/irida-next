import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "backButton",
    "month",
    "year",
    "calendar",
    "inMonthDateTemplate",
    "outOfMonthDateTemplate",
    "disabledDateTemplate",
  ];
  static values = {
    minDate: String,
    selectedDate: String,
    months: Array,
  };
  #DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
  #MONTHS = [
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

  #todaysFullDate = new Date();
  #todaysYear = this.#todaysFullDate.getFullYear();
  #todaysMonthIndex = this.#todaysFullDate.getMonth();
  #todaysDate = this.#todaysFullDate.getDate();

  #selectedYear = this.#todaysFullDate.getFullYear();
  #selectedMonthIndex = this.#todaysFullDate.getMonth();

  connect() {
    this.idempotentConnect();
  }

  idempotentConnect() {
    this.#clearCalendar();
    // set the months dropdown in case we're in the year of the minimum date
    this.#setMonths();
    // set the month and year inputs
    this.monthTarget.value = this.#MONTHS[this.#selectedMonthIndex];
    this.yearTarget.value = this.#selectedYear;
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
    if (this.minDateValue) {
      const minDateNode = this.calendarTarget.querySelector(
        `[data-date='${this.minDateValue}']`,
      );
      if (minDateNode) {
        this.backButtonTarget.disabled = true;
      } else {
        this.backButtonTarget.disabled = false;
      }
    }
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
    // disable month's 'back' button if we're on first allowable month
    this.#setBackButton();
  }

  #getPreviousMonthsDates() {
    let firstDayOfMonthIndex = new Date(
      `${this.#selectedYear}, ${this.#MONTHS[this.#selectedMonthIndex]}, 1`,
    ).getDay();
    // if first day lands on Sunday, we don't need to backfill dates
    if (firstDayOfMonthIndex === 0) {
      return [];
    } else {
      let lastDate;
      // check previous month's last date
      if (this.#selectedMonthIndex == 2) {
        lastDate = this.#checkLeapYear() ? 29 : 28;
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
      thisMonthsLastDate = this.#checkLeapYear() ? 29 : 28;
    } else {
      thisMonthsLastDate = this.#DAYS_IN_MONTH[this.#selectedMonthIndex];
    }

    return this.#getDateRange(1, thisMonthsLastDate);
  }

  #getNextMonthsDates(thisMonthsLastDate) {
    let lastDayOfMonthDay = new Date(
      `${this.#selectedYear}, ${this.#MONTHS[this.#selectedMonthIndex]}, ${thisMonthsLastDate}`,
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

  #checkLeapYear() {
    return new Date(this.#selectedYear, 1, 29).getDate() === 29;
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
    // the already selected date
    const selectedDate = this.calendarTarget.querySelector(
      `[data-date='${this.selectedDateValue}']`,
    );
    // today's date
    const todaysDate = this.calendarTarget.querySelector(
      `[data-date='${this.#getFormattedStringDate(this.#todaysYear, this.#todaysMonthIndex, this.#todaysDate)}']`,
    );

    // minimum date where dates prior will be disabled
    const minDate = this.calendarTarget.querySelector(
      `[data-date='${this.minDateValue}']`,
    );

    if (selectedDate) {
      this.#replaceDateStyling(selectedDate, this.#selectedDateClasses);
    }

    // don't need to add 'todaysDate' styling if todaysDate == selectedDate
    if (todaysDate && selectedDate != todaysDate) {
      this.#replaceDateStyling(todaysDate, this.#todaysDateClasses);
    }

    if (minDate) {
      // get all the date nodes within current calendar, and all dates prior the minDate index will be disabled
      const allDates = Array.from(
        this.calendarTarget.querySelectorAll("[data-date]"),
      );
      for (let i = 0; i < allDates.indexOf(minDate); i++) {
        this.#replaceDateStyling(allDates[i], this.#disabledDateClasses);
      }
    }
  }

  #replaceDateStyling(date, classes) {
    if (date.dataset.dateWithinMonthPosition === "inMonth") {
      date.classList.remove(...this.#inMonthClasses);
    } else {
      date.classList.remove(...this.#outOfMonthClasses);
    }
    date.classList.add(...classes);
  }

  previousMonth() {
    this.#selectedMonthIndex =
      this.#selectedMonthIndex == 0 ? 11 : this.#selectedMonthIndex - 1;
    this.monthTarget.value = this.#MONTHS[this.#selectedMonthIndex];

    if (this.#selectedMonthIndex == 11) {
      --this.#selectedYear;
    }
    this.idempotentConnect();
  }

  nextMonth() {
    this.#selectedMonthIndex =
      this.#selectedMonthIndex == 11 ? 0 : this.#selectedMonthIndex + 1;
    this.monthTarget.value = this.#MONTHS[this.#selectedMonthIndex];

    if (this.#selectedMonthIndex == 0) {
      ++this.#selectedYear;
    }
    this.idempotentConnect();
  }

  changeMonth() {
    this.#selectedMonthIndex = this.#MONTHS.indexOf(this.monthTarget.value);
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
}
