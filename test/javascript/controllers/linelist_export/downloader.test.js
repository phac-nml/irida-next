import { beforeEach, describe, expect, it, vi } from "vitest";
import * as xlsx from "xlsx";

describe("linelist_export/downloader", () => {
  beforeEach(() => {
    xlsx.resetXlsxMock();
  });

  it("downloads CSV content with the requested filename", async () => {
    const { downloadExport } =
      await import("controllers/linelist_export/downloader");
    const appendChild = vi.spyOn(document.body, "appendChild");
    const createObjectURL = vi
      .spyOn(URL, "createObjectURL")
      .mockReturnValue("blob:linelist");
    const revokeObjectURL = vi.spyOn(URL, "revokeObjectURL").mockReturnValue();
    const click = vi
      .spyOn(HTMLAnchorElement.prototype, "click")
      .mockImplementation(() => {});

    await downloadExport("linelist.csv", "SAMPLE PUID\nINXT_SAM_1", "csv");

    const anchor = appendChild.mock.calls[0][0];
    expect(createObjectURL).toHaveBeenCalledWith(expect.any(Blob));
    expect(anchor.download).toBe("linelist.csv");
    expect(anchor.href).toBe("blob:linelist");
    expect(click).toHaveBeenCalledOnce();
    expect(revokeObjectURL).toHaveBeenCalledWith("blob:linelist");
  });

  it("converts XLSX rows to a spreadsheet Blob", async () => {
    const { xlsxRowsToBlob } =
      await import("controllers/linelist_export/downloader");

    const blob = await xlsxRowsToBlob([["SAMPLE PUID"], ["INXT_SAM_1"]]);

    expect(xlsx.utils.aoa_to_sheet).toHaveBeenCalledWith([
      ["SAMPLE PUID"],
      ["INXT_SAM_1"],
    ]);
    expect(xlsx.write).toHaveBeenCalledWith(expect.any(Object), {
      bookType: "xlsx",
      type: "array",
    });
    expect(blob).toBeInstanceOf(Blob);
    expect(blob.type).toBe(
      "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    );
  });

  it("rejects invalid XLSX row data before writing a workbook", async () => {
    const { xlsxRowsToBlob } =
      await import("controllers/linelist_export/downloader");

    await expect(xlsxRowsToBlob(new Blob(["not rows"]))).rejects.toThrow(
      "Invalid spreadsheet data received from export worker.",
    );
    expect(xlsx.write).not.toHaveBeenCalled();
  });
});
