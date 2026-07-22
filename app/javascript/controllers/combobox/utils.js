export function isPrintableCharacter(str) {
  return str.length === 1 && str.match(/\S| /);
}

export function isOptionDisabled(option) {
  return option?.getAttribute("aria-disabled") === "true";
}

export function isComboboxDisabled(combobox) {
  return combobox?.getAttribute("aria-disabled") === "true";
}

export function getLowercaseContent(node) {
  return node.textContent.toLowerCase();
}

export function highlightOption(option, filter) {
  if (!filter) {
    return option;
  }

  const escape = filter.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  const regex = new RegExp(escape, "gi");

  // Highlight only text nodes so existing child elements remain untouched.
  const walker = document.createTreeWalker(option, NodeFilter.SHOW_TEXT);
  const textNodes = [];
  let currentNode = walker.nextNode();

  while (currentNode) {
    textNodes.push(currentNode);
    currentNode = walker.nextNode();
  }

  textNodes.forEach((textNode) => {
    const text = textNode.nodeValue;
    if (!text) {
      return;
    }

    regex.lastIndex = 0;
    const matches = [...text.matchAll(regex)];
    if (matches.length === 0) {
      return;
    }

    const fragment = document.createDocumentFragment();
    let lastIndex = 0;

    matches.forEach((match) => {
      const index = match.index;
      if (index === undefined) {
        return;
      }

      if (index > lastIndex) {
        fragment.appendChild(
          document.createTextNode(text.slice(lastIndex, index)),
        );
      }

      const mark = document.createElement("mark");
      mark.className = "bg-primary-300 dark:bg-primary-600 font-semibold";
      mark.textContent = match[0];
      fragment.appendChild(mark);
      lastIndex = index + match[0].length;
    });

    if (lastIndex < text.length) {
      fragment.appendChild(document.createTextNode(text.slice(lastIndex)));
    }

    textNode.replaceWith(fragment);
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
