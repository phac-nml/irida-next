import assert from "node:assert/strict";
import test from "node:test";
import { JSDOM } from "jsdom";

import { VirtualScrollCellRenderer } from "../../app/javascript/utilities/virtual_scroll_cell_renderer.js";

function buildRowDom() {
  const dom = new JSDOM("<!doctype html><html><body></body></html>");
  globalThis.window = dom.window;
  globalThis.document = dom.window.document;
  globalThis.Element = dom.window.Element;
  globalThis.CSS = dom.window.CSS || {
    escape: (value) => String(value).replace(/["\\]/g, "\\$&"),
  };

  const row = document.createElement("tr");
  row.dataset.sampleId = "sample-1";

  const baseA = document.createElement("td");
  baseA.textContent = "BaseA";
  baseA.setAttribute("aria-colindex", "1");
  baseA.setAttribute("role", "gridcell");
  const baseB = document.createElement("td");
  baseB.textContent = "BaseB";
  baseB.setAttribute("aria-colindex", "2");
  baseB.setAttribute("role", "gridcell");
  row.append(baseA, baseB);

  const container = document.createElement("div");
  container.dataset.sampleId = "sample-1";

  const templateA = document.createElement("template");
  templateA.dataset.field = "field_a";
  templateA.innerHTML = '<td data-field-id="field_a">A</td>';
  const templateB = document.createElement("template");
  templateB.dataset.field = "field_b";
  templateB.innerHTML = '<td data-field-id="field_b">B</td>';

  container.append(templateA, templateB);

  return { row, container };
}

test("VirtualScrollCellRenderer renders visible metadata cells", () => {
  const { row, container } = buildRowDom();
  const renderer = new VirtualScrollCellRenderer({
    metadataFields: ["field_a", "field_b", "field_c"],
    numBaseColumns: 2,
    metadataColumnWidths: [100, 110, 120],
    columnWidthFallback: 100,
  });

  renderer.renderRowCells(row, {
    firstVisible: 0,
    lastVisible: 2,
    templateContainer: { querySelector: () => container },
  });

  const cells = Array.from(row.querySelectorAll("td"));
  const gridCells = cells.filter((cell) => cell.hasAttribute("aria-colindex"));

  assert.equal(cells.length, 5);
  assert.equal(gridCells.length, 4);
  assert.equal(gridCells[2].getAttribute("aria-colindex"), "3");
  assert.equal(gridCells[3].getAttribute("aria-colindex"), "4");
});

test("VirtualScrollCellRenderer uses placeholders when template missing", () => {
  const { row, container } = buildRowDom();
  const renderer = new VirtualScrollCellRenderer({
    metadataFields: ["field_a", "field_b", "field_c"],
    numBaseColumns: 2,
    metadataColumnWidths: [100, 110, 120],
    columnWidthFallback: 100,
  });

  renderer.renderRowCells(row, {
    firstVisible: 1,
    lastVisible: 3,
    templateContainer: { querySelector: () => container },
  });

  const placeholder = row.querySelector('[data-placeholder="true"]');
  assert.ok(placeholder);
  assert.equal(placeholder.getAttribute("aria-busy"), "true");
});
