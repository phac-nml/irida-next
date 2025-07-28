export function getDayOfWeek(date) {
  return new Date(date).getDay();
}

// check if date is inMonth (eg: if calendar is on July but contains June 30, June 30 is 'outOfMonth')
export function verifyDateIsInMonth(node) {
  return node.getAttribute("data-date-within-month-position") === "inMonth";
}

export function getDateNode(calendar, date) {
  return calendar.querySelector(`[data-date='${date}']`);
}

export function getFirstOfMonthNode(calendar) {
  return calendar.querySelector('[data-date-within-month-position="inMonth"]');
}

export function focusDate(dateNode) {
  // find current tabbable node, and remove tabIndex
  const currentTabbableDate =
    this.calendarTarget.querySelectorAll('[tabindex="0"]')[0];
  currentTabbableDate.tabIndex = -1;

  // assign tabindex and focus to the current target date
  dateNode.tabIndex = 0;
  dateNode.focus();
}
