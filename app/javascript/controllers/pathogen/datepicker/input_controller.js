import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static outlets = ["pathogen--datepicker--calendar"];
  static targets = ["datepickerInput", "calenderTemplate", "inputError"];

  static values = {
    minDate: String,
    autosubmit: Boolean,
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

  initialize() {
    this.boundUnhideCalendar = this.unhideCalendar.bind(this);
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this);
    this.boundHandleGlobalKeydown = this.handleGlobalKeydown.bind(this);

    this.#addCalenderTemplate();
  }

  connect() {
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
    this.#calendar = containerNode.lastElementChild;
  }

  #setSelectedDate() {
    this.#selectedDate = this.datepickerInputTarget.value;
    if (this.#selectedDate) {
      const fullSelectedDate = new Date(this.#selectedDate);
      this.#selectedYear = fullSelectedDate.getFullYear();
      this.#selectedMonthIndex = fullSelectedDate.getMonth();
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
    // Position the calendar (implement proper positioning logic here)
    const inputRect = this.datepickerInputTarget.getBoundingClientRect();
    this.#calendar.style.left = `${inputRect.left}px`;

    // Calculate if calendar should appear above or below input
    const spaceBelow = window.innerHeight - inputRect.bottom;
    const calendarHeight = 400; // Estimate height or calculate from actual rendered element
    if (spaceBelow < calendarHeight && inputRect.top > calendarHeight) {
      // Position above the input if there's not enough space below
      this.#calendar.style.top = `${inputRect.top - calendarHeight}px`;
    } else {
      // Position below the input
      this.#calendar.style.top = `${inputRect.bottom}px`;
    }

    this.#calendar.classList.remove("hidden");
    this.#isCalendarOpen = true;
    // Set ARIA attributes for accessibility
    this.datepickerInputTarget.setAttribute("aria-expanded", "true");
    this.#calendar.setAttribute("aria-hidden", "false");

    // // Add global event listeners for outside clicks and keyboard events
    document.addEventListener("click", this.boundHandleOutsideClick);
    document.addEventListener("keydown", this.boundHandleGlobalKeydown);
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

  handleEnterDirectInput(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      this.directInput(event);
    }
  }

  #enableInputErrorState(message) {
    this.inputErrorTarget.innerText = message;
    if (this.inputErrorTarget.classList.contains("hidden")) {
      this.inputErrorTarget.classList.remove("hidden");
      this.inputErrorTarget.setAttribute("aria-hidden", false);
    }
    this.setInputValue(this.#selectedDate);
  }

  #disableInputErrorState() {
    this.inputErrorTarget.innerText = "";
    if (!this.inputErrorTarget.classList.contains("hidden")) {
      this.inputErrorTarget.classList.add("hidden");
      this.inputErrorTarget.setAttribute("aria-hidden", true);
    }
  }

  submitDate() {
    this.element.closest("form").requestSubmit();
    this.#setSelectedDate();
    this.#initializeCalendar();
  }

  setInputValue(value) {
    this.datepickerInputTarget.value = value;
  }

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

  focusDatepickerInput() {
    this.datepickerInputTarget.focus();
  }
}
