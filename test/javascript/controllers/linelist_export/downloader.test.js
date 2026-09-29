import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  downloadExport,
  XlsxLibraryLoadError,
} from "../../../../app/javascript/controllers/linelist_export/downloader.js";

describe("linelist export downloader", () => {
  beforeEach(() => {
    vi.stubGlobal("URL", {
      ...URL,
      createObjectURL: vi.fn(() => "blob:mock"),
      revokeObjectURL: vi.fn(),
    });
  });

  afterEach(() => {
    vi.doUnmock("xlsx");
    vi.unstubAllGlobals();
    document.body.replaceChildren();
  });

  describe("csv", () => {
    it("creates a blob download and cleans up the object URL", async () => {
      const clicked = [];
      const clickSpy = vi
        .spyOn(HTMLAnchorElement.prototype, "click")
        .mockImplementation(function () {
          clicked.push({ href: this.href, download: this.download });
        });

      await downloadExport("linelist.csv", "a,b\n1,2");

      expect(URL.createObjectURL).toHaveBeenCalledOnce();
      expect(clicked).toEqual([
        { href: "blob:mock", download: "linelist.csv" },
      ]);
      expect(URL.revokeObjectURL).toHaveBeenCalledWith("blob:mock");
      expect(document.body.querySelector("a")).toBeNull();
      clickSpy.mockRestore();
    });

    it("defaults to the csv path when no format is provided", async () => {
      const clickSpy = vi
        .spyOn(HTMLAnchorElement.prototype, "click")
        .mockImplementation(() => {});

      await downloadExport("file.csv", "content");

      expect(URL.createObjectURL).toHaveBeenCalledOnce();
      clickSpy.mockRestore();
    });
  });

  describe("xlsx", () => {
    it("builds a workbook and writes the file via the xlsx library", async () => {
      const writeFile = vi.fn();
      const bookNew = vi.fn(() => ({ book: true }));
      const aoaToSheet = vi.fn(() => ({ sheet: true }));
      const bookAppendSheet = vi.fn();
      vi.doMock("xlsx", () => ({
        default: {},
        utils: {
          book_new: bookNew,
          aoa_to_sheet: aoaToSheet,
          book_append_sheet: bookAppendSheet,
        },
        writeFile,
      }));

      const rows = [
        ["A", "B"],
        ["1", "2"],
      ];
      await downloadExport("linelist.xlsx", rows, "xlsx");

      expect(aoaToSheet).toHaveBeenCalledWith(rows);
      expect(bookAppendSheet).toHaveBeenCalledWith(
        { book: true },
        { sheet: true },
        "linelist",
      );
      expect(writeFile).toHaveBeenCalledWith({ book: true }, "linelist.xlsx");
    });

    it("throws when the worksheet data is not an array", async () => {
      await expect(
        downloadExport("linelist.xlsx", "not-an-array", "xlsx"),
      ).rejects.toThrow(
        "Invalid spreadsheet data received from export worker.",
      );
    });

    it("throws XlsxLibraryLoadError when the library cannot be loaded", async () => {
      vi.doMock("xlsx", () => {
        throw new Error("module unavailable");
      });
      const error = await downloadExport(
        "linelist.xlsx",
        [["A"]],
        "xlsx",
      ).catch((caught) => caught);
      expect(error).toBeInstanceOf(XlsxLibraryLoadError);
      expect(error.name).toBe("XlsxLibraryLoadError");
    });
  });
});
