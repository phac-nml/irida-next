import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import spreadsheet from "xlsx";
import "../../../app/javascript/workers/linelist_import_worker.js";

// The shared Vitest configuration aliases xlsx to a stub. Exercise the installed
// parser here so blank CSV/XLSX cells have their real spreadsheet representation.
vi.mock("xlsx", async () => {
  const { createRequire } = await import("node:module");
  return { default: createRequire(import.meta.url)("xlsx") };
});

const handleMessage = self.onmessage;
const result = { overallStatus: "successful", errors: [] };

function fileFromRows(rows, format) {
  const workbook = spreadsheet.utils.book_new();
  const worksheet = spreadsheet.utils.aoa_to_sheet(rows);
  spreadsheet.utils.book_append_sheet(workbook, worksheet, "Sheet1");
  const buffer = spreadsheet.write(workbook, {
    type: "array",
    bookType: format,
  });
  return { arrayBuffer: async () => buffer };
}

describe("linelist import worker with real spreadsheets", () => {
  let fetchMock;
  let posted;

  beforeEach(() => {
    posted = [];
    vi.spyOn(self, "postMessage").mockImplementation((message) =>
      posted.push(message),
    );
    fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      json: async () => ({ data: { bulkUpdateSampleMetadata: result } }),
    });
    vi.stubGlobal("fetch", fetchMock);
  });

  afterEach(() => {
    vi.restoreAllMocks();
    vi.unstubAllGlobals();
  });

  async function importRows(rows, format, ignoreEmptyValues) {
    await handleMessage({
      data: {
        mime_type:
          format === "csv"
            ? "text/csv"
            : "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        graphql_url: "/graphql",
        project_puid: "project-1",
        file: fileFromRows(rows, format),
        sample_id_column: "sample_id",
        metadata_columns: ["country"],
        ignore_empty_values: ignoreEmptyValues,
      },
    });
  }

  it.each([
    ["csv", true],
    ["csv", false],
    ["xlsx", true],
    ["xlsx", false],
  ])(
    "skips blank %s rows and counts only records (ignore empty: %s)",
    async (format, ignoreEmptyValues) => {
      await importRows(
        [
          ["sample_id", "country"],
          [],
          ["sample_1", "Canada"],
          [null, null],
          ["sample_2", "France"],
          [],
        ],
        format,
        ignoreEmptyValues,
      );

      expect(fetchMock).toHaveBeenCalledTimes(1);
      expect(
        JSON.parse(fetchMock.mock.calls[0][1].body).variables.metadata,
      ).toEqual({
        sample_1: { country: "Canada" },
        sample_2: { country: "France" },
      });
      expect(posted).toEqual([
        { type: "progress", current: 2, total: 2, result },
        { type: "done" },
      ]);
    },
  );

  it("keeps batches at 100 records across blank rows", async () => {
    const rows = [["sample_id", "country"]];
    for (let i = 0; i < 101; i += 1) rows.push([], [`sample_${i}`, "Canada"]);
    await importRows(rows, "xlsx", true);

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(
      Object.keys(
        JSON.parse(fetchMock.mock.calls[0][1].body).variables.metadata,
      ),
    ).toHaveLength(100);
    expect(
      JSON.parse(fetchMock.mock.calls[1][1].body).variables.metadata,
    ).toEqual({
      sample_100: { country: "Canada" },
    });
    expect(posted).toEqual([
      { type: "progress", current: 100, total: 101, result },
      { type: "progress", current: 101, total: 101, result },
      { type: "done" },
    ]);
  });

  it.each([true, false])(
    "preserves incomplete rows and falsy values (ignore empty: %s)",
    async (ignoreEmptyValues) => {
      await importRows(
        [
          ["sample_id", "country", "unselected"],
          ["sample_1"],
          [null, "Canada"],
          ["sample_0", 0],
          ["sample_false", false],
          ["sample_unselected", null, "keep this row"],
        ],
        "xlsx",
        ignoreEmptyValues,
      );

      const emptyMetadata = ignoreEmptyValues ? {} : { country: null };
      expect(
        JSON.parse(fetchMock.mock.calls[0][1].body).variables.metadata,
      ).toEqual({
        sample_1: emptyMetadata,
        null: { country: "Canada" },
        sample_0: { country: 0 },
        sample_false: { country: false },
        sample_unselected: emptyMetadata,
      });
      expect(posted[0]).toMatchObject({ current: 5, total: 5 });
    },
  );

  it("keeps rows with values only in unselected columns for validation", async () => {
    await importRows(
      [
        ["sample_id", "country", "unselected"],
        [null, null, "keep this row"],
      ],
      "xlsx",
      true,
    );

    expect(
      JSON.parse(fetchMock.mock.calls[0][1].body).variables.metadata,
    ).toEqual({ null: {} });
    expect(posted[0]).toMatchObject({ current: 1, total: 1 });
  });

  it("does not send requests for a worksheet containing only headers and blank rows", async () => {
    await importRows(
      [["sample_id", "country"], [], [null, null]],
      "csv",
      false,
    );

    expect(fetchMock).not.toHaveBeenCalled();
    expect(posted).toEqual([{ type: "done" }]);
  });
});
