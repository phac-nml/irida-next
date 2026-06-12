export function t(template, vars = {}) {
  return Object.entries(vars).reduce(
    (str, [key, val]) => str.replaceAll(`%{${key}}`, val),
    template,
  );
}
