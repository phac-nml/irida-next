import { Controller } from "@hotwired/stimulus";
import FloatingDropdown from "utilities/floating_dropdown";

export default class extends Controller {
  static outlets = ["combobox-datepicker--v1--calendar"];
  static targets = [
    "datepickerInput",
    "calendarTemplate",
    "minDate",
    "maxDate",
    "inputArrow",
  ];

  static values = {
    calendarId: String,
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

  #floatingDropdown;

  #maxDate;
  #minDate;

  initialize() {
    this.boundHandleCalendarFocus = this.handleCalendarFocus.bind(this);
    this.boundHandleGlobalKeydown = this.handleGlobalKeydown.bind(this);
  }

  connect() {
    if (this.hasMinDateTarget) {
      this.#setMinDate();
    }
    if (this.hasMaxDateTarget) {
      this.#setMaxDate();
    }

    this.idempotentConnect();
  }

  idempotentConnect() {
    // the currently selected date will be displayed on the initial calendar
    this.#setSelectedDate();

    this.#addCalendarTemplate();

    // Position the calendar
    this.#initializeDropdown();
  }

  disconnect() {
    this.#floatingDropdown?.destroy();
    this.#floatingDropdown = null;

    if (this.#calendar) {
      this.#calendar.remove();
      this.#calendar = null;
    }
  }

  // trigger must be datepicker input's parent container to maintain proper hide/show logic between clicking on
  // the input text box and the caret arrow
  #initializeDropdown() {
    this.#floatingDropdown = new FloatingDropdown({
      trigger: this.datepickerInputTarget.parentElement,
      dropdown: this.#calendar,
      distance: 10,
      autoSize: false,
      manageAria: false,
      onShow: () => this.#onShow(),
      onHide: () => this.#onHide(),
    });
  }

  #onShow() {
    this.#calendar.removeAttribute("hidden");
    document.addEventListener("keydown", this.boundHandleGlobalKeydown);
    this.#calendar.addEventListener("focusin", this.boundHandleCalendarFocus);
    this.inputArrowTarget.classList.add("rotate-180");
    this.datepickerInputTarget.setAttribute("aria-expanded", "true");
  }

  #onHide() {
    this.#calendar.setAttribute("hidden", "");
    document.removeEventListener("keydown", this.boundHandleGlobalKeydown);
    this.#calendar.removeEventListener(
      "focusin",
      this.boundHandleCalendarFocus,
    );
    this.inputArrowTarget.classList.remove("rotate-180");
    this.datepickerInputTarget.setAttribute("aria-expanded", "false");
  }

  #setMinDate() {
    this.#minDate = this.minDateTarget.firstElementChild.innerText;
    this.minDateTarget.remove();
  }

  #setMaxDate() {
    this.#maxDate = this.maxDateTarget.firstElementChild.innerText;
    this.maxDateTarget.remove();
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

      // aria-controls set after calendar is added to the DOM
      this.datepickerInputTarget.setAttribute(
        "aria-controls",
        this.calendarIdValue,
      );
    } catch (error) {
      console.error("Error adding calendar template:", error);
    }
  }

  #setSelectedDate() {
    this.#selectedDate = this.datepickerInputTarget.value;
    if (
      this.#selectedDate &&
      this.#validateDateWithinBounds(this.#selectedDate)
    ) {
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
    if (this.hasComboboxDatepickerV1CalendarOutlet) {
      this.#shareParamsWithCalendar();
    }
  }

  #validateDateWithinBounds(date) {
    let withinBounds = true;
    if (this.#minDate && this.#minDate > date) {
      withinBounds = false;
    }

    if (this.#maxDate && date > this.#maxDate) {
      withinBounds = false;
    }

    return withinBounds;
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
  comboboxDatepickerV1CalendarOutletConnected() {
    this.#shareParamsWithCalendar();
  }

  toggleCalendar(event) {
    if (!this.#floatingDropdown.isVisible()) {
      this.#floatingDropdown.show();
      // if datepicker was opened by clicking the arrow or by ArrowDown, focus calendar date node
      if (
        (event.type == "click" &&
          event.target !== this.datepickerInputTarget) ||
        event.key === "ArrowDown"
      ) {
        this.comboboxDatepickerV1CalendarOutlet.focusCurrentDate();
      }
    } else {
      this.hideCalendar();
      this.focusDatepickerInput();
    }
  }

  handleCalendarFocus(event) {
    const parentElement = this.#calendar.parentElement;
    if (parentElement.tagName === "DIALOG") {
      // setTimeout as rect seems to grab positions before floating_dropdown sets the calendar to ideal above/below
      // position
      setTimeout(() => {
        const rect = event.target.getBoundingClientRect();
        if (
          rect.top < 0 ||
          rect.top + rect.height > parentElement.offsetHeight
        ) {
          const dialogContents =
            parentElement.querySelector(".dialog--contents");
          dialogContents.scrollBy(0, rect.top);
        }
      }, 10);
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
      event.preventDefault();
      this.hideCalendar();
      this.setInputValue(this.#selectedDate);
      this.focusDatepickerInput();
      return;
    }

    // Shift-tabbing off the first datepicker element will cycle tab to the last datepicker element
    if (
      event.key === "Tab" &&
      event.shiftKey &&
      event.target ===
        this.comboboxDatepickerV1CalendarOutlet.getFirstFocusableElement()
    ) {
      event.preventDefault();
      this.comboboxDatepickerV1CalendarOutlet.getLastFocusableElement().focus();
      return;
    }

    if (event.key === "Tab") {
      // Tabbing off the last datepicker element will cycle tab back to the first datepicker element
      if (
        event.target ===
          this.comboboxDatepickerV1CalendarOutlet.getLastFocusableElement() &&
        !event.shiftKey
      ) {
        event.preventDefault();
        this.comboboxDatepickerV1CalendarOutlet
          .getFirstFocusableElement()
          .focus();
        // Tabbing from input text box, close calendar, handles tabbing after clicking datepicker input
      } else if (event.target === this.datepickerInputTarget) {
        this.hideCalendar();
      }
      return;
    }
  }

  handleInputChange(event) {
    event.preventDefault();
    const dateInput = event.target.value;
    if (
      this.#validateDateInput(dateInput) &&
      this.#validateDateWithinBounds(dateInput)
    ) {
      this.#setSelectedDate();
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
  handleKeyboardInput(event) {
    if (event.key === "ArrowDown") {
      event.preventDefault();
      this.toggleCalendar(event);
    } else if (event.key === "Enter") {
      event.preventDefault();
      this.handleInputChange(event);
    }
  }

  // submits the selected date
  submitDate() {
    this.element.closest("form").requestSubmit();
    this.#setSelectedDate();
  }

  // handles filling in the date input with the date
  // use cases:
  // 1. Add the newly selected date from the datepicker
  // 2. If user changed date via typing but then escapes out (didn't enter/submit), resets to original value
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
      maxDate: this.#maxDate,
      minDate: this.#minDate,
    };
    this.comboboxDatepickerV1CalendarOutlet.shareParamsWithCalendarByInput(
      sharedVariables,
    );
  }

  #handleError(error, source) {
    // In production, consider reporting errors to a logging service
    console.error(
      `Combobox-Datepicker--V1--InputController error in ${source}:`,
      error,
    );
  }

  // used by combobox_datepicker/calendar_controller.js and input_controller.js
  focusDatepickerInput() {
    this.datepickerInputTarget.focus();
  }
}
