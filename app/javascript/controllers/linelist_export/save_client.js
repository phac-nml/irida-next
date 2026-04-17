function buildSaveBody(request) {
  return {
    data_export: {
      ...(request.exportName ? { name: request.exportName } : {}),
      email_notification: request.emailNotification,
      export_type: "linelist",
      export_parameters: {
        ids: request.sampleIds,
        namespace_id: request.namespaceId,
        linelist_format: request.format,
        metadata_fields: request.metadataFields,
      },
    },
  };
}

async function parseResponsePayload(response) {
  try {
    return await response.json();
  } catch {
    return {};
  }
}

export async function queueLinelistSave({ saveUrl, csrfToken, request }) {
  if (!saveUrl) return null;

  const response = await fetch(saveUrl, {
    method: "POST",
    credentials: "same-origin",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
      "X-CSRF-Token": csrfToken,
    },
    body: JSON.stringify(buildSaveBody(request)),
  });

  const payload = await parseResponsePayload(response);

  if (!response.ok) {
    const detail = Array.isArray(payload?.errors)
      ? payload.errors.join(", ")
      : `Request failed (${response.status})`;
    throw new Error(detail);
  }

  return payload;
}

export function buildDataExportShowUrl(saveUrl, exportId) {
  if (!saveUrl || !exportId) return "";

  return `${saveUrl.replace(/\/$/, "")}/${encodeURIComponent(exportId)}`;
}
