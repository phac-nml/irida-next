import { Controller } from "@hotwired/stimulus";
import {
  FOCUSABLE_ELEMENTS,
  INPUT_CLASSES,
} from "controllers/datepicker/constants";
import { replaceStyleClasses } from "controllers/datepicker/utils";
import FloatingDropdown from "utilities/floating_dropdown";

export default class extends Controller {
  static outlets = ["datepicker--v2--calendar"];
  static targets = [
    "datepickerLabel",
    "datepickerInput",
    "calendarTemplate",
    "minDate",
    "errorContainer",
    "errorMessageTemplate",
    "errorMessage",
    "ariaLive",
    "inputArrow",
  ];

  static values = {
    autosubmit: Boolean,
    calendarId: String,
    invalidDate: String,
    invalidMinDate: String,
    dateFormatRegex: String,
    errorMessageId: String,
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

  #floatingDropdown;

  #minDate;

  #arrowSvg;

  connect() {
    if (this.hasMinDateTarget) {
      this.#setMinDate();
    }

    this.#arrowSvg = this.inputArrowTarget.firstElementChild;
    this.boundHandleCalendarFocus = this.handleCalendarFocus.bind(this);
    this.boundHandleGlobalKeydown = this.handleGlobalKeydown.bind(this);

    this.idempotentConnect();
  }

  idempotentConnect() {
    // the currently selected date will be displayed on the initial calendar
    this.#setSelectedDate();

    this.#addCalendarTemplate();

    // Position the calendar
    this.#initializeDropdown();

    this.#findNextFocusableElement();
  }

  disconnect() {
    this.#floatingDropdown?.destroy();
    this.#floatingDropdown = null;

    this.#calendar.remove();
    this.#calendar = null;
  }

  #initializeDropdown() {
    this.#floatingDropdown = new FloatingDropdown({
      trigger: this.datepickerInputTarget,
      dropdown: this.#calendar,
      distance: 10,
      onShow: () => this.#onShow(),
      onHide: () => this.#onHide(),
    });
  }

  #onShow() {
    document.addEventListener("keydown", this.boundHandleGlobalKeydown);
    this.#calendar.addEventListener("focusin", this.boundHandleCalendarFocus);
    this.#arrowSvg.classList.add("rotate-180");
  }

  #onHide() {
    document.removeEventListener("keydown", this.boundHandleGlobalKeydown);
    this.#calendar.removeEventListener(
      "focusin",
      this.boundHandleCalendarFocus,
    );
    this.#arrowSvg.classList.remove("rotate-180");
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
    if (this.hasDatepickerV2CalendarOutlet) {
      this.#shareParamsWithCalendar();
    }
  }

  // because the calendar is appended as the last element, tab logic needs to be altered as a user would expect after
  // tabbing through the calendar, we'd focus on the next element after the date input
  #findNextFocusableElement() {
    const focusable = Array.from(
      document.body.querySelectorAll(FOCUSABLE_ELEMENTS),
    );
    const index = focusable.indexOf(this.datepickerInputTarget);
    this.#nextFocusableElementAfterInput = focusable[index + 1];
  }

  // append datepicker to dialog if in dialog, otherwise append to body
  #findCalendarContainer() {
    let nextParentElement = this.datepickerInputTarget.parentElement;
    while (nextParentElement.tagName !== "MAIN") {
      if (nextParentElement.tagName === "DIALOG") {
        return nextParentElement;
      }
      nextParentElement = nextParentElement.parentElement;
    }
    return nextParentElement;
  }

  // once the calendar controller connects, share values used by both controllers
  datepickerV2CalendarOutletConnected() {
    this.#shareParamsWithCalendar();
  }

  toggleCalendar() {
    if (!this.#floatingDropdown.isVisible()) {
      this.#floatingDropdown.show();
    } else {
      this.hideCalendar();
    }
  }

  handleCalendarFocus(event) {
    const parentElement = this.#calendar.parentElement;
    if (parentElement.tagName === "DIALOG") {
      const rect = event.target.getBoundingClientRect();

      if (rect.top < 0 || rect.top + rect.height > parentElement.offsetHeight) {
        const dialogContents = parentElement.querySelector(".dialog--contents");
        dialogContents.scrollBy(0, rect.top);
      }
    }
  }

  // Hide calendar
  hideCalendar() {
    try {
      if (this.#floatingDropdown) {
        this.#floatingDropdown.hide();
      }
    } catch (error) {
      this.#handleError(error, "hideDropdown");
    }
  }

  // Handle Escape and Tab key actions once calendar is open
  handleGlobalKeydown(event) {
    // Escape: close calendar
    if (event.key === "Escape") {
      this.hideCalendar();
      this.setInputValue(this.#selectedDate);
      this.datepickerInputTarget.focus();
      return;
    }

    // If we tab off the last datepicker element, we want to force focus onto the next focusable element after
    // the datepicker input
    if (
      event.key === "Tab" &&
      event.target ===
        this.datepickerV2CalendarOutlet.getLastFocusableElement() &&
      !event.shiftKey
    ) {
      event.preventDefault();
      this.datepickerV2CalendarOutlet.getFirstFocusableElement().focus();
      return;
    }

    if (
      event.key === "Tab" &&
      event.shiftKey &&
      event.target ===
        this.datepickerV2CalendarOutlet.getFirstFocusableElement()
    ) {
      event.preventDefault();
      this.datepickerV2CalendarOutlet.getLastFocusableElement().focus();
      return;
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
          this.disableInputErrorState();
        }
        this.#setSelectedDate();
        this.focusNextFocusableElement();
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
    } else if (event.key === "ArrowDown") {
      this.toggleCalendar();
      this.datepickerV2CalendarOutlet.focusCurrentDate();
    }
  }

  // adds error message if invalid date or a date prior to minDate was entered
  #enableInputErrorState(message) {
    if (this.autosubmitValue) {
      this.errorContainerTarget.innerHTML = "";
      this.datepickerInputTarget.setAttribute("aria-invalid", "true");
      this.datepickerInputTarget.setAttribute(
        "aria-describedby",
        this.errorMessageIdValue,
      );
      this.#toggleErrorState(true);
      const errorMessage =
        this.errorMessageTemplateTarget.content.cloneNode(true);
      this.errorContainerTarget.appendChild(errorMessage);
      this.errorMessageTarget.innerText = message;

      this.ariaLiveTarget.innerText = message;

      if (this.errorContainerTarget.classList.contains("hidden")) {
        this.errorContainerTarget.classList.remove("hidden");
        this.errorContainerTarget.setAttribute("aria-hidden", false);
      }
    }
  }

  // disables the error state once a valid date is entered/selected
  disableInputErrorState() {
    if (this.autosubmitValue) {
      this.errorContainerTarget.innerHTML = "";
      this.datepickerInputTarget.removeAttribute("aria-invalid");
      this.datepickerInputTarget.removeAttribute("aria-describedby");
      if (!this.errorContainerTarget.classList.contains("hidden")) {
        this.errorContainerTarget.classList.add("hidden");
        this.errorContainerTarget.setAttribute("aria-hidden", true);
      }

      this.#toggleErrorState(false);
    }
  }

  #toggleErrorState(erroring) {
    if (erroring) {
      replaceStyleClasses(
        this.datepickerInputTarget,
        INPUT_CLASSES["INPUT_DEFAULT"],
        INPUT_CLASSES["INPUT_ERROR"],
      );
      if (this.hasDatepickerLabelTarget) {
        replaceStyleClasses(
          this.datepickerLabelTarget,
          INPUT_CLASSES["LABEL_DEFAULT"],
          INPUT_CLASSES["LABEL_ERROR"],
        );
      }
    } else {
      replaceStyleClasses(
        this.datepickerInputTarget,
        INPUT_CLASSES["INPUT_ERROR"],
        INPUT_CLASSES["INPUT_DEFAULT"],
      );
      if (this.hasDatepickerLabelTarget) {
        replaceStyleClasses(
          this.datepickerLabelTarget,
          INPUT_CLASSES["LABEL_ERROR"],
          INPUT_CLASSES["LABEL_DEFAULT"],
        );
      }
    }
  }

  // submits the selected date
  submitDate() {
    this.disableInputErrorState();
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
    this.datepickerV2CalendarOutlet.shareParamsWithCalendarByInput(
      sharedVariables,
    );
  }

  #handleError(error, source) {
    // In production, consider reporting errors to a logging service
    console.error(`Datepicker--V2--InputController error in ${source}:`, error);
  }

  // used by datepicker/calendar.js
  focusDatepickerInput() {
    this.datepickerInputTarget.focus();
  }

  focusNextFocusableElement() {
    this.#nextFocusableElementAfterInput.focus();
  }
}
