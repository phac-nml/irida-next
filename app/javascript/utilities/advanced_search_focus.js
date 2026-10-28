const FIELD_SELECTOR = [
  "input[role='combobox']",
  "select[name$='[field]']",
  "[name$='[field]']",
  "input:not([type='hidden'])",
].join(", ");

function isAvailableField(element) {
  return (
    element.type !== "hidden" &&
    !element.disabled &&
    !element.hidden &&
    element.getAttribute("aria-disabled") !== "true" &&
    !element.closest("[inert]")
  );
}

export function focusCondition(condition) {
  if (!condition) {
    return;
  }

  if (!condition.hasAttribute("tabindex")) {
    condition.setAttribute("tabindex", "-1");
  }

  condition.focus();
}

export function focusConditionField(condition) {
  if (!condition) {
    return;
  }

  const fieldInput = [...condition.querySelectorAll(FIELD_SELECTOR)].find(
    isAvailableField,
  );

  fieldInput?.focus();
}
