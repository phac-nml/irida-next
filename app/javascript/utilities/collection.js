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
