self.onmessage = async (event) => {
  const {
    sample_ids: sampleIds,
    metadata_fields: metadataFields,
    total_count: totalCount,
    filename,
  } = event.data || {};

  const fields = Array.isArray(metadataFields) ? metadataFields : [];
  const ids = Array.isArray(sampleIds) ? sampleIds : [];
  const rows = Math.max(ids.length, Number(totalCount) || 1);
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
    const sampleId = ids[i] ? String(ids[i]) : `sample-${i + 1}`;

    const row = [
      escape(`sample-${sampleId}`),
      escape(`Sample ${sampleId}`),
      escape(`project-${i + 1}`),
    ];

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
