const METADATA_FIELDS_SELECTOR =
  "input[name='data_export[export_parameters][metadata_fields][]']";
const FORMAT_SELECTOR =
  "input[name='data_export[export_parameters][linelist_format]']:checked";
const NAMESPACE_SELECTOR =
  "input[name='data_export[export_parameters][namespace_id]']";
const EXPORT_NAME_SELECTOR = "input[name='data_export[name]']";
const EMAIL_NOTIFICATION_SELECTOR =
  "input[name='data_export[email_notification]']";
const DELIVERY_MODE_SELECTOR =
  "input[name='data_export[delivery_mode]']:checked";

function selectedValue(root, selector, fallback = "") {
  const selected = root.querySelector(selector);
  return selected?.value || fallback;
}

export function readLinelistExportFormState(root) {
  const selectedDeliveryMode = selectedValue(
    root,
    DELIVERY_MODE_SELECTOR,
    "immediate_download",
  );

  return {
    metadataFields: Array.from(
      root.querySelectorAll(METADATA_FIELDS_SELECTOR),
    ).map((input) => input.value),
    format: selectedValue(root, FORMAT_SELECTOR, "csv"),
    namespaceId: selectedValue(root, NAMESPACE_SELECTOR, ""),
    exportName: selectedValue(root, EXPORT_NAME_SELECTOR, "").trim(),
    emailNotification: Boolean(
      root.querySelector(EMAIL_NOTIFICATION_SELECTOR)?.checked,
    ),
    saveToServer: selectedDeliveryMode === "save_to_server",
  };
}

export function selectionStorageKey(locationLike = location) {
  return `${locationLike.protocol}//${locationLike.host}${locationLike.pathname}`;
}

export function selectedSampleIds(storageKey, storage = sessionStorage) {
  const value = storage.getItem(storageKey);
  if (!value) return [];

  try {
    const parsed = JSON.parse(value);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

export function buildExportFilename(format, now = new Date()) {
  const exportFormat = format === "xlsx" ? "xlsx" : "csv";
  return `linelist-${now.toISOString().replace(/[:.]/g, "-")}.${exportFormat}`;
}

export function buildSaveRequest({ sampleIds, formState }) {
  return {
    saveToServer: formState.saveToServer,
    sampleIds,
    metadataFields: formState.metadataFields,
    namespaceId: formState.namespaceId,
    format: formState.format,
    exportName: formState.exportName,
    emailNotification: formState.emailNotification,
  };
}

export function buildWorkerMessage({
  sampleIds,
  formState,
  graphqlUrl,
  csrfToken,
  sampleGraphqlIdPrefix,
  filename,
  totalCount,
}) {
  return {
    sample_ids: sampleIds,
    metadata_fields: formState.metadataFields,
    namespace_id: formState.namespaceId,
    graphql_url: graphqlUrl,
    csrf_token: csrfToken,
    sample_graphql_id_prefix: sampleGraphqlIdPrefix,
    format: formState.format,
    filename,
    total_count: totalCount,
  };
}
