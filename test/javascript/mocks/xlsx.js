import { vi } from "vitest";

export const utils = {
  book_new: vi.fn(() => ({ sheets: [] })),
  aoa_to_sheet: vi.fn((rows) => ({ rows })),
  book_append_sheet: vi.fn((workbook, worksheet, name) => {
    workbook.sheets.push({ worksheet, name });
  }),
};

export const write = vi.fn(() => new Uint8Array([1, 2, 3]));
export const writeFile = vi.fn();

export function resetXlsxMock() {
  utils.book_new.mockClear();
  utils.aoa_to_sheet.mockClear();
  utils.book_append_sheet.mockClear();
  write.mockClear();
  writeFile.mockClear();
}
