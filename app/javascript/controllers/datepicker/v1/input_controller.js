import { Controller } from "@hotwired/stimulus";
import { FOCUSABLE_ELEMENTS } from "controllers/datepicker/constants";

export default class extends Controller {
  static outlets = ["datepicker--v1--calendar"];
  static targets = [
    "datepickerInput",
    "calendarTemplate",
    "minDate",
    "errorContainer",
    "errorMessageTemplate",
    "errorMessage",
    "ariaLive",
  ];

  static values = {
    autosubmit: Boolean,
    calendarId: String,
    invalidDate: String,
    invalidMinDate: String,
    dateFormatRegex: String,
    errors: Array,
  };

  #labelErrorClasses = ["text-red-700", "dark:text-red-400"];
  #labelDefaultClasses = ["text-slate-900", "dark:text-white"];

  #inputErrorClasses = ["!border-red-500", "!dark:border-red-400"];
  #inputDefaultClasses = ["border-slate-300", "dark:border-slate-600"];

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

  #dropdown;

  #minDate;

  #formFieldContainer;

  connect() {
    if (this.hasMinDateTarget) {
      this.#setMinDate();
    }

    if (this.errorsValue.length > 0) {
      this.#enableInputErrorState(this.errorsValue);
    }

    this.#findClosestFormField();

    this.boundHandleDatepickerInputFocus =
      this.handleDatepickerInputFocus.bind(this);
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

    this.datepickerInputTarget.addEventListener(
      "focus",
      this.boundHandleDatepickerInputFocus,
    );

    this.#findNextFocusableElement();
  }

  disconnect() {
    this.datepickerInputTarget.removeEventListener(
      "focus",
      this.boundHandleDatepickerInputFocus,
    );

    this.#calendar.remove();
    this.#calendar = null;
  }

  // verifies if the datepicker is within a form-field container. This will then allow us to disable any backend
  // validation error state styling classes (eg: remove .invalid) from this container
  #findClosestFormField() {
    const closestFormField = this.element.closest(".form-field");

