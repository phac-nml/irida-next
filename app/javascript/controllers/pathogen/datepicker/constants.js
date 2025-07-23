// used to search DOM for next tabbable element after datepicker (datepicker is not appended as a sibling to the input textbox)
export const FOCUSABLE_ELEMENTS =
  'a:not([disabled]), button:not([disabled]), input:not([disabled]):not([type="hidden"]), [tabindex]:not([disabled]):not([tabindex="-1"]), select:not([disabled])';

// height of the datepicker dialog
export const CALENDAR_HEIGHT = 445;

// adds a buffer based on the datepicker input for datepicker positioning
export const CALENDAR_TOP_BUFFER = 35;

export const DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

export const STYLE_CLASSES = {
  selectedDateClasses: [
    "bg-primary-700",
    "text-white",
    "hover:bg-primary-800",
    "dark:text-white",
    "dark:bg-primary-600",
    "dark:hover:bg-primary-700",
    "dark:border-primary-900",
    "dark:hover:bg-primary-700",
    "cursor-pointer",
  ],
  inMonthClasses: [
    "text-slate-900",
    "hover:bg-slate-100",
    "dark:hover:bg-slate-600",
    "dark:text-white",
    "cursor-pointer",
  ],
  outOfMonthClasses: [
    "hover:bg-slate-100",
    "dark:hover:bg-slate-600",
    "text-slate-500",
    "dark:text-slate-300",
    "cursor-pointer",
  ],
  todaysDateClasses: [
    "text-primary-700",
    "bg-slate-100",
    "hover:bg-slate-200",
    "dark:bg-slate-600",
    "dark:hover:bg-slate-500",
    "dark:text-primary-300",
    "cursor-pointer",
  ],
  disabledDateClasses: [
    "line-through",
    "cursor-not-allowed",
    "text-slate-500",
    "dark:text-slate-300",
  ],
  backButtonDisabledClasses: ["text-slate-400", "dark:text-slate-500"],
  backButtonEnabledClasses: ["text-slate-900", "dark:text-slate-100"],
};
