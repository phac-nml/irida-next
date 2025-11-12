/**
 * Utility helpers for the advanced search Stimulus controller.
 * These helpers keep the controller focused on wiring events while
 * reusable DOM manipulation and parsing logic resides here.
 */

export const GROUP_SELECTOR =
  "fieldset[data-advanced-search-target='groupsContainer']";
export const CONDITION_SELECTOR =
  "fieldset[data-advanced-search-target='conditionsContainer']";

/**
 * Replace placeholder tokens in a template string.
 * @param {string} template - Raw HTML string from a template element.
 * @param {Record<string, string|number>} replacements - Mapping of placeholder token to value.
 * @returns {string}
 */
export function replacePlaceholders(template, replacements = {}) {
  return Object.entries(replacements).reduce((result, [placeholder, value]) => {
    return result.replace(new RegExp(placeholder, "g"), String(value));
  }, template);
}

/**
 * Find the nearest group fieldset relative to a child element.
 * @param {HTMLElement} element
 * @returns {HTMLElement|null}
 */
export function findGroup(element) {
  return element.closest(GROUP_SELECTOR);
}

/**
 * Find the nearest condition fieldset relative to a child element.
 * @param {HTMLElement} element
 * @returns {HTMLElement|null}
 */
export function findCondition(element) {
  return element.closest(CONDITION_SELECTOR);
}

/**
 * Convert a NodeList of groups into an array for easier manipulation.
 * @param {HTMLElement|DocumentFragment} root
 * @returns {HTMLElement[]}
 */
export function getGroups(root) {
  return Array.from(root.querySelectorAll(GROUP_SELECTOR));
}

/**
 * Retrieve the conditions for a specific group.
 * @param {HTMLElement} group
 * @returns {HTMLElement[]}
 */
export function getConditions(group) {
  return Array.from(group.querySelectorAll(CONDITION_SELECTOR));
}

/**
 * Get the index of the provided group relative to its siblings.
 * @param {HTMLElement} group
 * @param {HTMLElement[]} groups
 * @returns {number}
 */
export function getGroupIndex(group, groups) {
  return groups.indexOf(group);
}

/**
 * Get the index of a condition within its parent group.
 * @param {HTMLElement} condition
 * @returns {number}
 */
export function getConditionIndex(condition) {
  const group = findGroup(condition);
  if (!group) return -1;
  return getConditions(group).indexOf(condition);
}

/**
 * Normalize condition indexes after a condition is added or removed.
 * Updates legend numbering and field names to ensure Rails receives the correct parameters.
 * @param {HTMLElement} group
 * @returns {HTMLElement[]} - Updated list of condition fieldsets.
 */
export function reindexConditions(group) {
  const conditions = getConditions(group);

  conditions.forEach((condition, index) => {
    const legend = condition.querySelector("legend");
    if (legend) {
      legend.innerHTML = legend.innerHTML.replace(
        /(Condition\s)\d+/,
        `$1${index + 1}`,
      );
    }

    condition.querySelectorAll("[name]").forEach((input) => {
      input.name = input.name.replace(
        /(\[conditions_attributes\]\[)\d+?(\])/,
        `$1${index}$2`,
      );
    });
  });

  return conditions;
}

/**
 * Normalize group indexes after a group is added or removed.
 * Updates legend numbering and field names across all groups.
 * @param {HTMLElement[]} groups
 */
export function reindexGroups(groups) {
  groups.forEach((group, index) => {
    const legend = Array.from(group.children).find((child) =>
      child.matches?.("legend"),
    );

    if (legend) {
      legend.innerHTML = legend.innerHTML.replace(
        /(Group\s)\d+/,
        `$1${index + 1}`,
      );
    }

    group.querySelectorAll("[name]").forEach((input) => {
      input.name = input.name.replace(
        /(\[groups_attributes\]\[)\d+?(\])/,
        `$1${index}$2`,
      );
    });
  });
}

/**
 * Safely parse a JSON data attribute stored on an element.
 * @param {HTMLElement} element
 * @param {string} attribute
 * @returns {Object|null}
 */
export function parseJSONDataAttribute(element, attribute) {
  const payload = element.dataset?.[attribute];
  if (!payload) return null;

  try {
    return JSON.parse(payload);
  } catch (error) {
    console.error(`Error parsing JSON data attribute ${attribute}:`, error);
    return null;
  }
}

/**
 * Determine whether a field represents an enum field.
 * @param {Record<string, any>} enumFields
 * @param {string} field
 * @returns {boolean}
 */
export function isEnumField(enumFields, field) {
  return Boolean(
    enumFields && Object.prototype.hasOwnProperty.call(enumFields, field),
  );
}

/**
 * Create a select element populated with enum options.
 * @param {Object} options
 * @param {string} options.name - Name attribute for the select element.
 * @param {string} [options.id] - Optional DOM id to assign.
 * @param {string} [options.className] - Tailwind classes to copy from the original input.
 * @param {string} [options.ariaLabel] - Accessible label.
 * @param {boolean} [options.multiple=false] - Whether the select allows multiple values.
 * @param {Record<string, string>} [options.labels={}] - Optional label overrides per enum value.
 * @param {string[]} options.values - Enum values to populate.
 * @returns {HTMLSelectElement}
 */
export function createEnumSelect({
  name,
  id,
  className = "",
  ariaLabel,
  multiple = false,
  labels = {},
  values = [],
}) {
  const select = document.createElement("select");
  select.name = multiple ? `${name}[]` : name;
  select.id =
    id || name.replace(/\[/g, "_").replace(/\]/g, "").replace(/__+/g, "_");
  select.className = className;

  if (ariaLabel) {
    select.setAttribute("aria-label", ariaLabel);
  }

  if (multiple) {
    select.setAttribute("multiple", "multiple");
  } else {
    const blankOption = document.createElement("option");
    blankOption.value = "";
    blankOption.text = "";
    select.appendChild(blankOption);
  }

  values.forEach((value) => {
    const option = document.createElement("option");
    option.value = value;
    option.text =
      labels[value] ||
      value.replace(/_/g, " ").replace(/\b\w/g, (char) => char.toUpperCase());
    select.appendChild(option);
  });

  return select;
}
