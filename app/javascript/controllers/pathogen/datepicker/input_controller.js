import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static outlets = ["pathogen--datepicker--calendar"];
  static targets = ["datepickerInput", "calenderTemplate", "inputError"];

  static values = {
    minDate: String,
    autosubmit: Boolean,
    calendarId: String,
    invalidDate: String,
    invalidMinDate: String,
  };

  #formattedDateRegex = /^\d{4}-\d{2}-\d{2}$/;
  #focussableElements =
    'a:not([disabled]), button:not([disabled]), input:not([disabled]):not([type="hidden"]), [tabindex]:not([disabled]):not([tabindex="-1"]), select:not([disabled])';
  // today's date attributes for quick access
  #todaysFullDate = new Date();
  #todaysYear = this.#todaysFullDate.getFullYear();
  #todaysMonthIndex = this.#todaysFullDate.getMonth();
  #todaysDate = this.#todaysFullDate.getDate();

  // the currently displayed year/month on datepicker
  #selectedDate;
  #selectedYear;
  #selectedMonthIndex;

  // calendar DOM element once appended
  #calendar;
  // retrieves next focussable element in DOM after date input
  #nextFocussableElementAfterInput;

  // tracks calendar open state
  #isCalendarOpen = false;
  // positioning of datepicker pop-up differs in a dialog
  #inDialog = false;

  initialize() {
    this.boundUnhideCalendar = this.unhideCalendar.bind(this);
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this);
    this.boundHandleGlobalKeydown = this.handleGlobalKeydown.bind(this);

    // when a turbo response occurs (such as adding new member/group), this initialize will trigger but the
    // calendar will already exist and doesn't need to be added, except for the newly added member/group
    if (!this.#calendar) {
      this.idempotentConnect();
      this.#addCalenderTemplate();
    }
  }

  idempotentConnect() {
    // the currently selected date will be displayed on the initial calendar
    this.#setSelectedDate();
    this.datepickerInputTarget.addEventListener(
      "focus",
      this.boundUnhideCalendar,
    );
    this.datepickerInputTarget.addEventListener(
      "click",
      this.boundUnhideCalendar,
    );

    this.#findNextFocussableElement();
  }

  disconnect() {
    this.datepickerInputTarget.removeEventListener(
      "focus",
      this.boundUnhideCalendar,
    );
    this.datepickerInputTarget.removeEventListener(
      "click",
      this.boundUnhideCalendar,
    );
    this.removeCalendarListeners();
  }

  #addCalenderTemplate() {
    // Don't add calendar if it's already open
    if (this.#isCalendarOpen) return;

    // Add the calendar template to the DOM
    const calendar = this.calenderTemplateTarget.content.cloneNode(true);
    const containerNode = this.#findCalendarContainer();
    containerNode.appendChild(calendar);
    // requery calendar so we can manipulate it later. Must use getElementById as target is outside of this controller's
    // scope, and using something like lastElementChild does not work with turbo-stream (eg: members/group-link tables)
    this.#calendar = document.getElementById(this.calendarIdValue);
  }

  #setSelectedDate() {
    this.#selectedDate = this.datepickerInputTarget.value;
    if (this.#selectedDate) {
      const fullSelectedDate = new Date(this.#selectedDate);
      this.#selectedYear = fullSelectedDate.getUTCFullYear();
      // Sometimes an issue where selecting the 1st will display the previous month with the 1st as an
      // 'outOfMonth' date (eg: selected Sept 1st, but August is displayed with Sept 1st at the end of calendar)
      this.#selectedMonthIndex = fullSelectedDate.getUTCMonth();
    } else {
      this.#selectedYear = this.#todaysYear;
      this.#selectedMonthIndex = this.#todaysMonthIndex;
    }
  }

  // because the calendar is appended as the last element, tab logic needs to be altered as a user would expect after
  // tabbing through the calendar, we'd focus on the next element after the date input
  #findNextFocussableElement() {
    const focussable = Array.from(
      document.body.querySelectorAll(this.#focussableElements),
    );
    let index = focussable.indexOf(this.datepickerInputTarget);
    this.#nextFocussableElementAfterInput = focussable[index + 1];
  }

  // append datepicker to dialog if in dialog, otherwise append to body
  #findCalendarContainer() {
    let nextParentElement = this.datepickerInputTarget.parentNode;
    while (nextParentElement.tagName !== "BODY") {
      if (nextParentElement.tagName === "DIALOG") {
        this.#inDialog = true;
        return nextParentElement;
      }
      nextParentElement = nextParentElement.parentNode;
    }
    return document.body;
  }

  // once the calendar controller connects, share values used by both controllers
  pathogenDatepickerCalendarOutletConnected() {
    this.#initializeCalendar();
  }

  unhideCalendar() {
    if (this.#isCalendarOpen) return;
    // Position the calendar
    this.#positionCalendar();

    this.#calendar.classList.remove("hidden");
    this.#isCalendarOpen = true;
    // Set ARIA attributes for accessibility
    this.datepickerInputTarget.setAttribute("aria-expanded", "true");
    this.#calendar.setAttribute("aria-hidden", "false");

    // // Add global event listeners for outside clicks and keyboard events
    document.addEventListener("click", this.boundHandleOutsideClick);
    document.addEventListener("keydown", this.boundHandleGlobalKeydown);
  }

  #positionCalendar() {
    const inputRect = this.datepickerInputTarget.getBoundingClientRect();

    let left = inputRect.left;
    let top = inputRect.top + 35; // +35 accounts for datepicker element height
    let bottom = inputRect.bottom;
    // Calculate if calendar should appear above or below input
    const calendarHeight = 410; // rough height of calendar
    const spaceBelow = window.innerHeight - bottom;
    // dialog positioning requires calendar positioning to be relative to the dialog
    if (this.#inDialog) {
      const dialogContainer = this.#calendar.parentNode.getBoundingClientRect();
      left = left - dialogContainer.left;
      top = top - dialogContainer.top;
      bottom = dialogContainer.bottom - bottom;
    }

    this.#calendar.style.left = `${left}px`;

    if (spaceBelow < calendarHeight) {
      // Position above the input if there's not enough space below
      this.#calendar.style.top = `${top - calendarHeight}px`;
    } else {
      // Position below the input
      this.#calendar.style.top = `${top}px`;
    }
  }

  // Handle clicks outside the datepicker and input
  handleOutsideClick(event) {
    const clickedInsideComponent =
      this.#calendar.contains(event.target) ||
      this.datepickerInputTarget.contains(event.target);

    if (!clickedInsideComponent) {
      this.hideCalendar();
    }
  }

  // Close calendar and clean up listeners
  hideCalendar() {
    if (!this.#isCalendarOpen) return;

    this.removeCalendarListeners();

    this.#isCalendarOpen = false;
    this.datepickerInputTarget.setAttribute("aria-expanded", "false");
    this.#calendar.classList.add("hidden");
    this.#calendar.setAttribute("aria-hidden", "true");
  }

  // Remove global event listeners
  removeCalendarListeners() {
    document.removeEventListener("click", this.boundHandleOutsideClick);
    document.removeEventListener("keydown", this.boundHandleGlobalKeydown);
  }

  // Handle Escape and Tab key actions once calendar is open
  handleGlobalKeydown(event) {
    // Escape: close calendar
    if (event.key === "Escape") {
      this.hideCalendar();
      this.setInputValue(this.#selectedDate);
      return;
    }

    // If we tab off the last datepicker element, we want to force focus onto the next focussable element after
    // the datepicker input
    if (
      event.key === "Tab" &&
      event.target ===
        this.pathogenDatepickerCalendarOutlet.getLastFocussableElement() &&
      !event.shiftKey
    ) {
      event.preventDefault();
      this.hideCalendar();
      this.#nextFocussableElementAfterInput.focus();
      return;
    }

    // If we Tab while on the datepicker input, Shift+Tab should close the datepicker,
    // while Tab focuses on the first focussable element within the calendar
    if (event.key === "Tab" && event.target === this.datepickerInputTarget) {
      if (event.shiftKey) {
        this.hideCalendar();
      } else if (!event.shiftKey) {
        event.preventDefault();
        this.pathogenDatepickerCalendarOutlet
          .getFirstFocussableElement()
          .focus();
      }
    }
  }

  // handles validating user directly typing in a date
  directInput(event) {
    event.preventDefault();
    const dateInput = event.target.value;
    if (this.#validateDateInput(dateInput)) {
      if (this.minDateValue && this.minDateValue > dateInput) {
        this.#enableInputErrorState(this.invalidMinDateValue);
      } else {
        if (this.autosubmitValue) {
          this.submitDate();
        }
        this.#disableInputErrorState();
      }
    } else {
      this.#enableInputErrorState(this.invalidDateValue);
    }
    this.hideCalendar();
  }

  // validates both the date format (expected YYYY-MM-DD) and if a real date was entered
  #validateDateInput(dateInput) {
    let year, month, day;

    if (dateInput.match(this.#formattedDateRegex)) {
      [year, month, day] = dateInput.split("-").map(Number);
      month--;
      const date = new Date(year, month, day);
      return (
        date.getFullYear() === year &&
        date.getMonth() === month &&
        date.getDate() === day
      );
    }
    return false;
  }

  // without event.preventDefault() on Enter, form is submitted
  handleEnterDirectInput(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      this.directInput(event);
    }
  }

  // adds error message if invalid date or a date prior to minDate was entered
  #enableInputErrorState(message) {
    this.inputErrorTarget.innerText = message;
    if (this.inputErrorTarget.classList.contains("hidden")) {
      this.inputErrorTarget.classList.remove("hidden");
      this.inputErrorTarget.setAttribute("aria-hidden", false);
    }
    this.setInputValue(this.#selectedDate);
  }

  // disables the error state once a valid date is entered/selected
  #disableInputErrorState() {
    this.inputErrorTarget.innerText = "";
    if (!this.inputErrorTarget.classList.contains("hidden")) {
      this.inputErrorTarget.classList.add("hidden");
      this.inputErrorTarget.setAttribute("aria-hidden", true);
    }
  }

  // submits the selected date
  submitDate() {
    this.element.closest("form").requestSubmit();
    this.#setSelectedDate();
    this.#initializeCalendar();
  }

  // handles filling in the date input with the date
  // use cases:
  // 1. Add the newly selected date from the datepicker
  // 2. If user changed date via typing but then escapes out (didn't enter/submit), resets to original value
  // 3. If user entered an invalid date, resets to original value
  setInputValue(date) {
    this.datepickerInputTarget.value = date;
    this.#selectedDate = date;
    this.#setSelectedDate();
    this.#initializeCalendar();
  }

  // passes all shared variables required by the calendar, avoids processing or passing values twice
  // triggers upon initial connection as well as after submission
  #initializeCalendar() {
    const sharedVariables = {
      todaysYear: this.#todaysYear,
      todaysMonthIndex: this.#todaysMonthIndex,
      todaysDate: this.#todaysDate,
      selectedDate: this.#selectedDate,
      selectedYear: this.#selectedYear,
      selectedMonthIndex: this.#selectedMonthIndex,
      minDate: this.minDateValue,
      autosubmit: this.autosubmitValue,
    };
    this.pathogenDatepickerCalendarOutlet.initializeCalendarByInput(
      sharedVariables,
    );
  }

  // used by pathogen/datepicker/calendar.js
  focusDatepickerInput() {
    this.datepickerInputTarget.focus();
  }
}
