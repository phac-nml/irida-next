import assert from "node:assert/strict";
import test from "node:test";
import { JSDOM } from "jsdom";

import { GridKeyboardNavigator } from "../../app/javascript/utilities/grid_keyboard_navigator.js";

function buildGridDom() {
  const dom = new JSDOM(
    '<!doctype html><html><body><table role="grid"><thead role="rowgroup"><tr aria-rowindex="1"><th role="columnheader" aria-colindex="1">H1</th><th role="columnheader" aria-colindex="2">H2</th></tr></thead><tbody role="rowgroup"><tr aria-rowindex="2"><td role="gridcell" aria-colindex="1">A1</td><td role="gridcell" aria-colindex="2">A2</td></tr><tr aria-rowindex="3"><td role="gridcell" aria-colindex="1">B1</td><td role="gridcell" aria-colindex="2">B2</td></tr></tbody></table></body></html>',
  );

  globalThis.window = dom.window;
  globalThis.document = dom.window.document;
  globalThis.CustomEvent = dom.window.CustomEvent;
  globalThis.Element = dom.window.Element;

  return dom;
}

test("GridKeyboardNavigator applies roving tabindex", () => {
  buildGridDom();
  const table = document.querySelector("table");
  const tbody = document.querySelector("tbody");

  const navigator = new GridKeyboardNavigator({
    gridElement: table,
    bodyElement: tbody,
    numBaseColumns: 0,
    totalColumns: 2,
  });

  navigator.applyRovingTabindex();

  const tabbable = Array.from(
    document.querySelectorAll("[aria-colindex]"),
  ).filter((el) => el.tabIndex === 0);

  assert.equal(tabbable.length, 1);
});

test("GridKeyboardNavigator navigates to a specific cell", async () => {
  buildGridDom();
  const table = document.querySelector("table");
  const tbody = document.querySelector("tbody");

  const navigator = new GridKeyboardNavigator({
    gridElement: table,
    bodyElement: tbody,
    numBaseColumns: 0,
    totalColumns: 2,
  });

  const focused = await navigator.navigateToCell(3, 2);
  const cell = document.querySelector(
    'tr[aria-rowindex="3"] [aria-colindex="2"]',
  );

  assert.equal(focused, true);
  assert.equal(document.activeElement, cell);
  assert.equal(navigator.focusedRowIndex, 3);
  assert.equal(navigator.focusedColIndex, 2);
});
