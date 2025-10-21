// used to search DOM for next tabbable element after datepicker (datepicker is not appended as a sibling to the input textbox)
export const FOCUSABLE_ELEMENTS =
  'a:not([disabled]), button:not([disabled]), input:not([disabled]):not([type="hidden"]), [tabindex]:not([disabled]):not([tabindex="-1"]), select:not([disabled])';

export const DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

// specifically required for when utils.js getDayOfWeek() is called as new Date(date).getDay() doesn't work with
// non-english month names
export const MONTHS_IN_ENGLISH = [
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

export const CALENDAR_CLASSES = {
  SELECTED_DATE: [
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
  IN_MONTH: [
    "text-slate-900",
    "hover:bg-slate-100",
    "dark:hover:bg-slate-600",
    "dark:text-white",
    "cursor-pointer",
  ],
  OUT_OF_MONTH: [
    "hover:bg-slate-100",
    "dark:hover:bg-slate-600",
    "text-slate-500",
    "dark:text-slate-300",
    "cursor-pointer",
  ],
  TODAYS_DATE: [
    "text-primary-700",
    "bg-slate-100",
    "hover:bg-slate-200",
    "dark:bg-slate-600",
    "dark:hover:bg-slate-500",
    "dark:text-primary-300",
    "cursor-pointer",
  ],
  TODAYS_HOVER: ["hover:bg-slate-200", "dark:hover:bg-slate-500"],
  DISABLED_DATE: [
    "line-through",
    "cursor-not-allowed",
    "text-slate-500",
    "dark:text-slate-300",
  ],
  BACK_BUTTON_DISABLED: ["text-slate-400", "dark:text-slate-500"],
  BACK_BUTTON_ENABLED: ["text-slate-900", "dark:text-slate-100"],
};
