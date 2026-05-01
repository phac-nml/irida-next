const SAMPLE_CHUNK_SIZE = 100;
const SUPPORTED_FORMATS = new Set(["csv", "xlsx"]);
const CONTENT_TYPES_BY_FORMAT = {
  csv: "text/csv",
  xlsx: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
};

const LINELIST_SAMPLES_QUERY = `
  query LinelistSamplesForExport($namespaceId: ID!, $sampleIds: [ID!]!, $metadataKeys: [String!]) {
    linelistExportRows(
      namespaceId: $namespaceId
      sampleIds: $sampleIds
      metadataKeys: $metadataKeys
    ) {
      id
      __typename
      puid
      name
      metadata
      project {
        puid
      }
    }
  }
`;

const CREATE_DIRECT_UPLOAD_MUTATION = `
  mutation CreateDirectUpload($filename: String!, $contentType: String!, $checksum: String!, $byteSize: BigInt!) {
    createDirectUpload(input: {
      filename: $filename
      contentType: $contentType
      checksum: $checksum
      byteSize: $byteSize
    }) {
      directUpload {
        url
        headers
        signedBlobId
      }
    }
  }
`;

const CREATE_LINELIST_DATA_EXPORT_MUTATION = `
  mutation CreateLinelistDataExport(
    $name: String
    $signedBlobId: ID!
    $namespaceId: ID!
    $linelistFormat: String!
    $sampleIds: [ID!]!
    $metadataFields: [String!]
  ) {
    createLinelistDataExport(input: {
      name: $name
      signedBlobId: $signedBlobId
      namespaceId: $namespaceId
      linelistFormat: $linelistFormat
      sampleIds: $sampleIds
      metadataFields: $metadataFields
    }) {
      id
      url
      errors {
        message
        path
      }
    }
  }
`;

const escapeCsv = (value) => {
  const text = String(value ?? "");

  if (text.includes(",") || text.includes('"') || text.includes("\n")) {
    return '"' + text.replace(/"/g, '""') + '"';
  }

  return text;
};

const toCellValue = (value) => {
  if (value == null) return "";
  return value;
};

const chunk = (items, size) => {
  const chunks = [];

  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }

  return chunks;
};

const toSampleGraphqlId = (sampleId, sampleGraphqlIdPrefix) => {
  const id = String(sampleId ?? "");

  if (id.startsWith("gid://")) return id;
  if (sampleGraphqlIdPrefix) return `${sampleGraphqlIdPrefix}${id}`;

  throw new Error("Unable to build GraphQL sample IDs for export.");
};

