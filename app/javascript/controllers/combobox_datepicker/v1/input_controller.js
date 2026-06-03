import { Controller } from "@hotwired/stimulus";
import FloatingDropdown from "utilities/floating_dropdown";
import { focusWhenVisible } from "utilities/focus";

export default class extends Controller {
  static outlets = ["combobox-datepicker--v1--calendar"];
  static targets = [
    "datepickerLabel",
    "datepickerInput",
    "calendarTemplate",
    "minDate",
    "maxDate",
    "inputArrow",
    "confirmDialogTemplate",
    "confirmDialogContainer",
  ];

  static values = {
    autosubmit: Boolean,
    calendarId: String,
    invalidDate: String,
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

  #arrowSvg;

  initialize() {
    this.boundBlur = this.blur.bind(this);
  }

  connect() {
    if (this.hasMinDateTarget) {
      this.#setMinDate();
    }
    if (this.hasMaxDateTarget) {
      this.#setMaxDate();
    }

    this.#arrowSvg = this.inputArrowTarget.firstElementChild;
    this.boundHandleCalendarFocus = this.handleCalendarFocus.bind(this);
    this.boundHandleGlobalKeydown = this.handleGlobalKeydown.bind(this);

    this.datepickerInputTarget.addEventListener("blur", this.boundBlur);
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
    this.#arrowSvg.classList.add("rotate-180");
    this.datepickerInputTarget.setAttribute("aria-expanded", "true");
  }

  #onHide() {
    this.#calendar.setAttribute("hidden", "");
    document.removeEventListener("keydown", this.boundHandleGlobalKeydown);
    this.#calendar.removeEventListener(
      "focusin",
      this.boundHandleCalendarFocus,
    );
    this.#arrowSvg.classList.remove("rotate-180");
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
    if (this.#validateInputValue(this.datepickerInputTarget.value)) {
      this.#selectedDate = this.datepickerInputTarget.value;
      const fullSelectedDate = new Date(this.#selectedDate);
      this.#selectedYear = fullSelectedDate.getUTCFullYear();
      // Sometimes an issue where selecting the 1st will display the previous month with the 1st as an
      // 'outOfMonth' date (eg: selected Sept 1st, but August is displayed with Sept 1st at the end of calendar)
      // using UTCMonth alleviates the issue
      this.#selectedMonthIndex = fullSelectedDate.getUTCMonth();
    } else {
      this.#selectedDate = "";
      this.#selectedYear = this.#todaysYear;
      this.#selectedMonthIndex = this.#todaysMonthIndex;
    }
    if (this.hasComboboxDatepickerV1CalendarOutlet) {
      this.#shareParamsWithCalendar();
    }
  }

  // validates the date within the input; prevents re-rendering incorrect calendar if an invalid date was entered
  // and submitted to the backend
  #validateInputValue(date) {
    if (
      isNaN(Date.parse(date)) ||
      (this.#minDate && this.#minDate > date) ||
      (this.#maxDate && date > this.#maxDate)
    ) {
      return false;
    }

    return true;
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
      this.datepickerInputTarget.focus();
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
      this.datepickerInputTarget.focus();
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

  // handles validating user directly typing in a date
  directInput(event) {
    event.preventDefault();
    if (this.autosubmitValue) {
      this.submitDate();
    } else {
      this.#setSelectedDate();
    }
    this.hideCalendar();
  }

  // without event.preventDefault() on Enter, form is submitted
  handleEnterDirectInput(event) {
    if (event.key === "Enter") {
      event.preventDefault();
      this.directInput(event);
    } else if (event.key === "ArrowDown") {
      event.preventDefault();
      this.toggleCalendar(event);
    }
  }

  async blur(event) {
    if (this.datepickerInputTarget.value == this.#selectedDate) return;

    event.preventDefault();

    await this.confirmDirectInput();
  }

  async confirmDirectInput() {
    const confirmDialog = this.confirmDialogTemplateTarget.innerHTML
      .replace(/ORIGINAL_VALUE/g, this.#selectedDate)
      .replace(/NEW_VALUE/g, this.datepickerInputTarget.value);
    this.confirmDialogContainerTarget.innerHTML = confirmDialog;

    const dialog =
      this.confirmDialogContainerTarget.getElementsByTagName("dialog")[0];
    let messageType = "wov";

    if (this.datepickerInputTarget.value === "") {
      messageType = "wonv";
    } else if (this.#selectedDate === "") {
      messageType = "woov";
    }
    dialog
      .querySelector(`[data-message-type="${messageType}"]`)
      .classList.remove("hidden");

    dialog.showModal();

    // Focus the cancel button for accessibility
    const cancelButton = dialog.querySelector('button[value="cancel"]');
    if (cancelButton) {
      focusWhenVisible(cancelButton);
    }

    // Handle dialog actions
    dialog.addEventListener(
      "click",
      (e) => {
        if (e.target.tagName !== "BUTTON") return;
        e.target.value === "confirm" ? this.submitDate() : this.#resetInput();
        dialog.close();
      },
      { once: true },
    );

    // Handle dialog close
    dialog.addEventListener(
      "close",
      () => {
        this.#resetInput();
      },
      { once: true },
    );
  }

  #resetInput() {
    this.datepickerInputTarget.value = this.#selectedDate;
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
      autosubmit: this.autosubmitValue,
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

  // used by datepicker/calendar.js
  focusDatepickerInput() {
    this.datepickerInputTarget.focus();
  }
}
