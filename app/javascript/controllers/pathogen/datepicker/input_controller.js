import { Controller } from "@hotwired/stimulus";

export default class extends Controller {
  static outlets = ["pathogen--datepicker--calendar"];
  static targets = ["datepickerInput", "calenderTemplate", "inputError"];

  static values = {
    minDate: String,
    autosubmit: Boolean,
    invalidDateFormat: String,
    invalidMinDate: String,
  };

  #formattedDateRegex = /^\d{4}-\d{2}-\d{2}$/;

  // today's date attributes for quick access
  #todaysFullDate = new Date();
  #todaysYear = this.#todaysFullDate.getFullYear();
  #todaysMonthIndex = this.#todaysFullDate.getMonth();
  #todaysDate = this.#todaysFullDate.getDate();

  // the currently displayed year/month on datepicker
  #selectedDate;
  #selectedYear;
  #selectedMonthIndex;

  #calendar;
  #nextElementAfterInput;

  initialize() {
    this.boundUnhideCalendar = this.unhideCalendar.bind(this);
    this.boundHandleOutsideClick = this.handleOutsideClick.bind(this);
    this.boundHandleGlobalKeydown = this.handleGlobalKeydown.bind(this);

    // Track calendar open state
    this.isCalendarOpen = false;

    this.addCalenderTemplate();
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
  }

  findNextFocussableElement() {
    var focussableElements =
      'a:not([disabled]), button:not([disabled]), input:not([disabled]):not([type="hidden"]), [tabindex]:not([disabled]):not([tabindex="-1"]), select:not([disabled])';
    var focussable = Array.from(
      document.body.querySelectorAll(focussableElements),
    );
    var index = focussable.indexOf(this.datepickerInputTarget);
    this.#nextElementAfterInput = focussable[index + 1];
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

  addCalenderTemplate(event) {
    // Don't add calendar if it's already open
    if (this.isCalendarOpen) return;

    // Add the calendar template to the DOM
    const calendar = this.calenderTemplateTarget.content.cloneNode(true);
    const containerNode = this.#findCalendarContainer();
    containerNode.appendChild(calendar);
    this.#calendar = containerNode.lastElementChild;

    // this.pathogenDatepickerCalendarOutlet.test("test");
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
    // this.idempotentConnect();
  }

  // datepicker doesn't work if we're in a dialog but it's appended to the body
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
    this.#calendar.classList.remove("hidden");
    this.isCalendarOpen = true;
    // Set ARIA attributes for accessibility
    this.datepickerInputTarget.setAttribute("aria-expanded", "true");
    this.#calendar.setAttribute("aria-hidden", "false");

    // // Add global event listeners for outside clicks and keyboard events
    document.addEventListener("click", this.boundHandleOutsideClick);
    document.addEventListener("keydown", this.boundHandleGlobalKeydown);
  }

  // Handle clicks outside the datepicker component
  handleOutsideClick(event) {
    const clickedInsideComponent =
      this.#calendar.contains(event.target) ||
      this.datepickerInputTarget.contains(event.target);

    if (!clickedInsideComponent) {
      this.closeCalendar();
    }
  }

  // Close calendar and clean up listeners
  closeCalendar() {
    if (!this.isCalendarOpen) return;

    this.removeCalendarListeners();

    if (!this.#calendar.classList.contains("hidden")) {
      this.#calendar.classList.add("hidden");
    }

    this.isCalendarOpen = false;
    this.datepickerInputTarget.setAttribute("aria-expanded", "false");
  }

  // Remove global event listeners
  removeCalendarListeners() {
    document.removeEventListener("click", this.boundHandleOutsideClick);
    document.removeEventListener("keydown", this.boundHandleGlobalKeydown);
  }

  // Handle Escape and Tab key actions once calendar is open
  // other keys are handled in navigateCalendar() and only function when focused within calendar
  handleGlobalKeydown(event) {
    if (event.key === "Escape") {
      this.closeCalendar();
      this.setInputValue(this.#selectedDate);
      return;
    }
    if (
      event.key === "Tab" &&
      event.target ===
        this.pathogenDatepickerCalendarOutlet.getLastFocussableElement() &&
      !event.shiftKey
    ) {
      event.preventDefault();
      this.closeCalendar();
      this.#nextElementAfterInput.focus();
      return;
    }

    if (event.key === "Tab" && event.target === this.datepickerInputTarget) {
      if (event.shiftKey) {
        this.closeCalendar();
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

    // check if date input is formatted as YYYY-MM-DD
    if (!dateInput.match(this.#formattedDateRegex)) {
      this.#enableInputErrorState(this.invalidDateFormatValue);
      return;
    }

    // check if date input is a valid date
    const date = new Date(dateInput);
    var dateTime = date.getTime();
    if (!dateTime && dateTime !== 0) {
      this.#enableInputErrorState(this.invalidDateFormatValue);
      return;
    }

    // if theres a minimum date, check input is after minDate
    if (this.minDateValue && this.minDateValue > dateInput) {
      this.#enableInputErrorState(this.invalidMinDateValue);
      return;
    }

    if (this.autosubmitValue) {
      this.submitDate();
      this.closeCalendar();
    }

    this.#disableInputErrorState();
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
}
