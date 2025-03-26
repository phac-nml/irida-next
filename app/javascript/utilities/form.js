export function createHiddenInput(name, value) {
  const element = document.createElement("input");
  element.type = "hidden";
  element.name = name;
  element.value = value;
  return element;
}
