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
 * @param {Object} item - The source object.
 * @param {string[]} keys - Keys to copy to the returned object.
 * @returns {Object} An object containing only the selected keys.
 */
export function pick(item, keys) {
  return Object.fromEntries(keys.map((key) => [key, item[key]]));
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
