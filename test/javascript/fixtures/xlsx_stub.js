// Test stub for the CDN-loaded `xlsx` library. The real library is provided via
// the import map in production and is not installed as an npm dependency, so
// tests alias the bare `xlsx` specifier here. Individual tests override this
// module with `vi.doMock("xlsx", ...)` to assert workbook building or to force
// a load failure.
export const utils = {
  book_new: () => ({}),
  aoa_to_sheet: () => ({}),
  book_append_sheet: () => {},
};

export function writeFile() {}

export default { utils, writeFile };
