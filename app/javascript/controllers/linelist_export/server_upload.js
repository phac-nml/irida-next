import { xlsxRowsToBlob } from "controllers/linelist_export/downloader";

export async function uploadLinelistExport({
  uploadUrl,
  csrfToken,
  payload,
  pendingUpload,
}) {
  const formData = await buildUploadFormData(payload, pendingUpload);
  const response = await fetch(uploadUrl, {
    method: "POST",
    credentials: "same-origin",
    headers: {
      Accept: "application/json",
      "X-CSRF-Token": csrfToken,
    },
    body: formData,
  });

  const responseBody = await parseJsonResponse(response);
  if (!response.ok) {
    throw new Error(
      responseBody?.error || `Upload failed (${response.status}).`,
    );
  }

  if (!responseBody?.url) {
    throw new Error("Upload succeeded but no export link was returned.");
  }

  return responseBody;
}

async function buildUploadFormData(payload, pendingUpload = {}) {
  const formData = new FormData();

  if (pendingUpload.name) {
    formData.append("data_export[name]", pendingUpload.name);
  }

  const uploadFile = await fileForUpload(payload);
  formData.append("data_export[file]", uploadFile, payload.filename);
  formData.append(
    "data_export[export_parameters][namespace_id]",
    pendingUpload.namespaceId || "",
  );
  formData.append(
    "data_export[export_parameters][linelist_format]",
    pendingUpload.format || "csv",
  );

  (pendingUpload.sampleIds || []).forEach((sampleId) => {
    formData.append("data_export[export_parameters][ids][]", sampleId);
  });

  (pendingUpload.metadataFields || []).forEach((field) => {
    formData.append("data_export[export_parameters][metadata_fields][]", field);
  });

  return formData;
}

async function fileForUpload(payload) {
  if (payload.content instanceof Blob || payload.content instanceof File) {
    return payload.content;
  }

  if (payload.format === "xlsx") {
    return xlsxRowsToBlob(payload.content);
  }

  return new Blob([payload.content], { type: "text/csv;charset=utf-8;" });
}

async function parseJsonResponse(response) {
  const contentType = response.headers.get("content-type") || "";
  if (!contentType.includes("application/json")) return null;

  try {
    return await response.json();
  } catch {
    return null;
  }
}
