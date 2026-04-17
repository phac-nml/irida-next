import * as XLSX from "xlsx";

function xlsxBlobFromRows(rows) {
  const workbook = XLSX.utils.book_new();
  const sheet = XLSX.utils.aoa_to_sheet(Array.isArray(rows) ? rows : []);
  XLSX.utils.book_append_sheet(workbook, sheet, "Linelist");
  const content = XLSX.write(workbook, { bookType: "xlsx", type: "array" });

  return new Blob([content], {
    type: "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
  });
}

export function downloadLinelist(payload) {
  const filename = payload?.filename || "linelist-export.csv";
  const format = payload?.format === "xlsx" ? "xlsx" : "csv";
  const blob =
    format === "xlsx"
      ? xlsxBlobFromRows(payload?.rows)
      : new Blob([payload?.content || ""], {
          type: "text/csv;charset=utf-8;",
        });

  const url = URL.createObjectURL(blob);
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.download = filename;
  document.body.appendChild(anchor);
  anchor.click();
  anchor.remove();
  URL.revokeObjectURL(url);
}
