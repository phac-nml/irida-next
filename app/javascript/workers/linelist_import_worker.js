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
    throw new Error(
      `Network error while updating sample metadata: ${error?.message || "request failed"}`,
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

self.onmessage = async (event) => {
  const {
    graphql_url: graphqlUrl,
    csrf_token: csrfToken,
    metadata,
    group_id: groupId,
    group_puid: groupPuid,
    project_id: projectId,
    project_puid: projectPuid,
  } = event.data || {};

  try {
    const result = await bulkUpdateSampleMetadata({
      graphqlUrl,
      csrfToken,
      metadata,
      groupId,
      groupPuid,
      projectId,
      projectPuid,
    });

    self.postMessage({ type: "done", result });
  } catch (error) {
    self.postMessage({
      type: "error",
      message: error?.message || "Unexpected error while importing metadata.",
    });
  } finally {
    self.close();
  }
};
