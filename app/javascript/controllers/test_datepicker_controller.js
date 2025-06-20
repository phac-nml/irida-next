import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static targets = [
    "month",
    "year",
    "calendar",
    "inMonthDateTemplate",
    "outOfMonthDateTemplate",
    "disabledDateTemplate",
  ];
  static values = { minDate: String, selectedDate: String };
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
  ];

  #inMonthClasses = [
    "text-slate-900",
    "hover:bg-slate-100",
    "dark:hover:bg-slate-600",
    "dark:text-white",
  ];

  #outOfMonthClasses = [];

  #todaysDateClasses = [];

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
    // set the month and year inputs
    this.monthTarget.value = this.#MONTHS[this.#selectedMonthIndex];
    this.yearTarget.value = this.#selectedYear;
    this.#loadCalendar();
  }

  #clearCalendar() {
    this.calendarTarget.innerHTML = "";
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

    this.#checkForTodaysDateAndSelectedDate();
  }

  #getPreviousMonthsDates() {
    let firstDayOfMonthIndex = new Date(
      `${this.#selectedYear}, ${this.#MONTHS[this.#selectedMonthIndex]}, 1`,
    ).getDay();
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
    // this will flip each time we cross date == 1, so a calendar with 30, 31, 1 -> 30, 1, 2.
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
  // startingDate = 27; endingDate = 30; returns [27, 28, 29, 30]
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

  #checkForTodaysDateAndSelectedDate() {
    const todaysDate = this.calendarTarget.querySelector(
      `[data-date='${this.#getFormattedStringDate(this.#todaysYear, this.#todaysMonthIndex, this.#todaysDate)}']`,
    );
    console.log(this.selectedDateValue);
    const selectedDate = this.calendarTarget.querySelector(
      `[data-date='${this.selectedDateValue}']`,
    );

    // TODO add logic for out of month
    // maybe add data-attribute in/outmonth?
    if (selectedDate) {
      selectedDate.classList.remove(...this.#inMonthClasses);
      selectedDate.classList.add(...this.#selectedDateClasses);
    }

    // add logic for todays date
    // make sure to add logic to check todaysDate = selectedDate
    if (todaysDate) {
    }
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
    this.#selectedYear = this.yearTarget.value;
    this.idempotentConnect();
  }

  showToday() {
    this.#selectedYear = this.#todaysYear;
    this.#selectedMonthIndex = this.#todaysMonthIndex;
    this.idempotentConnect();
  }
}
