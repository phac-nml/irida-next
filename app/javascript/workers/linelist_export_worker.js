self.onmessage = async (event) => {
  const {
    sample_ids: sampleIds,
    metadata_fields: metadataFields,
    namespace_id: namespaceId,
    total_count: totalCount,
    filename,
    format,
  } = event.data || {};

  const fields = Array.isArray(metadataFields) ? metadataFields : [];
  const ids = Array.isArray(sampleIds) ? sampleIds : [];
  const rows = Math.max(ids.length, Number(totalCount) || 0);

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

  const header = [
    "SAMPLE PUID",
    "SAMPLE NAME",
    "PROJECT PUID",
    ...fields.map((field) => String(field).toUpperCase()),
  ];
  const lines = [header.join(",")];
  const progressInterval = Math.max(1, Math.floor(rows / 250));
  const progressDelayMs = 25;

  const escape = (value) => {
    const text = String(value ?? "");

    if (text.includes(",") || text.includes('"') || text.includes("\n")) {
      return '"' + text.replace(/"/g, '""') + '"';
    }

    return text;
  };

  for (let i = 0; i < rows; i += 1) {
    const sampleId = String(ids[i]);

    const row = [escape(sampleId), "", escape(namespaceId)];

    fields.forEach((field) => {
      row.push(escape(`value-${field}-${sampleId}`));
    });

    lines.push(row.join(","));

    if ((i + 1) % progressInterval === 0 || i + 1 === rows) {
      const percentage = ((i + 1) / rows) * 100;

      self.postMessage({
        type: "progress",
        current: i + 1,
        total: rows,
        percentage,
      });

      await new Promise((resolve) => setTimeout(resolve, progressDelayMs));
    }
  }

  self.postMessage({
    type: "done",
    filename,
    content: lines.join("\n"),
  });
};
