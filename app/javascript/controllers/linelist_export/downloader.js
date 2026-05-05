export class XlsxLibraryLoadError extends Error {
  constructor() {
    super("Failed to load XLSX export library.");
    this.name = "XlsxLibraryLoadError";
  }
}

const XLSX_MIME_TYPE =
  "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";

export async function downloadExport(filename, content, format = "csv") {
  if (format === "xlsx") {
    await downloadXlsx(filename, content);
    return;
  }

  downloadCsv(filename, content);
}

function downloadCsv(filename, csvContent) {
  const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}

async function downloadXlsx(filename, rows) {
  const xlsxLibrary = await loadXlsxLibrary();
  const workbook = workbookFromRows(rows, xlsxLibrary);
  xlsxLibrary.writeFile(workbook, filename);
}

export async function xlsxRowsToBlob(rows) {
  const xlsxLibrary = await loadXlsxLibrary();
  const workbook = workbookFromRows(rows, xlsxLibrary);
  const output = xlsxLibrary.write(workbook, {
    bookType: "xlsx",
    type: "array",
  });

  return new Blob([output], { type: XLSX_MIME_TYPE });
}

function workbookFromRows(rows, xlsxLibrary) {
  if (!Array.isArray(rows)) {
    throw new Error("Invalid spreadsheet data received from export worker.");
  }

  const workbook = xlsxLibrary.utils.book_new();
  const worksheet = xlsxLibrary.utils.aoa_to_sheet(rows);
  xlsxLibrary.utils.book_append_sheet(workbook, worksheet, "linelist");
  return workbook;
}

async function loadXlsxLibrary() {
  try {
    return await import("xlsx");
  } catch {
    throw new XlsxLibraryLoadError();
  }
}
