import spreadsheet from "xlsx";

const ROW_CHUNK_SIZE = 100;
const MAX_RETRY_ATTEMPTS = 3;
const RETRY_DELAY_MS = 250;
const SUPPORTED_MIME_TYPES = [
  "text/csv",
  "text/tab-separated-values",
  "application/vnd.ms-excel",
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
];

const buildBulkUpdateSampleMetadataMutation = (namespaceField) => `
  mutation BulkUpdateSampleMetadata($metadata: JSON!, $${namespaceField}: ID!) {
    bulkUpdateSampleMetadata(
      input: {
        metadata: $metadata
        ${namespaceField}: $${namespaceField}
      }
    ) {
      overallStatus
      status
      errors {
        path
        message
      }
    }
  }
`;

const namespaceSelection = ({ groupId, groupPuid, projectId, projectPuid }) => {
  if (groupId) return { field: "groupId", value: groupId };
  if (groupPuid) return { field: "groupPuid", value: groupPuid };
  if (projectId) return { field: "projectId", value: projectId };
  if (projectPuid) return { field: "projectPuid", value: projectPuid };

  return null;
};

const retryableError = (message, cause) => {
  const error = new Error(message, { cause });
  error.retryable = true;

  return error;
};

const postGraphql = async ({
  graphqlUrl,
  query,
  variables,
  operationName,
  csrfToken,
}) => {
  let response;

  try {
    response = await fetch(graphqlUrl, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/graphql-response+json, application/json",
        ...(csrfToken ? { "X-CSRF-Token": csrfToken } : {}),
      },
      body: JSON.stringify({ query, variables, operationName }),
    });
  } catch (error) {
    throw retryableError(
      `Network error while updating sample metadata: ${error?.message || "request failed"}`,
      error,
    );
  }

  if (!response.ok) {
    if (response.status === 429 || response.status >= 500) {
      throw retryableError(`GraphQL request failed (${response.status}).`);
    }

    throw new Error(`GraphQL request failed (${response.status}).`);
  }

  let payload;

  try {
    payload = await response.json();
  } catch {
    throw new Error("GraphQL response was not valid JSON.");
  }

  if (Array.isArray(payload?.errors) && payload.errors.length > 0) {
    const firstMessage = payload.errors[0]?.message;
    throw new Error(firstMessage || "GraphQL request failed.");
  }

  return payload;
};

export const bulkUpdateSampleMetadata = async ({
  graphqlUrl,
  csrfToken,
  metadata,
  groupId,
  groupPuid,
  projectId,
  projectPuid,
}) => {
  if (!graphqlUrl) {
    throw new Error("Missing GraphQL endpoint for linelist import.");
  }

  if (!metadata || typeof metadata !== "object") {
    throw new Error("Metadata payload is required for import.");
  }

  const selectedNamespace = namespaceSelection({
    groupId,
    groupPuid,
    projectId,
    projectPuid,
  });

  if (!selectedNamespace) {
    throw new Error(
      "One of groupId, groupPuid, projectId, or projectPuid is required.",
    );
  }

  const variables = {
    metadata,
    [selectedNamespace.field]: selectedNamespace.value,
  };

  const payload = await postGraphql({
    graphqlUrl,
    query: buildBulkUpdateSampleMetadataMutation(selectedNamespace.field),
    variables,
    operationName: "BulkUpdateSampleMetadata",
    csrfToken,
  });

  return payload?.data?.bulkUpdateSampleMetadata;
};

const workbookFromFile = async (file) => {
  const workbook = spreadsheet.read(await file.arrayBuffer());
  const worksheetName = workbook.SheetNames[0];

  return workbook.Sheets[worksheetName];
};

const worksheetHeaders = (worksheet) =>
  spreadsheet.utils.sheet_to_json(worksheet, { header: 1 })[0] || [];

const rowValue = (worksheet, row, column) =>
  worksheet[spreadsheet.utils.encode_cell({ r: row, c: column })]?.v ?? null;

const spreadsheetRows = function* ({
  worksheet,
  headers,
  sampleIdColumn,
  metadataColumns,
  ignoreEmptyValues,
}) {
  const range = spreadsheet.utils.decode_range(worksheet["!ref"] || "A1");
  const headerIndexes = new Map(
    headers.map((header, index) => [header, index]),
  );
  const sampleIdColumnIndex = headerIndexes.get(sampleIdColumn);

  for (let row = range.s.r + 1; row <= range.e.r; row += 1) {
    const metadata = {};

    metadataColumns.forEach((column) => {
      const value = rowValue(worksheet, row, headerIndexes.get(column));
      if (!ignoreEmptyValues || value != null) metadata[column] = value;
    });

    yield [rowValue(worksheet, row, sampleIdColumnIndex), metadata];
  }
};

