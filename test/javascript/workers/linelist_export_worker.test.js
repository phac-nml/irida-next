import { beforeEach, describe, expect, it, vi } from "vitest";

const loadWorker = async () => {
  vi.resetModules();
  self.postMessage = vi.fn();
  await import("workers/linelist_export_worker");
};

const jsonResponse = (payload, status = 200) =>
  new Response(JSON.stringify(payload), {
    status,
    headers: { "Content-Type": "application/json" },
  });

const sampleRow = (id, puid = id) => ({
  id: `gid://irida/Sample/${id}`,
  __typename: "LinelistSampleExportRow",
  puid,
  name: `sample-${id}`,
  metadata: {
    country: `country-${id}`,
    empty: null,
  },
  project: {
    puid: `project-${id}`,
  },
});

describe("linelist_export_worker", () => {
  beforeEach(async () => {
    vi.stubGlobal("fetch", vi.fn());
    await loadWorker();
  });

  it("builds CSV content from GraphQL rows in the selected sample order", async () => {
    fetch.mockResolvedValue(
      jsonResponse({
        data: {
          linelistExportRows: [sampleRow("2"), sampleRow("1")],
        },
      }),
    );

    await self.onmessage({
      data: {
        sample_ids: ["1", "2"],
        metadata_fields: ["country", "missing"],
        namespace_id: "10",
        graphql_url: "/-/graphql",
        csrf_token: "token",
        sample_graphql_id_prefix: "gid://irida/Sample/",
        format: "csv",
        filename: "linelist.csv",
      },
    });

    expect(fetch).toHaveBeenCalledWith(
      "/-/graphql",
      expect.objectContaining({
        method: "POST",
        credentials: "same-origin",
        headers: expect.objectContaining({ "X-CSRF-Token": "token" }),
      }),
    );
    expect(self.postMessage).toHaveBeenCalledWith({
      type: "progress",
      current: 2,
      total: 2,
      percentage: 100,
    });
    expect(self.postMessage).toHaveBeenLastCalledWith({
      type: "done",
      filename: "linelist.csv",
      format: "csv",
      content: [
        "SAMPLE PUID,SAMPLE NAME,PROJECT PUID,COUNTRY,MISSING",
        "1,sample-1,project-1,country-1,",
        "2,sample-2,project-2,country-2,",
      ].join("\n"),
    });
  });

  it("returns XLSX exports as spreadsheet rows for the controller to write", async () => {
    fetch.mockResolvedValue(
      jsonResponse({
        data: {
          linelistExportRows: [sampleRow("1", "INXT_SAM_1")],
        },
      }),
    );

    await self.onmessage({
      data: {
        sample_ids: ["1"],
        metadata_fields: ["country"],
        namespace_id: "10",
        graphql_url: "/-/graphql",
        sample_graphql_id_prefix: "gid://irida/Sample/",
        format: "xlsx",
        filename: "linelist.xlsx",
      },
    });

    expect(self.postMessage).toHaveBeenLastCalledWith({
      type: "done",
      filename: "linelist.xlsx",
      format: "xlsx",
      content: [
        ["SAMPLE PUID", "SAMPLE NAME", "PROJECT PUID", "COUNTRY"],
        ["INXT_SAM_1", "sample-1", "project-1", "country-1"],
      ],
    });
  });

  it("loads samples in chunks and reports progress for each chunk", async () => {
    fetch
      .mockResolvedValueOnce(
        jsonResponse({
          data: {
            linelistExportRows: Array.from({ length: 100 }, (_, index) =>
              sampleRow(String(index + 1)),
            ),
          },
        }),
      )
      .mockResolvedValueOnce(
        jsonResponse({
          data: {
            linelistExportRows: [sampleRow("101")],
          },
        }),
      );

    await self.onmessage({
      data: {
        sample_ids: Array.from({ length: 101 }, (_, index) =>
          String(index + 1),
        ),
        metadata_fields: [],
        namespace_id: "10",
        graphql_url: "/-/graphql",
        sample_graphql_id_prefix: "gid://irida/Sample/",
        format: "csv",
        filename: "linelist.csv",
      },
    });

    const progressMessages = self.postMessage.mock.calls
      .map(([message]) => message)
      .filter((message) => message.type === "progress");

    expect(fetch).toHaveBeenCalledTimes(2);
    expect(progressMessages).toEqual([
      {
        type: "progress",
        current: 100,
        total: 101,
        percentage: (100 / 101) * 100,
      },
      { type: "progress", current: 101, total: 101, percentage: 100 },
    ]);
  });

  it("direct-uploads CSV content and creates a saved data export", async () => {
    fetch.mockImplementation(async (url, options = {}) => {
      if (options.method === "PUT") return new Response("", { status: 200 });

      const body = JSON.parse(options.body);
      if (body.operationName === "LinelistSamplesForExport") {
        return jsonResponse({
          data: { linelistExportRows: [sampleRow("1", "INXT_SAM_1")] },
        });
      }
      if (body.operationName === "CreateDirectUpload") {
        return jsonResponse({
          data: {
            createDirectUpload: {
              directUpload: {
                url: "/rails/active_storage/direct_uploads/blob",
                headers: JSON.stringify({ "Content-Type": "text/csv" }),
                signedBlobId: "signed-blob",
              },
            },
          },
        });
      }
      if (body.operationName === "CreateLinelistDataExport") {
        return jsonResponse({
          data: {
            createLinelistDataExport: {
              id: "123",
              url: "/-/data_exports/123",
              errors: [],
            },
          },
        });
      }

      throw new Error(`Unexpected operation ${body.operationName}`);
    });

    await self.onmessage({
      data: {
        sample_ids: ["1"],
        metadata_fields: ["country"],
        namespace_id: "10",
        graphql_url: "/-/graphql",
        csrf_token: "token",
        sample_graphql_id_prefix: "gid://irida/Sample/",
        save_to_server: true,
        upload_metadata: {
          name: "saved linelist",
          namespaceId: "10",
          sampleIds: ["1"],
          metadataFields: ["country"],
        },
        format: "csv",
        filename: "linelist.csv",
      },
    });

    expect(fetch).toHaveBeenCalledWith(
      "/rails/active_storage/direct_uploads/blob",
      expect.objectContaining({
        method: "PUT",
        headers: { "Content-Type": "text/csv" },
        body: expect.any(Blob),
      }),
    );
    expect(self.postMessage).toHaveBeenLastCalledWith({
      type: "server_saved",
      filename: "linelist.csv",
      format: "csv",
      content: [
        "SAMPLE PUID,SAMPLE NAME,PROJECT PUID,COUNTRY",
        "INXT_SAM_1,sample-1,project-1,country-1",
      ].join("\n"),
      serverResponse: { id: "123", url: "/-/data_exports/123" },
    });
  });

  it("returns upload_error with local content when save-to-server fails", async () => {
    fetch.mockImplementation(async (_url, options = {}) => {
      if (options.method === "PUT") return new Response("", { status: 200 });

      const body = JSON.parse(options.body);
      if (body.operationName === "CreateDirectUpload") {
        return jsonResponse({
          data: {
            createDirectUpload: {
              directUpload: {
                url: "/upload",
                headers: "{}",
                signedBlobId: "signed-blob",
              },
            },
          },
        });
      }
      if (body.operationName === "CreateLinelistDataExport") {
        return jsonResponse({
          data: {
            createLinelistDataExport: {
              id: null,
              url: null,
              errors: [{ message: "Unable to save export." }],
            },
          },
        });
      }

      throw new Error(`Unexpected operation ${body.operationName}`);
    });

    await self.onmessage({
      data: {
        action: "upload_to_server",
        graphql_url: "/-/graphql",
        filename: "linelist.csv",
        format: "csv",
        content: "SAMPLE PUID\nINXT_SAM_1",
        upload_metadata: {
          namespaceId: "10",
          sampleIds: ["1"],
          metadataFields: [],
        },
      },
    });

    expect(self.postMessage).toHaveBeenLastCalledWith({
      type: "upload_error",
      filename: "linelist.csv",
      format: "csv",
      content: "SAMPLE PUID\nINXT_SAM_1",
      message: "Unable to save export.",
    });
  });
});
