const SAMPLE_CHUNK_SIZE = 100;

const LINELIST_SAMPLES_QUERY = `
  query LinelistSamples($ids: [ID!]!, $metadataKeys: [String!]) {
    nodes(ids: $ids) {
      id
      __typename
      ... on Sample {
        puid
        name
        metadata(keys: $metadataKeys)
        project {
          puid
        }
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

const chunk = (items, size) => {
  const chunks = [];

  for (let index = 0; index < items.length; index += size) {
    chunks.push(items.slice(index, index + size));
  }

  return chunks;
};

const toSampleGraphqlId = (sampleId, sampleGraphqlIdPrefix) => {
  const id = String(sampleId || "");

  if (id.startsWith("gid://")) return id;
  if (sampleGraphqlIdPrefix) return `${sampleGraphqlIdPrefix}${id}`;

  throw new Error("Unable to build GraphQL sample IDs for export.");
};

const postGraphql = async ({ graphqlUrl, query, variables, operationName }) => {
  let response;

  try {
    response = await fetch(graphqlUrl, {
      method: "POST",
      credentials: "same-origin",
      headers: {
        "Content-Type": "application/json",
        Accept: "application/graphql-response+json, application/json",
      },
      body: JSON.stringify({ query, variables, operationName }),
    });
  } catch (error) {
    throw new Error(
      `Network error while loading samples: ${error?.message || "request failed"}`,
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

self.onmessage = async (event) => {
  const {
    sample_ids: sampleIds,
    metadata_fields: metadataFields,
    graphql_url: graphqlUrl,
    sample_graphql_id_prefix: sampleGraphqlIdPrefix,
    filename,
    format,
  } = event.data || {};

  const fields = Array.isArray(metadataFields) ? metadataFields : [];
  const ids = Array.isArray(sampleIds) ? sampleIds : [];
  const rows = ids.length;

  if (!rows) {
    self.postMessage({
      type: "error",
      message: "No samples were selected for export.",
    });
    return;
  }

  if (format !== "csv" && format !== undefined && format !== null) {
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

  try {
    const sampleGraphqlIds = ids.map((id) =>
      toSampleGraphqlId(id, sampleGraphqlIdPrefix),
    );

    const sampleById = new Map();
    let fetched = 0;
    const idChunks = chunk(sampleGraphqlIds, SAMPLE_CHUNK_SIZE);

    for (const idChunk of idChunks) {
      const payload = await postGraphql({
        graphqlUrl,
        query: LINELIST_SAMPLES_QUERY,
        variables: { ids: idChunk, metadataKeys: fields },
        operationName: "LinelistSamples",
      });

      const nodes = payload?.data?.nodes;

      if (!Array.isArray(nodes)) {
        throw new Error("GraphQL response did not include sample nodes.");
      }

      nodes.forEach((node) => {
        if (node?.__typename === "Sample" && node.id) {
          sampleById.set(node.id, node);
        }
      });

      fetched += idChunk.length;
      self.postMessage({
        type: "progress",
        current: Math.min(fetched, rows),
        total: rows,
        percentage: (Math.min(fetched, rows) / rows) * 100,
      });
    }

    const header = [
      "SAMPLE PUID",
      "SAMPLE NAME",
      "PROJECT PUID",
      ...fields.map((field) => String(field).toUpperCase()),
    ];
    const lines = [header.join(",")];

    sampleGraphqlIds.forEach((sampleGraphqlId) => {
      const sample = sampleById.get(sampleGraphqlId);

      if (!sample) {
        throw new Error(
          "One or more selected samples were not returned by GraphQL.",
        );
      }

      const metadata = sample.metadata || {};

      const row = [
        escapeCsv(sample.puid),
        escapeCsv(sample.name),
        escapeCsv(sample.project?.puid),
      ];

      fields.forEach((field) => {
        row.push(escapeCsv(metadata[field]));
      });

      lines.push(row.join(","));
    });

    self.postMessage({
      type: "done",
      filename,
      content: lines.join("\n"),
    });
  } catch (error) {
    self.postMessage({
      type: "error",
      message: error?.message || "Unexpected error while generating export.",
    });
  }
};
