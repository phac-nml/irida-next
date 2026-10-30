import {
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from "vitest";
import { bulkUpdateSampleMetadata } from "../../../app/javascript/workers/linelist_import_worker.js";

const { mockDecodeRange, mockEncodeCell, mockRead, mockSheetToJson } =
  vi.hoisted(() => ({
    mockDecodeRange: vi.fn(),
    mockEncodeCell: vi.fn(),
    mockRead: vi.fn(),
    mockSheetToJson: vi.fn(),
  }));

vi.mock("xlsx", () => ({
  default: {
    read: mockRead,
    utils: {
      decode_range: mockDecodeRange,
      encode_cell: mockEncodeCell,
      sheet_to_json: mockSheetToJson,
    },
  },
}));

let handleMessage;

beforeAll(async () => {
  handleMessage = self.onmessage;
});

function jsonResponse(payload, { ok = true, status = 200 } = {}) {
  return { ok, status, json: async () => payload };
}

describe("linelist import worker", () => {
  let posted;

  beforeEach(() => {
    posted = [];
    mockEncodeCell.mockImplementation(({ r, c }) => `${r}:${c}`);
    vi.spyOn(self, "postMessage").mockImplementation((message) => {
      posted.push(message);
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const lastMessage = () => posted.at(-1);

  it("rejects an incomplete bulk update request before fetching", async () => {
    await expect(
      bulkUpdateSampleMetadata({ metadata: {}, groupId: "group-1" }),
    ).rejects.toThrow("Missing GraphQL endpoint for linelist import.");

    await expect(
      bulkUpdateSampleMetadata({
        graphqlUrl: "/graphql",
        metadata: null,
        groupId: "group-1",
      }),
    ).rejects.toThrow("Metadata payload is required for import.");

    await expect(
      bulkUpdateSampleMetadata({ graphqlUrl: "/graphql", metadata: {} }),
    ).rejects.toThrow(
      "One of groupId, groupPuid, projectId, or projectPuid is required.",
    );
  });

  it("posts the selected namespace and returns the mutation result", async () => {
    const fetchMock = vi
      .fn()
      .mockResolvedValue(
        jsonResponse({ data: { bulkUpdateSampleMetadata: { status: "ok" } } }),
      );
    vi.stubGlobal("fetch", fetchMock);

    const result = await bulkUpdateSampleMetadata({
      graphqlUrl: "/graphql",
      csrfToken: "csrf-token",
      metadata: { country: "Canada" },
      groupId: "group-1",
      projectId: "project-1",
    });

    expect(result).toEqual({ status: "ok" });
    const [url, options] = fetchMock.mock.calls[0];
    const body = JSON.parse(options.body);
    expect(url).toBe("/graphql");
    expect(options.headers).toMatchObject({
      "Content-Type": "application/json",
      "X-CSRF-Token": "csrf-token",
    });
    expect(body.operationName).toBe("BulkUpdateSampleMetadata");
    expect(body.variables).toEqual({
      metadata: { country: "Canada" },
      groupId: "group-1",
    });
    expect(body.query).toContain("$groupId: ID!");
  });

  it.each([
    ["groupPuid", "group-puid-1"],
    ["projectId", "project-1"],
    ["projectPuid", "project-puid-1"],
  ])("supports the %s namespace", async (field, value) => {
    const fetchMock = vi
      .fn()
      .mockResolvedValue(
        jsonResponse({ data: { bulkUpdateSampleMetadata: {} } }),
      );
    vi.stubGlobal("fetch", fetchMock);

    await bulkUpdateSampleMetadata({
      graphqlUrl: "/graphql",
      metadata: { country: "Canada" },
      [field]: value,
    });

    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.variables[field]).toBe(value);
  });

  it("reports network failures, invalid JSON, and GraphQL errors", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("offline")));
    await expect(
      bulkUpdateSampleMetadata({
        graphqlUrl: "/graphql",
        metadata: {},
        groupId: "group-1",
      }),
    ).rejects.toThrow("Network error while updating sample metadata: offline");

    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        json: async () => {
          throw new Error("bad json");
        },
      }),
    );
    await expect(
      bulkUpdateSampleMetadata({
        graphqlUrl: "/graphql",
        metadata: {},
        groupId: "group-1",
      }),
    ).rejects.toThrow("GraphQL response was not valid JSON.");

    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(jsonResponse({ errors: [{}] })),
    );
    await expect(
      bulkUpdateSampleMetadata({
        graphqlUrl: "/graphql",
        metadata: {},
        groupId: "group-1",
      }),
    ).rejects.toThrow("GraphQL request failed.");
  });

  it("uses a generic message when a network failure has no message", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue({}));

    await expect(
      bulkUpdateSampleMetadata({
        graphqlUrl: "/graphql",
        metadata: {},
        groupId: "group-1",
      }),
    ).rejects.toThrow(
      "Network error while updating sample metadata: request failed",
    );
  });

  it("reports unsupported MIME types without fetching", async () => {
    const fetchMock = vi.fn();
    vi.stubGlobal("fetch", fetchMock);

    await handleMessage({
      data: { mime_type: "application/pdf", rows: [] },
    });

    expect(lastMessage()).toEqual({
      type: "error",
      message: "Unsupported linelist format.",
    });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("treats missing event data as an unsupported format", async () => {
    await handleMessage({});

    expect(lastMessage()).toEqual({
      type: "error",
      message: "Unsupported linelist format.",
    });
  });

  it("reads spreadsheet headers in the worker", async () => {
    const file = { arrayBuffer: async () => new ArrayBuffer(0) };
    mockRead.mockReturnValue({
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: {} },
    });
    mockSheetToJson.mockReturnValue([["sample_id", "country"]]);

    await handleMessage({ data: { type: "read_headers", file } });

    expect(lastMessage()).toEqual({
      type: "headers",
      headers: ["sample_id", "country"],
    });
  });

  it("returns empty headers when the worksheet has no header row", async () => {
    const file = { arrayBuffer: async () => new ArrayBuffer(0) };
    mockRead.mockReturnValue({
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: {} },
    });
    mockSheetToJson.mockReturnValue([]);

    await handleMessage({ data: { type: "read_headers", file } });

    expect(lastMessage()).toEqual({ type: "headers", headers: [] });
  });

  it("reports a fallback error when reading headers fails without a message", async () => {
    const file = { arrayBuffer: async () => Promise.reject({}) };

    await handleMessage({ data: { type: "read_headers", file } });

    expect(lastMessage()).toEqual({
      type: "error",
      message: "Unable to read the uploaded spreadsheet.",
    });
  });

  it("imports file rows in bounded batches without receiving a rows array", async () => {
    const file = { arrayBuffer: async () => new ArrayBuffer(0) };
    const worksheet = { "!ref": "A1:C102" };
    ["sample_id", "country", "batch"].forEach((value, column) => {
      worksheet[`0:${column}`] = { v: value };
    });
    Array.from({ length: 101 }, (_, index) => {
      worksheet[`${index + 1}:0`] = { v: `sample_${index}` };
      worksheet[`${index + 1}:1`] = { v: "Canada" };
      worksheet[`${index + 1}:2`] = { v: index };
    });
    mockRead.mockReturnValue({
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: worksheet },
    });
    mockSheetToJson.mockReturnValue([["sample_id", "country", "batch"]]);
    mockDecodeRange.mockReturnValue({ s: { r: 0, c: 0 }, e: { r: 101, c: 2 } });
    const fetchMock = vi.fn().mockResolvedValue(
      jsonResponse({
        data: { bulkUpdateSampleMetadata: { overallStatus: "ok" } },
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await handleMessage({
      data: {
        mime_type: "text/csv",
        graphql_url: "/graphql",
        project_puid: "project-1",
        file,
        sample_id_column: "sample_id",
        metadata_columns: ["country", "batch"],
        ignore_empty_values: true,
      },
    });

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(lastMessage()).toEqual({ type: "done" });

    const firstBody = JSON.parse(fetchMock.mock.calls[0][1].body);
    const secondBody = JSON.parse(fetchMock.mock.calls[1][1].body);
    expect(Object.keys(firstBody.variables.metadata)).toHaveLength(100);
    expect(secondBody.variables.metadata).toEqual({
      sample_100: { country: "Canada", batch: 100 },
    });
  });

  it("imports missing cell values when empty values are selected", async () => {
    const file = { arrayBuffer: async () => new ArrayBuffer(0) };
    const worksheet = {};
    mockRead.mockReturnValue({
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: worksheet },
    });
    mockSheetToJson.mockReturnValue([["sample_id", "country"]]);
    mockDecodeRange.mockReturnValue({ s: { r: 0, c: 0 }, e: { r: 1, c: 1 } });
    const fetchMock = vi.fn().mockResolvedValue(
      jsonResponse({
        data: { bulkUpdateSampleMetadata: { overallStatus: "ok" } },
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await handleMessage({
      data: {
        mime_type: "text/csv",
        graphql_url: "/graphql",
        project_puid: "project-1",
        file,
        sample_id_column: "sample_id",
        metadata_columns: ["country"],
        ignore_empty_values: false,
      },
    });

    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.variables.metadata).toEqual({ null: { country: null } });
  });

  it("omits missing metadata values when empty values are ignored", async () => {
    const file = { arrayBuffer: async () => new ArrayBuffer(0) };
    const worksheet = {};
    mockRead.mockReturnValue({
      SheetNames: ["Sheet1"],
      Sheets: { Sheet1: worksheet },
    });
    mockSheetToJson.mockReturnValue([["sample_id", "country"]]);
    mockDecodeRange.mockReturnValue({ s: { r: 0, c: 0 }, e: { r: 1, c: 1 } });
    const fetchMock = vi.fn().mockResolvedValue(
      jsonResponse({
        data: { bulkUpdateSampleMetadata: { overallStatus: "ok" } },
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await handleMessage({
      data: {
        mime_type: "text/csv",
        graphql_url: "/graphql",
        project_puid: "project-1",
        file,
        sample_id_column: "sample_id",
        metadata_columns: ["country"],
        ignore_empty_values: true,
      },
    });

    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.variables.metadata).toEqual({ null: {} });
  });

  it("imports rows in chunks and reports progress before completion", async () => {
    const rows = Array.from({ length: 101 }, (_, index) => [
      `sample_${index}`,
      `value_${index}`,
    ]);
    const fetchMock = vi.fn().mockResolvedValue(
      jsonResponse({
        data: { bulkUpdateSampleMetadata: { overallStatus: "ok" } },
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await handleMessage({
      data: {
        mime_type: "text/csv",
        graphql_url: "/graphql",
        project_puid: "project-1",
        rows,
      },
    });

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(posted).toEqual([
      {
        type: "progress",
        current: 100,
        total: 101,
        result: { overallStatus: "ok" },
      },
      {
        type: "progress",
        current: 101,
        total: 101,
        result: { overallStatus: "ok" },
      },
      { type: "done" },
    ]);

    const firstBody = JSON.parse(fetchMock.mock.calls[0][1].body);
    const secondBody = JSON.parse(fetchMock.mock.calls[1][1].body);
    expect(Object.keys(firstBody.variables.metadata)).toHaveLength(100);
    expect(secondBody.variables.metadata).toEqual({ sample_100: "value_100" });
    expect(secondBody.variables.projectPuid).toBe("project-1");
  });

  it("does not send an empty final batch", async () => {
    const rows = Array.from({ length: 100 }, (_, index) => [
      `sample_${index}`,
      `value_${index}`,
    ]);
    const fetchMock = vi.fn().mockResolvedValue(
      jsonResponse({
        data: { bulkUpdateSampleMetadata: { overallStatus: "ok" } },
      }),
    );
    vi.stubGlobal("fetch", fetchMock);

    await handleMessage({
      data: {
        mime_type: "text/csv",
        graphql_url: "/graphql",
        project_puid: "project-1",
        rows,
      },
    });

    expect(fetchMock).toHaveBeenCalledTimes(1);
    expect(posted).toEqual([
      {
        type: "progress",
        current: 100,
        total: 100,
        result: { overallStatus: "ok" },
      },
      { type: "done" },
    ]);
  });

  it("retries a transient batch failure before continuing", async () => {
    vi.useFakeTimers();
    const fetchMock = vi
      .fn()
      .mockRejectedValueOnce(new Error("offline"))
      .mockResolvedValueOnce(
        jsonResponse({
          data: { bulkUpdateSampleMetadata: { overallStatus: "ok" } },
        }),
      );
    vi.stubGlobal("fetch", fetchMock);

    const importPromise = handleMessage({
      data: {
        mime_type: "text/csv",
        graphql_url: "/graphql",
        project_puid: "project-1",
        rows: [["sample_1", { country: "Canada" }]],
      },
    });

    await vi.runAllTimersAsync();
    await importPromise;

    expect(fetchMock).toHaveBeenCalledTimes(2);
    expect(posted).toEqual([
      { type: "retry", current: 0, total: 1, attempt: 1, maxAttempts: 3 },
      {
        type: "progress",
        current: 1,
        total: 1,
        result: { overallStatus: "ok" },
      },
      { type: "done" },
    ]);
  });

  it("stops after retryable rate-limit failures are exhausted", async () => {
    vi.useFakeTimers();
    const fetchMock = vi
      .fn()
      .mockResolvedValue(jsonResponse({}, { ok: false, status: 429 }));
    vi.stubGlobal("fetch", fetchMock);

    const importPromise = handleMessage({
      data: {
        mime_type: "text/csv",
        graphql_url: "/graphql",
        project_puid: "project-1",
        rows: [["sample_1", { country: "Canada" }]],
      },
    });

    await vi.runAllTimersAsync();
    await importPromise;

    expect(fetchMock).toHaveBeenCalledTimes(4);
    expect(posted.filter(({ type }) => type === "retry")).toHaveLength(3);
    expect(lastMessage()).toEqual({
      type: "error",
      message: "GraphQL request failed (429).",
    });
  });

  it("posts a worker error when the import request fails", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(jsonResponse({}, { ok: false, status: 422 })),
    );

    await handleMessage({
      data: {
        mime_type: "text/tab-separated-values",
        graphql_url: "/graphql",
        group_id: "group-1",
        rows: [["country", "Canada"]],
      },
    });

    expect(lastMessage()).toEqual({
      type: "error",
      message: "GraphQL request failed (422).",
    });
  });

  it("uses a generic message for unexpected errors without a message", async () => {
    const rows = {
      get length() {
        throw {};
      },
    };

    await handleMessage({
      data: {
        mime_type: "text/csv",
        graphql_url: "/graphql",
        group_id: "group-1",
        rows,
      },
    });

    expect(lastMessage()).toEqual({
      type: "error",
      message: "Unexpected error while importing metadata.",
    });
  });
});
