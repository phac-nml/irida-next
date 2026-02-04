import assert from "node:assert/strict";
import test from "node:test";

import { calculateVisibleRange } from "../../app/javascript/controllers/virtual_scroll/visible_range.js";
import { VirtualScrollGeometry } from "../../app/javascript/utilities/virtual_scroll_geometry.js";

test("calculateVisibleRange keeps editing column visible", () => {
  const widths = [100, 100, 100, 100];
  const geometry = new VirtualScrollGeometry(widths);

  const range = calculateVisibleRange({
    geometry,
    metadataColumnWidths: widths,
    metadataAreaScrollLeft: 0,
    containerWidth: 150,
    bufferColumns: 1,
    numMetadataColumns: widths.length,
    activeEditingColumnIndex: 3,
    pendingFocusColumnIndex: null,
  });

  assert.ok(range.firstVisible <= 3);
  assert.ok(range.lastVisible > 3);
});

test("calculateVisibleRange keeps pending focus column visible", () => {
  const widths = [120, 120, 120, 120];
  const geometry = new VirtualScrollGeometry(widths);

  const range = calculateVisibleRange({
    geometry,
    metadataColumnWidths: widths,
    metadataAreaScrollLeft: 240,
    containerWidth: 200,
    bufferColumns: 1,
    numMetadataColumns: widths.length,
    activeEditingColumnIndex: null,
    pendingFocusColumnIndex: 0,
  });

  assert.equal(range.firstVisible, 0);
});
