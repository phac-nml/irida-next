import assert from "node:assert/strict";
import test from "node:test";

import { VirtualScrollGeometry } from "../../app/javascript/utilities/virtual_scroll_geometry.js";

test("VirtualScrollGeometry finds columns and ranges", () => {
  const geometry = new VirtualScrollGeometry([100, 150, 200, 50]);

  assert.equal(geometry.findColumnAtPosition(0), 0);
  assert.equal(geometry.findColumnAtPosition(100), 1);
  assert.equal(geometry.findColumnAtPosition(249), 1);
  assert.equal(geometry.findColumnAtPosition(250), 2);

  assert.equal(geometry.cumulativeWidthTo(0), 0);
  assert.equal(geometry.cumulativeWidthTo(1), 100);
  assert.equal(geometry.cumulativeWidthTo(3), 450);

  const range = geometry.calculateVisibleRange(0, 260, 1);
  assert.deepEqual(range, { firstVisible: 0, lastVisible: 4 });
});

test("VirtualScrollGeometry updates column widths", () => {
  const geometry = new VirtualScrollGeometry([100, 100, 100]);
  geometry.updateColumnWidths([200, 50, 75]);

  assert.equal(geometry.findColumnAtPosition(0), 0);
  assert.equal(geometry.findColumnAtPosition(199), 0);
  assert.equal(geometry.findColumnAtPosition(200), 1);
  assert.equal(geometry.getTotalWidth(), 325);
});
