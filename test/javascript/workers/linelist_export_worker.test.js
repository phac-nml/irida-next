import {
  afterEach,
  beforeAll,
  beforeEach,
  describe,
  expect,
  it,
  vi,
} from "vitest";

// Importing the worker module registers its self.onmessage handler.
let handleMessage;

beforeAll(async () => {
  await import("../../../app/javascript/workers/linelist_export_worker.js");
  handleMessage = self.onmessage;
});

function jsonResponse(payload, { ok = true, status = 200 } = {}) {
  return { ok, status, json: async () => payload };
}

function sampleNode(prefix, id, overrides = {}) {
  return {
    id: `${prefix}${id}`,
    __typename: "Sample",
    puid: `PUID-${id}`,
    name: `Sample ${id}`,
    project: { puid: `PROJ-${id}` },
    metadata: {},
    ...overrides,
  };
}

describe("linelist export worker", () => {
  const prefix = "gid://irida/Sample/";
  let posted;

  beforeEach(() => {
    posted = [];
    vi.spyOn(self, "postMessage").mockImplementation((message) => {
      posted.push(message);
    });
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  const lastMessage = () => posted.at(-1);

  it("reports an error when no samples are selected", async () => {
    await handleMessage({ data: { sample_ids: [], graphql_url: "/graphql" } });
    expect(lastMessage()).toEqual({
      type: "error",
      message: "No samples were selected for export.",
    });
  });

  it("treats missing event data as an empty selection", async () => {
    await handleMessage({});
    expect(lastMessage()).toEqual({
      type: "error",
      message: "No samples were selected for export.",
    });
  });

  it("rejects unsupported formats", async () => {
    await handleMessage({
      data: { sample_ids: ["1"], graphql_url: "/graphql", format: "pdf" },
    });
    expect(lastMessage()).toEqual({
      type: "error",
      message: "Unsupported linelist format for this flow.",
    });
  });

  it("requires a GraphQL endpoint", async () => {
    await handleMessage({ data: { sample_ids: ["1"], format: "csv" } });
    expect(lastMessage()).toEqual({
      type: "error",
      message: "Missing GraphQL endpoint for linelist export.",
    });
  });

  it("errors when sample IDs cannot be converted without a prefix", async () => {
    await handleMessage({
      data: { sample_ids: ["1"], graphql_url: "/graphql", format: "csv" },
    });
    expect(lastMessage()).toEqual({
      type: "error",
      message: "Unable to build GraphQL sample IDs for export.",
    });
  });

  it("builds a CSV export, escaping special characters and blank values", async () => {
    const node = sampleNode(prefix, "1", {
      name: 'quote"name',
      metadata: { age: "1,2", country: "line\nbreak", missing: null },
    });
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(jsonResponse({ data: { nodes: [node] } })),
    );

    await handleMessage({
      data: {
        sample_ids: ["1"],
        metadata_fields: ["age", "country", "missing"],
        graphql_url: "/graphql",
        csrf_token: "token-1",
        sample_graphql_id_prefix: prefix,
        format: "csv",
        filename: "linelist.csv",
      },
    });

    const [url, options] = fetch.mock.calls[0];
    expect(url).toBe("/graphql");
    expect(options.headers["X-CSRF-Token"]).toBe("token-1");

    const progress = posted.find((m) => m.type === "progress");
    expect(progress).toMatchObject({ current: 1, total: 1, percentage: 100 });

    const done = lastMessage();
    expect(done.type).toBe("done");
    expect(done.filename).toBe("linelist.csv");
    expect(done.format).toBe("csv");
    expect(done.content).toBe(
      [
        "SAMPLE PUID,SAMPLE NAME,PROJECT PUID,AGE,COUNTRY,MISSING",
        'PUID-1,"quote""name",PROJ-1,"1,2","line\nbreak",',
      ].join("\n"),
    );
  });

  it("normalizes a null sample id to the bare prefix", async () => {
    const node = {
      id: prefix,
      __typename: "Sample",
      puid: "PUID-0",
      name: "Sample 0",
      project: { puid: "PROJ-0" },
      metadata: {},
    };
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(jsonResponse({ data: { nodes: [node] } })),
    );

    await handleMessage({
      data: {
        sample_ids: [null],
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "csv",
        filename: "linelist.csv",
      },
    });

    expect(lastMessage().type).toBe("done");
  });

  it("passes through gid:// identifiers and omits the CSRF header when absent", async () => {
    const node = sampleNode("", "gid://irida/Sample/9", { puid: "PUID-9" });
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(jsonResponse({ data: { nodes: [node] } })),
    );

    await handleMessage({
      data: {
        sample_ids: ["gid://irida/Sample/9"],
        graphql_url: "/graphql",
        format: "csv",
        filename: "linelist.csv",
      },
    });

    const [, options] = fetch.mock.calls[0];
    expect(options.headers["X-CSRF-Token"]).toBeUndefined();
    expect(lastMessage().type).toBe("done");
  });

  it("returns spreadsheet rows for the xlsx format", async () => {
    const node = sampleNode(prefix, "1", {
      project: null,
      metadata: null,
    });
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(jsonResponse({ data: { nodes: [node] } })),
    );

    await handleMessage({
      data: {
        sample_ids: ["1"],
        metadata_fields: ["age"],
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "xlsx",
        filename: "linelist.xlsx",
      },
    });

    const done = lastMessage();
    expect(done.format).toBe("xlsx");
    expect(done.content).toEqual([
      ["SAMPLE PUID", "SAMPLE NAME", "PROJECT PUID", "AGE"],
      ["PUID-1", "Sample 1", "", ""],
    ]);
  });

  it("fetches large selections in chunks and reports incremental progress", async () => {
    const ids = Array.from({ length: 150 }, (_, index) => String(index + 1));
    const fetchMock = vi.fn(async (_url, options) => {
      const { variables } = JSON.parse(options.body);
      const nodes = variables.ids.map((id) => ({
        id,
        __typename: "Sample",
        puid: id,
        name: id,
        project: { puid: id },
        metadata: {},
      }));
      return jsonResponse({ data: { nodes } });
    });
    vi.stubGlobal("fetch", fetchMock);

    await handleMessage({
      data: {
        sample_ids: ids,
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "csv",
        filename: "linelist.csv",
      },
    });

    expect(fetchMock).toHaveBeenCalledTimes(2);
    const progressMessages = posted.filter((m) => m.type === "progress");
    expect(progressMessages.map((m) => m.current)).toEqual([100, 150]);
    expect(lastMessage().type).toBe("done");
  });

  it("reports a network error when fetch rejects", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue(new Error("offline")));

    await handleMessage({
      data: {
        sample_ids: ["1"],
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "csv",
      },
    });

    expect(lastMessage()).toEqual({
      type: "error",
      message: "Network error while loading samples: offline",
    });
  });

  it("uses a generic network message when the rejection has no message", async () => {
    vi.stubGlobal("fetch", vi.fn().mockRejectedValue({}));

    await handleMessage({
      data: {
        sample_ids: ["1"],
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "csv",
      },
    });

    expect(lastMessage().message).toBe(
      "Network error while loading samples: request failed",
    );
  });

  it("reports non-OK GraphQL responses", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(jsonResponse({}, { ok: false, status: 503 })),
    );

    await handleMessage({
      data: {
        sample_ids: ["1"],
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "csv",
      },
    });

    expect(lastMessage()).toEqual({
      type: "error",
      message: "GraphQL request failed (503).",
    });
  });

  it("reports invalid JSON payloads", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        status: 200,
        json: async () => {
          throw new Error("bad json");
        },
      }),
    );

    await handleMessage({
      data: {
        sample_ids: ["1"],
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "csv",
      },
    });

    expect(lastMessage()).toEqual({
      type: "error",
      message: "GraphQL response was not valid JSON.",
    });
  });

  it("surfaces the first GraphQL error message", async () => {
    vi.stubGlobal(
      "fetch",
      vi
        .fn()
        .mockResolvedValue(
          jsonResponse({ errors: [{ message: "not authorized" }] }),
        ),
    );

    await handleMessage({
      data: {
        sample_ids: ["1"],
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "csv",
      },
    });

    expect(lastMessage()).toEqual({
      type: "error",
      message: "not authorized",
    });
  });

  it("uses a generic message when a GraphQL error has no message", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(jsonResponse({ errors: [{}] })),
    );

    await handleMessage({
      data: {
        sample_ids: ["1"],
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "csv",
      },
    });

    expect(lastMessage().message).toBe("GraphQL request failed.");
  });

  it("errors when the response omits sample nodes", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(jsonResponse({ data: {} })),
    );

    await handleMessage({
      data: {
        sample_ids: ["1"],
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "csv",
      },
    });

    expect(lastMessage()).toEqual({
      type: "error",
      message: "GraphQL response did not include sample nodes.",
    });
  });

  it("ignores non-sample nodes and errors on missing samples", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue(
        jsonResponse({
          data: { nodes: [{ __typename: "Project", id: "x" }] },
        }),
      ),
    );

    await handleMessage({
      data: {
        sample_ids: ["1"],
        graphql_url: "/graphql",
        sample_graphql_id_prefix: prefix,
        format: "csv",
      },
    });

    expect(lastMessage()).toEqual({
      type: "error",
      message: "One or more selected samples were not returned by GraphQL.",
    });
  });
});