const importRowChunks = async ({
  rows,
  graphqlUrl,
  csrfToken,
  groupId,
  groupPuid,
  projectId,
  projectPuid,
  total,
}) => {
  let importedCount = 0;
  let rowChunk = [];

  for (const row of rows) {
    rowChunk.push(row);
    if (rowChunk.length < ROW_CHUNK_SIZE) continue;

    const result = await importRowChunkWithRetry({
      rowChunk,
      graphqlUrl,
      csrfToken,
      groupId,
      groupPuid,
      projectId,
      projectPuid,
      current: importedCount,
      total,
    });
    importedCount += rowChunk.length;
    self.postMessage({
      type: "progress",
      current: importedCount,
      total,
      result,
    });
    rowChunk = [];
  }

  if (rowChunk.length > 0) {
    const result = await importRowChunkWithRetry({
      rowChunk,
      graphqlUrl,
      csrfToken,
      groupId,
      groupPuid,
      projectId,
      projectPuid,
      current: importedCount,
      total,
    });
    importedCount += rowChunk.length;
    self.postMessage({
      type: "progress",
      current: importedCount,
      total,
      result,
    });
  }
};

const importRowChunk = async ({
  rowChunk,
  graphqlUrl,
  csrfToken,
  groupId,
  groupPuid,
  projectId,
  projectPuid,
}) => {
  if (rowChunk.length === 0) return null;

  return bulkUpdateSampleMetadata({
    graphqlUrl,
    csrfToken,
    metadata: Object.fromEntries(rowChunk),
    groupId,
    groupPuid,
    projectId,
    projectPuid,
  });
};

const importRowChunkWithRetry = async ({ current, total, ...options }) => {
  for (let attempt = 0; ; attempt += 1) {
    try {
      return await importRowChunk(options);
    } catch (error) {
      if (!error.retryable || attempt >= MAX_RETRY_ATTEMPTS) throw error;

      self.postMessage({
        type: "retry",
        current,
        total,
        attempt: attempt + 1,
        maxAttempts: MAX_RETRY_ATTEMPTS,
      });
      await new Promise((resolve) => {
        setTimeout(resolve, RETRY_DELAY_MS * 2 ** attempt);
      });
    }
  }
};

self.onmessage = async (event) => {
  const {
    type,
    csrf_token: csrfToken,
    mime_type: mimeType,
    graphql_url: graphqlUrl,
    group_id: groupId,
    group_puid: groupPuid,
    project_id: projectId,
    project_puid: projectPuid,
    rows,
    file,
    sample_id_column: sampleIdColumn,
    metadata_columns: metadataColumns,
    ignore_empty_values: ignoreEmptyValues,
  } = event.data || {};

  if (type === "read_headers") {
    try {
      const worksheet = await workbookFromFile(file);
      self.postMessage({
        type: "headers",
        headers: worksheetHeaders(worksheet),
      });
    } catch (error) {
      self.postMessage({
        type: "error",
        message: error?.message || "Unable to read the uploaded spreadsheet.",
      });
    }
    return;
  }

  if (!SUPPORTED_MIME_TYPES.includes(mimeType)) {
    self.postMessage({
      type: "error",
      message: "Unsupported linelist format.",
    });
    return;
  }

  try {
    if (file) {
      const worksheet = await workbookFromFile(file);
      const headers = worksheetHeaders(worksheet);
      const range = spreadsheet.utils.decode_range(worksheet["!ref"] || "A1");
      await importRowChunks({
        rows: spreadsheetRows({
          worksheet,
          headers,
          sampleIdColumn,
          metadataColumns,
          ignoreEmptyValues,
        }),
        graphqlUrl,
        csrfToken,
        groupId,
        groupPuid,
        projectId,
        projectPuid,
        total: range.e.r,
      });
    } else {
      await importRowChunks({
        rows,
        graphqlUrl,
        csrfToken,
        groupId,
        groupPuid,
        projectId,
        projectPuid,
        total: rows.length,
      });
    }
    self.postMessage({ type: "done" });
  } catch (error) {
    self.postMessage({
      type: "error",
      message: error?.message || "Unexpected error while importing metadata.",
    });
  }
};
