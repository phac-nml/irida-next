export function createHiddenInput(name, value) {
  const element = document.createElement("input");
  element.type = "hidden";
  element.name = name;
  element.value = value;
  return element;
}

/**
 * Converts FormData to a JSON object with normalized parameters.
 * @param {FormData} formData - The FormData object to convert
 * @returns {Object} The normalized JSON parameters
 */
export function formDataToJsonParams(formData) {
  const jsonParams = new Object();

  formData.forEach((value, key) => {
    normalizeParams(jsonParams, key, value, 0);
  });

  return jsonParams;
}

/**
 * Custom error class for parameter type errors.
 */
export class ParameterTypeError extends Error {
  constructor(message) {
    super(message);
    this.name = "ParameterTypeError";
  }
}

/**
 * Normalizes form parameters into a nested object structure.
 * Stolen from Rack, converted from Ruby to Javascript
 * https://github.com/rack/rack/blob/e6376927801774e25a3c1e5b977ff2fd2209e799/lib/rack/query_parser.rb#L124
 * @param {Object} params - The target object to store normalized parameters
 * @param {string} name - The parameter name to normalize
 * @param {*} v - The parameter value
 * @param {number} depth - The current nesting depth
 * @returns {Object} The normalized parameters object
 * @throws {ParameterTypeError} When parameter types don't match expected structure
 */
export function normalizeParams(params, name, v, depth) {
  let k, after, child_key, start;

  if (!name) {
    // nil name, treat same as empty string (required by tests)
    k = after = "";
  } else if (depth === 0) {
    // Start of parsing, don't treat [] or [ at start of string specially
    if ((start = name.indexOf("[", 1)) !== -1) {
      // Start of parameter nesting, use part before brackets as key
      k = name.substring(0, 0 + start);
      after = name.substring(start, start + name.length);
    } else {
      // Plain parameter with no nesting
      k = name;
      after = "";
    }
  } else if (name.startsWith("[]")) {
    // Array nesting
    k = "[]";
    after = name.substring(2, 2 + name.length);
  } else if (name.startsWith("[") && (start = name.indexOf("]", 1)) !== -1) {
    // Hash nesting, use the part inside brackets as the key
    k = name.substring(1, 1 + start - 1);
    after = name.substring(start + 1, start + 1 + name.length);
  } else {
    // Probably malformed input, nested but not starting with [
    // treat full name as key for backwards compatibility.
    k = name;
    after = "";
  }

  if (k === undefined || k.length === 0) return;

  if (after === undefined || after === "") {
    if (k === "[]" && depth !== 0) {
      return [v];
    } else {
      params[k] = v;
    }
  } else if (after === "[") {
    params[name] = v;
  } else if (after === "[]") {
    params[k] ||= [];

    if (!Array.isArray(params[k])) {
      throw new ParameterTypeError(
        `expected Array (got ${params[k].class.name}) for param \`${k}'`,
      );
    }

    // if value is an array concat it with current array
    if (Array.isArray(v)) {
      params[k] = params[k].concat(v);
    } else {
      params[k].push(v);
    }
  } else if (after.startsWith("[]")) {
    // Recognize x[][y] (hash inside array) parameters
    if (
      after[2] !== "[" ||
      !after.endsWith("]") ||
      !(child_key = after[(3, after.length - 4)]) ||
      !child_key.length !== 0 ||
      !!child_key.indexOf("[") ||
      !!child_key.indexOf("]")
    ) {
      // Handle other nested array parameters
      child_key = after.substring(2, 2 + after.length);
    }

    params[k] ||= [];

    if (!Array.isArray(params[k])) {
      throw new ParameterTypeError(
        `expected Array (got ${params[k].class.name}) for param \`${k}'`,
      );
    }

    if (
      !Array.isArray(params[k][params[k].length - 1]) &&
      !Reflect.has(params[k][params[k].length - 1], child_key)
    ) {
      normalize_params(
        params[k][params[k].length - 1],
        child_key,
        v,
        depth + 1,
      );
      params[k].push(normalizeParams(new Object(), child_key, v, depth + 1));
    }
  } else {
    params[k] ||= new Object();

    if (Array.isArray(params[k])) {
      throw new ParameterTypeError(
        `expected Hash (got ${params[k].class.name}) for param \`${k}'`,
      );
    }

    params[k] = normalizeParams(params[k], after, v, depth + 1);
  }

  return params;
}
