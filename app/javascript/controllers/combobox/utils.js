export function isPrintableCharacter(str) {
  return str.length === 1 && str.match(/\S| /);
}

export function getLowercaseContent(node) {
  return node.textContent.toLowerCase();
}

export function highlightOption(option, filter) {
  if (!filter) {
    return option;
  }
  const escape = filter.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const regex = new RegExp(`(${escape})`, "gi");
  const text = option.textContent;
  const parts = text.split(regex);
  option.innerHTML = "";
  parts.forEach((part) => {
    if (regex.test(part)) {
      const mark = document.createElement("mark");
      mark.className = "bg-primary-300 dark:bg-primary-600 font-semibold";
      mark.textContent = part;
      option.appendChild(mark);
    } else {
      option.appendChild(document.createTextNode(part));
    }
  });
  return option;
}

export function setActiveDescendant(option, combobox) {
  if (option) {
    combobox.setAttribute("aria-activedescendant", option.id);
  } else {
    combobox.removeAttribute("aria-activedescendant");
  }
}
