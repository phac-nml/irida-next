export function selectedMetadataFields(rootElement) {
  return Array.from(
    rootElement.querySelectorAll("#selected-list li"),
    (item) => item.lastElementChild?.textContent?.trim() || "",
  ).filter((value) => value.length > 0);
}

export function selectedFormat(rootElement) {
  const selected = rootElement.querySelector(
    "input[name='data_export[export_parameters][linelist_format]']:checked",
  );

  return selected?.value || "csv";
}

export function selectedNamespaceId(rootElement) {
  const namespaceInput = rootElement.querySelector(
    "input[name='data_export[export_parameters][namespace_id]']",
  );

  return namespaceInput?.value || "";
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

export function selectionStorageKey(loc = location) {
  return `${loc.protocol}//${loc.host}${loc.pathname}`;
}

export function csrfToken(doc = document) {
  const meta = doc.querySelector('meta[name="csrf-token"]');
  return meta?.getAttribute("content") || "";
}
