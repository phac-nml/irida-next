export function isPrintableCharacter(str) {
  return str.length === 1 && str.match(/\S| /);
}

export function getLowercaseContent(node) {
  return node.textContent.toLowerCase();
}

export function isOptionInView(option) {
  const bounding = option.getBoundingClientRect();
  return (
    bounding.top >= 0 &&
    bounding.left >= 0 &&
    bounding.bottom <=
      (window.innerHeight || document.documentElement.clientHeight) &&
    bounding.right <=
      (window.innerWidth || document.documentElement.clientWidth)
  );
}

export function highlightOption(option, filter) {
  const escapeRegExp = filter.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const regex = new RegExp(`(${escapeRegExp})`, "gi");
  option.innerHTML = option.textContent.replace(
    regex,
    "<mark class='bg-primary-300 dark:bg-primary-600 font-semibold'>$1</mark>",
  );
  return option;
}

export function setActiveDescendant(option, combobox) {
  if (option) {
    combobox.setAttribute("aria-activedescendant", option.id);
    if (!isOptionInView(option)) {
      option.scrollIntoView({ behavior: "smooth", block: "nearest" });
    }
  } else {
    combobox.removeAttribute("aria-activedescendant");
  }
}
