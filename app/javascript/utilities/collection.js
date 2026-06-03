/**
 * Splits an array into sub-arrays of the provided size.
 *
 * @param {Array} items - The array to split.
 * @param {number} size - The maximum size of each chunk.
 * @returns {Array[]} A new array containing chunked arrays.
 */
export function chunk(items, size) {
  const chunks = [];

  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }

  return chunks;
}

/**
 * Builds a new object containing only the provided keys from the source object.
 *
 * Keys that are not own properties of `item` are omitted from the result, so
 * the returned object never carries `undefined` placeholders for missing keys.
 * Matches the semantics of `lodash.pick`.
 *
 * @param {Object|null|undefined} item - The source object. `null` or `undefined` returns `{}`.
 * @param {string[]} keys - Keys to copy to the returned object.
 * @returns {Object} A new object containing only the selected own keys present on `item`.
 *
 * @example
 * pick({ id: 1, name: "Alice" }, ["id", "name", "role"]);
 * // => { id: 1, name: "Alice" }
 *
 * @example
 * pick(null, ["id"]);
 * // => {}
 */
export function pick(item, keys) {
  if (item == null) return {};

  return Object.fromEntries(
    keys
      .filter((key) => Object.prototype.hasOwnProperty.call(item, key))
      .map((key) => [key, item[key]]),
  );
}

/**
 * Builds a new object excluding entries that match the predicate.
 *
 * @param {Object} object - The source object.
 * @param {(value: any, key: string) => boolean} predicate - Returns true for entries to omit.
 * @returns {Object} An object containing entries that did not match the predicate.
 */

export function omitBy(object, predicate) {
  return Object.fromEntries(
    Object.entries(object).filter(([key, value]) => !predicate(value, key)),
  );
}