    if (closestFormField && closestFormField.contains(this.element)) {
      this.#formFieldContainer = closestFormField;
    }
  }

  #initializeDropdown() {
    try {
      if (typeof Dropdown !== "function") {
        throw new Error(
          "Flowbite Dropdown class not found. Make sure Flowbite JS is loaded.",
        );
      }
      this.#dropdown = new Dropdown(
        this.#calendar,
        this.datepickerInputTarget,
        {
          placement: "top",
          triggerType: "none", // handle via handleDatepickerInputFocus instead
          offsetSkidding: 0,
          offsetDistance: 10,
          delay: 300,
          onShow: () => {
            this.datepickerInputTarget.setAttribute("aria-expanded", "true");
            document.addEventListener("keydown", this.boundHandleGlobalKeydown);
            this.#calendar.addEventListener(
              "focusin",
              this.boundHandleCalendarFocus,
            );
          },
          onHide: () => {
            this.datepickerInputTarget.setAttribute("aria-expanded", "false");
            document.removeEventListener(
              "keydown",
              this.boundHandleGlobalKeydown,
            );
            this.#calendar.removeEventListener(
              "focusin",
              this.boundHandleCalendarFocus,
            );
          },
        },
      );
    } catch (error) {
      this.#handleError(error, "initializeDropdown");
    }
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
    if (this.hasDatepickerV1CalendarOutlet) {
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
  datepickerV1CalendarOutletConnected() {
    this.#shareParamsWithCalendar();
  }

  handleDatepickerInputFocus() {
    if (!this.#dropdown.isVisible()) {
      this.#dropdown.show();
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
      if (this.#dropdown) this.#dropdown.hide();
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
      return;
    }

    // If we tab off the last datepicker element, we want to force focus onto the next focusable element after
    // the datepicker input
    if (
      event.key === "Tab" &&
      event.target ===
        this.datepickerV1CalendarOutlet.getLastFocusableElement() &&
      !event.shiftKey
    ) {
      event.preventDefault();
      this.hideCalendar();
      this.focusNextFocusableElement();
      return;
    }

    // If we Tab while on the datepicker input, Shift+Tab should close the datepicker,
    // while Tab focuses on the first focusable element within the calendar
    if (event.key === "Tab" && event.target === this.datepickerInputTarget) {
      if (event.shiftKey) {
        this.hideCalendar();
      } else if (!event.shiftKey) {
        event.preventDefault();
        this.datepickerV1CalendarOutlet.getFirstFocusableElement().focus();
      }
    }
  }

  // handles validating user directly typing in a date
  directInput(event) {
    event.preventDefault();
    const dateInput = event.target.value;
    if (this.#validateDateInput(dateInput)) {
      if (this.#minDate && this.#minDate > dateInput) {
        this.#enableInputErrorState([this.invalidMinDateValue]);
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
      this.#enableInputErrorState([this.invalidDateValue]);
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
  #enableInputErrorState(messages) {
    this.errorContainerTarget.innerHTML = "";

    this.datepickerInputTarget.setAttribute("aria-invalid", "true");
    this.datepickerInputTarget.setAttribute(
      "aria-describedby",
      `${this.datepickerInputTarget.id}-message`,
    );

    this.#toggleErrorState(true);
    messages.forEach((message) => {
      const errorMessage =
        this.errorMessageTemplateTarget.content.cloneNode(true);
      this.errorContainerTarget.appendChild(errorMessage);
      this.errorMessageTargets[this.errorMessageTargets.length - 1].innerText =
        message;
    });

    this.ariaLiveTarget.innerText = messages.join(", ");

    if (this.errorContainerTarget.classList.contains("hidden")) {
      this.errorContainerTarget.classList.remove("hidden");
      this.errorContainerTarget.setAttribute("aria-hidden", false);
    }
  }

  // disables the error state once a valid date is entered/selected
  disableInputErrorState() {
    this.errorContainerTarget.innerText = "";
    this.datepickerInputTarget.removeAttribute("aria-invalid");
    this.datepickerInputTarget.removeAttribute("aria-describedby");
    if (!this.errorContainerTarget.classList.contains("hidden")) {
      this.errorContainerTarget.classList.add("hidden");
      this.errorContainerTarget.setAttribute("aria-hidden", true);
    }

    if (
      this.#formFieldContainer &&
      this.#formFieldContainer.classList.contains("invalid")
    ) {
      this.#formFieldContainer.classList.remove("invalid");
    }

    this.#toggleErrorState(false);
  }

  #toggleErrorState(erroring) {
    if (erroring) {
      this.datepickerInputTarget.classList.remove(...this.#inputDefaultClasses);
      this.datepickerInputTarget.classList.add(...this.#inputErrorClasses);
      if (this.hasDatepickerLabelTarget) {
        this.datepickerLabelTarget.classList.remove(
          ...this.#labelDefaultClasses,
        );
        this.datepickerLabelTarget.classList.add(...this.#labelErrorClasses);
      }
    } else {
      this.datepickerInputTarget.classList.remove(...this.#inputErrorClasses);
      this.datepickerInputTarget.classList.add(...this.#inputDefaultClasses);
      if (this.hasDatepickerLabelTarget) {
        this.datepickerLabelTarget.classList.remove(...this.#labelErrorClasses);
        this.datepickerLabelTarget.classList.add(...this.#labelDefaultClasses);
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
    this.datepickerV1CalendarOutlet.shareParamsWithCalendarByInput(
      sharedVariables,
    );
  }

  #handleError(error, source) {
    // In production, consider reporting errors to a logging service
    console.error(`Datepicker--V1--InputController error in ${source}:`, error);
  }

  // used by datepicker/calendar.js
  focusDatepickerInput() {
    this.datepickerInputTarget.focus();
  }

  focusNextFocusableElement() {
    this.#nextFocusableElementAfterInput.focus();
  }
}
