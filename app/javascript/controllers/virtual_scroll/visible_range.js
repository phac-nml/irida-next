// Compute the metadata visible window for virtual scroll.
// Separated to keep VirtualScrollController smaller and testable.
export function calculateVisibleRange({
  geometry,
  metadataColumnWidths,
  metadataAreaScrollLeft,
  containerWidth,
  bufferColumns = 3,
  numMetadataColumns,
  activeEditingColumnIndex,
}) {
  if (!geometry || !Array.isArray(metadataColumnWidths)) {
    return { firstVisible: 0, lastVisible: 0 };
  }

  let firstVisible = Math.max(
    0,
    geometry.findColumnAtPosition(metadataAreaScrollLeft) - bufferColumns,
  );

  // Compute how many columns fit in the viewport using measured widths
  let visibleWidth = 0;
  let visibleCount = 0;

  for (let i = firstVisible; i < metadataColumnWidths.length; i += 1) {
    visibleWidth += metadataColumnWidths[i];
    visibleCount += 1;
    if (visibleWidth >= containerWidth) break;
  }

  // Add buffer columns to both sides
  visibleCount += 2 * bufferColumns;

  let lastVisible = Math.min(numMetadataColumns, firstVisible + visibleCount);

  // Ensure the actively edited column stays within the rendered window
  if (Number.isInteger(activeEditingColumnIndex)) {
    if (activeEditingColumnIndex < firstVisible) {
      firstVisible = activeEditingColumnIndex;
    }
    if (activeEditingColumnIndex >= lastVisible) {
      lastVisible = Math.min(numMetadataColumns, activeEditingColumnIndex + 1);
    }
  }

  return { firstVisible, lastVisible };
}
