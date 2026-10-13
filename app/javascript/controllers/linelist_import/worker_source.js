// Resolves the linelist import worker script, preferring (in order) an
// explicit worker-url value, the import map, then a relative fallback.
// Mirrors resolveLinelistExportWorkerSource for consistent worker resolution.
export function resolveLinelistImportWorkerSource(
  { hasWorkerUrlValue, workerUrlValue },
  doc = document,
  loc = location,
) {
  if (hasWorkerUrlValue && workerUrlValue) {
    return workerUrlValue;
  }

  const resolvedFromImportMap = workerSourceFromImportMap(doc);
  if (resolvedFromImportMap) {
    return new URL(resolvedFromImportMap, loc.origin).href;
  }

  return new URL("../../workers/linelist_import_worker.js", import.meta.url)
    .href;
}

function workerSourceFromImportMap(doc) {
  const importMapScript = doc.querySelector("script[type='importmap']");
  if (!importMapScript?.textContent) return null;

  try {
    const importMap = JSON.parse(importMapScript.textContent);
    return importMap?.imports?.["workers/linelist_import_worker"] || null;
  } catch {
    return null;
  }
}
