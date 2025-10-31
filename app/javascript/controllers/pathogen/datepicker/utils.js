export function getDayOfWeek(year, monthIndex, day) {
  return new Date(year, monthIndex, day).getDay();
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