const postGraphql = async ({
  graphqlUrl,
  query,
  variables,
  operationName,
  csrfToken,
  errorContext = "GraphQL request",
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
    throw new Error(
      `Network error during ${errorContext}: ${error?.message || "request failed"}`,
      { cause: error },
    );
  }

  if (!response.ok) {
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

const leftRotate = (value, amount) =>
  ((value << amount) | (value >>> (32 - amount))) >>> 0;

const md5Bytes = (input) => {
  const bytes = new Uint8Array(input);
  const originalLength = bytes.length;
  const bitLength = originalLength * 8;
  const paddedLength = (((originalLength + 8) >> 6) + 1) * 64;
  const buffer = new Uint8Array(paddedLength);
  buffer.set(bytes);
  buffer[originalLength] = 0x80;

  const view = new DataView(buffer.buffer);
  view.setUint32(paddedLength - 8, bitLength >>> 0, true);
  view.setUint32(paddedLength - 4, Math.floor(bitLength / 0x100000000), true);

  let a0 = 0x67452301;
  let b0 = 0xefcdab89;
  let c0 = 0x98badcfe;
  let d0 = 0x10325476;

  const shifts = [
    7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 5, 9, 14, 20, 5,
    9, 14, 20, 5, 9, 14, 20, 5, 9, 14, 20, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11,
    16, 23, 4, 11, 16, 23, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10,
    15, 21,
  ];
  const constants = Array.from(
    { length: 64 },
    (_, i) => Math.floor(Math.abs(Math.sin(i + 1)) * 0x100000000) >>> 0,
  );

  for (let offset = 0; offset < paddedLength; offset += 64) {
    let a = a0;
    let b = b0;
    let c = c0;
    let d = d0;
    const words = Array.from({ length: 16 }, (_, i) =>
      view.getUint32(offset + i * 4, true),
    );

    for (let i = 0; i < 64; i += 1) {
      let f;
      let g;

      if (i < 16) {
        f = (b & c) | (~b & d);
        g = i;
      } else if (i < 32) {
        f = (d & b) | (~d & c);
        g = (5 * i + 1) % 16;
      } else if (i < 48) {
        f = b ^ c ^ d;
        g = (3 * i + 5) % 16;
      } else {
        f = c ^ (b | ~d);
        g = (7 * i) % 16;
      }

      const next = d;
      d = c;
      c = b;
      b =
        (b + leftRotate((a + f + constants[i] + words[g]) >>> 0, shifts[i])) >>>
        0;
      a = next;
    }

    a0 = (a0 + a) >>> 0;
    b0 = (b0 + b) >>> 0;
    c0 = (c0 + c) >>> 0;
    d0 = (d0 + d) >>> 0;
  }

  const digest = new Uint8Array(16);
  const digestView = new DataView(digest.buffer);
  [a0, b0, c0, d0].forEach((word, index) => {
    digestView.setUint32(index * 4, word, true);
  });
  return digest;
};

const base64FromBytes = (bytes) => {
  let binary = "";
  bytes.forEach((byte) => {
    binary += String.fromCharCode(byte);
  });
  return btoa(binary);
};

const blobForUpload = (content, format) => {
  if (content instanceof Blob) return content;

  return new Blob([content], {
    type: CONTENT_TYPES_BY_FORMAT[format] || "application/octet-stream",
  });
};

const uploadLinelistExport = async ({
  graphqlUrl,
  csrfToken,
  filename,
  format,
  content,
  uploadMetadata = {},
}) => {
  const blob = blobForUpload(content, format);
  const arrayBuffer = await blob.arrayBuffer();
  const checksum = base64FromBytes(md5Bytes(arrayBuffer));
  const contentType = CONTENT_TYPES_BY_FORMAT[format] || blob.type;

  const directUploadPayload = await postGraphql({
    graphqlUrl,
    query: CREATE_DIRECT_UPLOAD_MUTATION,
    variables: {
      filename,
      contentType,
      checksum,
      byteSize: blob.size,
    },
    operationName: "CreateDirectUpload",
    csrfToken,
    errorContext: "direct upload creation",
  });
  const directUpload =
    directUploadPayload?.data?.createDirectUpload?.directUpload;

  if (!directUpload?.url || !directUpload?.signedBlobId) {
    throw new Error("Direct upload credentials were not returned.");
  }

  let headers = {};
  if (directUpload.headers) {
    try {
      headers = JSON.parse(directUpload.headers);
    } catch {
      throw new Error("Direct upload headers were not valid JSON.");
    }
  }

  const uploadResponse = await fetch(directUpload.url, {
    method: "PUT",
    headers,
    body: blob,
  });

  if (!uploadResponse.ok) {
    throw new Error(`File upload failed (${uploadResponse.status}).`);
  }

  const createPayload = await postGraphql({
    graphqlUrl,
    query: CREATE_LINELIST_DATA_EXPORT_MUTATION,
    variables: {
      name: uploadMetadata.name || null,
      signedBlobId: directUpload.signedBlobId,
      namespaceId: String(uploadMetadata.namespaceId || ""),
      linelistFormat: format,
      sampleIds: (uploadMetadata.sampleIds || []).map((id) => String(id)),
      metadataFields: uploadMetadata.metadataFields || [],
    },
    operationName: "CreateLinelistDataExport",
    csrfToken,
    errorContext: "linelist data export creation",
  });
  const result = createPayload?.data?.createLinelistDataExport;

  if (Array.isArray(result?.errors) && result.errors.length > 0) {
    throw new Error(result.errors[0]?.message || "Unable to save export.");
  }

  if (!result?.url) {
    throw new Error("Saved export link was not returned.");
  }

  return { id: result.id, url: result.url };
};

self.onmessage = async (event) => {
  const {
    action,
    sample_ids: sampleIds,
    metadata_fields: metadataFields,
    graphql_url: graphqlUrl,
    csrf_token: csrfToken,
    sample_graphql_id_prefix: sampleGraphqlIdPrefix,
    namespace_id: namespaceId,
    filename,
    format,
    content: uploadContent,
    save_to_server: saveToServer,
    upload_metadata: uploadMetadata,
  } = event.data || {};

  if (action === "upload_to_server") {
    try {
      const serverResponse = await uploadLinelistExport({
        graphqlUrl,
        csrfToken,
        filename,
        format,
        content: uploadContent,
        uploadMetadata,
      });

      self.postMessage({
        type: "server_saved",
        filename,
        format,
        content: uploadContent,
        serverResponse,
      });
    } catch (error) {
      self.postMessage({
        type: "upload_error",
        filename,
        format,
        content: uploadContent,
        message: error?.message || "Upload failed.",
      });
    }
    return;
  }

  const fields = Array.isArray(metadataFields) ? metadataFields : [];
  const ids = Array.isArray(sampleIds) ? sampleIds : [];
  const rows = ids.length;
  const normalizedFormat = format || "csv";

  if (!rows) {
    self.postMessage({
      type: "error",
      message: "No samples were selected for export.",
    });
    return;
  }

  if (!SUPPORTED_FORMATS.has(normalizedFormat)) {
    self.postMessage({
      type: "error",
      message: "Unsupported linelist format for this flow.",
    });
    return;
  }

  if (!graphqlUrl) {
    self.postMessage({
      type: "error",
      message: "Missing GraphQL endpoint for linelist export.",
    });
    return;
  }

  const namespaceIdStr =
    namespaceId != null && String(namespaceId).trim() !== ""
      ? String(namespaceId).trim()
      : "";

  if (!namespaceIdStr) {
    self.postMessage({
      type: "error",
      message: "Missing namespace for linelist export.",
    });
    return;
  }

  try {
    const sampleGraphqlIds = ids.map((id) =>
      toSampleGraphqlId(id, sampleGraphqlIdPrefix),
    );

    const sampleById = new Map();
    let fetched = 0;
    const idChunks = chunk(ids, SAMPLE_CHUNK_SIZE);

    for (const idChunk of idChunks) {
      const payload = await postGraphql({
        graphqlUrl,
        query: LINELIST_SAMPLES_QUERY,
        variables: {
          namespaceId: namespaceIdStr,
          sampleIds: idChunk.map((id) => String(id)),
          metadataKeys: fields.length ? fields : [],
        },
        operationName: "LinelistSamplesForExport",
        csrfToken,
        errorContext: "sample export row loading",
      });

      const exportRows = payload?.data?.linelistExportRows;

      if (!Array.isArray(exportRows)) {
        throw new Error(
          "GraphQL response did not include linelist export rows.",
        );
      }

      exportRows.forEach((node) => {
        if (node?.__typename === "LinelistSampleExportRow" && node.id) {
          sampleById.set(node.id, node);
        }
      });

      fetched += idChunk.length;
      const current = Math.min(fetched, rows);
      self.postMessage({
        type: "progress",
        current,
        total: rows,
        percentage: (current / rows) * 100,
      });
    }

    const header = [
      "SAMPLE PUID",
      "SAMPLE NAME",
      "PROJECT PUID",
      ...fields.map((field) => String(field).toUpperCase()),
    ];
    const tableRows = [header];

    sampleGraphqlIds.forEach((sampleGraphqlId) => {
      const sample = sampleById.get(sampleGraphqlId);

      if (!sample) {
        throw new Error(
          "One or more selected samples were not returned by GraphQL.",
        );
      }

      const metadata = sample.metadata || {};

      const row = [
        toCellValue(sample.puid),
        toCellValue(sample.name),
        toCellValue(sample.project?.puid),
      ];

      fields.forEach((field) => {
        row.push(toCellValue(metadata[field]));
      });

      tableRows.push(row);
    });

    let content;
    if (normalizedFormat === "xlsx") {
      content = tableRows;
    } else {
      const lines = tableRows.map((row) => row.map(escapeCsv).join(","));
      content = lines.join("\n");
    }

    if (saveToServer && normalizedFormat === "csv") {
      try {
        const serverResponse = await uploadLinelistExport({
          graphqlUrl,
          csrfToken,
          filename,
          format: normalizedFormat,
          content,
          uploadMetadata,
        });

        self.postMessage({
          type: "server_saved",
          filename,
          format: normalizedFormat,
          content,
          serverResponse,
        });
      } catch (error) {
        self.postMessage({
          type: "upload_error",
          filename,
          format: normalizedFormat,
          content,
          message: error?.message || "Upload failed.",
        });
      }
    } else {
      self.postMessage({
        type: "done",
        filename,
        format: normalizedFormat,
        content,
      });
    }
  } catch (error) {
    self.postMessage({
      type: "error",
      message: error?.message || "Unexpected error while generating export.",
    });
  }
};
