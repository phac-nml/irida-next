export const DAYS_IN_MONTH = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

export const CALENDAR_CLASSES = {
  SELECTED_DATE: [
    "bg-primary-700",
    "!text-white",
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
    "after:absolute",
    "after:left-1/2",
    "after:bottom-1",
    "after:h-1.5",
    "after:w-1.5",
    "after:-translate-x-1/2",
    "after:rounded-full",
    "after:bg-primary-700",
    "dark:after:bg-primary-600",
    "after:content-['']",
  ],

  TODAYS_HOVER: ["hover:bg-slate-200", "dark:hover:bg-slate-500"],
  MONTH_NAV_ARROW_DISABLED: ["text-slate-400", "dark:text-slate-500"],
  MONTH_NAV_ARROW_ENABLED: ["text-slate-900", "dark:text-slate-100"],
};
