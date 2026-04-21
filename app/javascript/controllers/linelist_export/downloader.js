export class XlsxLibraryLoadError extends Error {
  constructor() {
    super("Failed to load XLSX export library.");
    this.name = "XlsxLibraryLoadError";
  }
}

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
  if (!Array.isArray(rows)) {
    throw new Error("Invalid spreadsheet data received from export worker.");
  }

  let XLSX;

  try {
    XLSX = await import("xlsx");
  } catch {
    throw new XlsxLibraryLoadError();
  }

  const workbook = XLSX.utils.book_new();
  const worksheet = XLSX.utils.aoa_to_sheet(rows);
  XLSX.utils.book_append_sheet(workbook, worksheet, "linelist");
  XLSX.writeFile(workbook, filename);
}
