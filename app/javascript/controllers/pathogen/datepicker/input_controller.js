import { Controller } from "@hotwired/stimulus";
import {
  FOCUSABLE_ELEMENTS,
  CALENDAR_HEIGHT,
  CALENDAR_TOP_BUFFER,
} from "./constants.js";

export default class extends Controller {
  static outlets = ["pathogen--datepicker--calendar"];
  static targets = [
    "datepickerInput",
    "calendarTemplate",
    "inputError",
    "minDate",
  ];

  static values = {
    autosubmit: Boolean,
    calendarId: String,
    invalidDate: String,
    invalidMinDate: String,
    dateFormatRegex: String,
  };

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
  // retrieves next focusable element in DOM after date input
  #nextFocusableElementAfterInput;

  // tracks calendar open state
  #isCalendarOpen = false;
  // positioning of datepicker pop-up differs in a dialog
  #inDialog = false;

  #minDate;

  initialize() {
    this.boundUnhideCalendar = this.unhideCalendar.bind(this);
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this);
    this.boundHandleGlobalKeydown = this.handleGlobalKeydown.bind(this);

    // when a turbo response occurs (such as adding new member/group), this initialize will trigger but the
    // calendar will already exist and doesn't need to be added, except for the newly added member/group
    if (!this.#calendar) {
      this.idempotentConnect();
      this.#addCalendarTemplate();
    }
  }

  connect() {
    if (this.hasMinDateTarget) {
      this.#setMinDate();
    }
  }

  idempotentConnect() {
    // the currently selected date will be displayed on the initial calendar
    this.#setSelectedDate();

    ["focus", "click"].forEach((event) => {
      this.datepickerInputTarget.addEventListener(
        event,
        this.boundUnhideCalendar,
      );
    });

    this.#findNextFocusableElement();
  }

  disconnect() {
    ["focus", "click"].forEach((event) => {
      this.datepickerInputTarget.removeEventListener(
        event,
        this.boundUnhideCalendar,
      );
    });
    this.removeCalendarListeners();
  }

  #setMinDate() {
    this.#minDate = this.minDateTarget.firstElementChild.innerText;
    this.invalidMinDateValue = this.invalidMinDateValue.concat(this.#minDate);
    this.minDateTarget.remove();
  }

  #addCalendarTemplate() {
    try {
      // Don't add calendar if already exists
      if (this.#calendar) return;

      // Add the calendar template to the DOM
      const calendar = this.calendarTemplateTarget.content.cloneNode(true);
      const containerNode = this.#findCalendarContainer();
      containerNode.appendChild(calendar);

      // requery calendar so we can manipulate it later. Must use getElementById as target is outside of this controller's
      // scope, and using something like lastElementChild does not work with turbo-stream (eg: members/group-link tables)
      this.#calendar = document.getElementById(this.calendarIdValue);

      if (!this.#calendar) {
        console.error("Failed to find calendar after appending to DOM");
      }
    } catch (error) {
      console.error("Error adding calendar template:", error);
    }
  }

  #setSelectedDate() {
    this.#selectedDate = this.datepickerInputTarget.value;
    if (this.#selectedDate) {
      const fullSelectedDate = new Date(this.#selectedDate);
      this.#selectedYear = fullSelectedDate.getUTCFullYear();
      // Sometimes an issue where selecting the 1st will display the previous month with the 1st as an
      // 'outOfMonth' date (eg: selected Sept 1st, but August is displayed with Sept 1st at the end of calendar)
      // using UTCMonth alleviates the issue
      this.#selectedMonthIndex = fullSelectedDate.getUTCMonth();
    } else {
      this.#selectedYear = this.#todaysYear;
      this.#selectedMonthIndex = this.#todaysMonthIndex;
    }
    if (this.hasPathogenDatepickerCalendarOutlet) {
      this.#shareParamsWithCalendar();
    }
  }

  // because the calendar is appended as the last element, tab logic needs to be altered as a user would expect after
  // tabbing through the calendar, we'd focus on the next element after the date input
  #findNextFocusableElement() {
    const focusable = Array.from(
      document.body.querySelectorAll(FOCUSABLE_ELEMENTS),
    );
    let index = focusable.indexOf(this.datepickerInputTarget);
    this.#nextFocusableElementAfterInput = focusable[index + 1];
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
    this.#shareParamsWithCalendar();
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
    const position = this.#calculateOptimalPosition(inputRect);
    this.#applyPositionToCalendar(position);
  }

  #calculateOptimalPosition(inputRect) {
    let left = inputRect.left;
    let top = inputRect.top + CALENDAR_TOP_BUFFER; // + CALENDAR_TOP_BUFFER accounts for datepicker element height

    // dialog positioning requires calendar positioning to be relative to the dialog
    if (this.#inDialog) {
      const dialogContainer = this.#calendar.parentNode.getBoundingClientRect();
      left = left - dialogContainer.left;
      top = top - dialogContainer.top;
    }

    // Adjust top positioning based on where input is positioned
    const spaceBelow = window.innerHeight - inputRect.bottom;
    // if not enough space below input, orientate calendar above the input
    if (spaceBelow < CALENDAR_HEIGHT) {
      top = top - CALENDAR_HEIGHT;
    }
    return { left, top };
  }

  #applyPositionToCalendar({ left, top }) {
    this.#calendar.style.left = `${left}px`;
    this.#calendar.style.top = `${top}px`;
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

    // If we tab off the last datepicker element, we want to force focus onto the next focusable element after
    // the datepicker input
    if (
      event.key === "Tab" &&
      event.target ===
        this.pathogenDatepickerCalendarOutlet.getLastFocusableElement() &&
      !event.shiftKey
    ) {
      event.preventDefault();
      this.hideCalendar();
      this.#nextFocusableElementAfterInput.focus();
      return;
    }

    // If we Tab while on the datepicker input, Shift+Tab should close the datepicker,
    // while Tab focuses on the first focusable element within the calendar
    if (event.key === "Tab" && event.target === this.datepickerInputTarget) {
      if (event.shiftKey) {
        this.hideCalendar();
      } else if (!event.shiftKey) {
        event.preventDefault();
        this.pathogenDatepickerCalendarOutlet
          .getFirstFocusableElement()
          .focus();
      }
    }
  }

  // handles validating user directly typing in a date
  directInput(event) {
    event.preventDefault();
    const dateInput = event.target.value;
    if (this.#validateDateInput(dateInput)) {
      if (this.#minDate && this.#minDate > dateInput) {
        this.#enableInputErrorState(this.invalidMinDateValue);
      } else {
        if (this.autosubmitValue) {
          this.submitDate();
        } else {
          this.#disableInputErrorState();
        }
        this.#setSelectedDate();
      }
    } else {
      this.#enableInputErrorState(this.invalidDateValue);
    }
    this.hideCalendar();
  }

  // validates both the date format (expected YYYY-MM-DD) and if a real date was entered
  #validateDateInput(dateInput) {
    let year, month, day;
    if (dateInput.match(this.dateFormatRegexValue)) {
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
    this.#disableInputErrorState();
    this.element.closest("form").requestSubmit();
    this.#setSelectedDate();
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
  }

  // passes all shared variables required by the calendar, avoids processing or passing values twice
  // triggers upon initial connection as well as after submission
  #shareParamsWithCalendar() {
    const sharedVariables = {
      todaysYear: this.#todaysYear,
      todaysMonthIndex: this.#todaysMonthIndex,
      todaysDate: this.#todaysDate,
      selectedDate: this.#selectedDate,
      selectedYear: this.#selectedYear,
      selectedMonthIndex: this.#selectedMonthIndex,
      minDate: this.#minDate,
      minDateMessage: this.invalidMinDateValue,
      autosubmit: this.autosubmitValue,
    };
    this.pathogenDatepickerCalendarOutlet.shareParamsWithCalendarByInput(
      sharedVariables,
    );
  }

  // used by pathogen/datepicker/calendar.js
  focusDatepickerInput() {
    this.datepickerInputTarget.focus();
  }
}
