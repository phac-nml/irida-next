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
  // static values = { item: String };
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
    this.monthTarget.value = this.#MONTHS[this.#selectedMonthIndex];
    this.yearTarget.value = this.#selectedYear;
    this.#loadCalendar();
  }

  #loadCalendar() {
    let firstWeekLastDate = this.#setupFirstCalendarRow();
    const nextDateToAdd = firstWeekLastDate + 1;
    this.#setupRemainingCalendarForCurrentMonth(nextDateToAdd);

    const lastDayOfMonthDay = new Date(
      `${this.#selectedYear}, ${this.#MONTHS[this.#selectedMonthIndex]}, ${this.#DAYS_IN_MONTH[this.#selectedMonthIndex]}`,
    ).getDay();

    if (lastDayOfMonthDay != 6) {
      this.#addNextMonthDates(lastDayOfMonthDay);
    }

    this.#checkForTodaysDate();
  }

  #setupFirstCalendarRow() {
    const firstDayOfMonthIndex = new Date(
      `${this.#selectedYear}, ${this.#MONTHS[this.#selectedMonthIndex]}, 1`,
    ).getDay();

    const tableRow = document.createElement("tr");
    if (firstDayOfMonthIndex != 0) {
      const lastMonthDaysNumber =
        this.#DAYS_IN_MONTH[
          this.#selectedMonthIndex == 0 ? 11 : this.#selectedMonthIndex - 1
        ];

      for (
        let i = lastMonthDaysNumber - firstDayOfMonthIndex + 1;
        i < lastMonthDaysNumber + 1;
        i++
      ) {
        const outOfMonthDate =
          this.outOfMonthDateTemplateTarget.content.cloneNode(true);
        const tableCell = outOfMonthDate.querySelector("td");
        tableCell.innerText = i;
        tableCell.setAttribute(
          "data-date",
          `${this.#MONTHS[this.#selectedMonthIndex]} ${i}, ${this.#selectedYear}`,
        );
        tableRow.appendChild(outOfMonthDate);
      }
    }

    for (let i = 1; i < 7 - firstDayOfMonthIndex + 1; i++) {
      const inMonthDate =
        this.inMonthDateTemplateTarget.content.cloneNode(true);
      const tableCell = inMonthDate.querySelector("td");
      tableCell.innerText = i;
      tableCell.setAttribute(
        "data-date",
        `${this.#MONTHS[this.#selectedMonthIndex]} ${i}, ${this.#selectedYear}`,
      );
      tableRow.appendChild(inMonthDate);
    }
    this.calendarTarget.appendChild(tableRow);
    return 7 - firstDayOfMonthIndex;
  }

  #setupRemainingCalendarForCurrentMonth(startingDate) {
    let tableRow = document.createElement("tr");
    for (
      let i = startingDate;
      i <= this.#DAYS_IN_MONTH[this.#selectedMonthIndex];
      i++
    ) {
      const inMonthDate =
        this.inMonthDateTemplateTarget.content.cloneNode(true);
      const tableCell = inMonthDate.querySelector("td");
      tableCell.innerText = i;
      tableCell.setAttribute(
        "data-date",
        `${this.#MONTHS[this.#selectedMonthIndex]} ${i}, ${this.#selectedYear}`,
      );

      tableRow.appendChild(inMonthDate);

      if (
        (i - (startingDate - 1)) % 7 == 0 ||
        i == this.#DAYS_IN_MONTH[this.#selectedMonthIndex]
      ) {
        this.calendarTarget.appendChild(tableRow);
        tableRow = document.createElement("tr");
      }
    }
  }

  #addNextMonthDates(leftoverSpace) {
    const lastCalendarRow = this.calendarTarget.lastElementChild;
    for (let i = 1; i < 7 - leftoverSpace; i++) {
      const outOfMonthDate =
        this.outOfMonthDateTemplateTarget.content.cloneNode(true);
      const tableCell = outOfMonthDate.querySelector("td");
      tableCell.innerText = i;
      tableCell.setAttribute(
        "data-date",
        `${this.#MONTHS[this.#selectedMonthIndex + 1]} ${i}, ${this.#selectedYear}`,
      );
      lastCalendarRow.appendChild(outOfMonthDate);
    }
  }

  #checkForTodaysDate() {
    const todaysDate = this.calendarTarget.querySelector(
      `[data-date='${this.#MONTHS[this.#todaysMonthIndex]} ${this.#todaysDate}, ${this.#todaysYear}']`,
    );
    if (todaysDate) {
      todaysDate.classList.add("text-primary-600");
    }
  }

  #clearCalendar() {
    this.calendarTarget.innerHTML = "";
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
