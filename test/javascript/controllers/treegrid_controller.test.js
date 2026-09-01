import { Application } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import TreegridController from "../../../app/javascript/controllers/treegrid_controller.js";

vi.mock("tabbable", async () => {
  const actual = await vi.importActual("tabbable");

  return {
    ...actual,
    tabbable: (node, options) =>
      actual.tabbable(node, { ...options, displayCheck: "none" }),
    focusable: (node, options) =>
      actual.focusable(node, { ...options, displayCheck: "none" }),
    isFocusable: (node, options) =>
      actual.isFocusable(node, { ...options, displayCheck: "none" }),
    isTabbable: (node, options) =>
      actual.isTabbable(node, { ...options, displayCheck: "none" }),
  };
});

/**
 * Generates HTML for treegrid test fixtures
 * @param {Array<Object>} rows - Array of row configurations supporting nested child rows
 * @param {string} rows[].label - Label text for the row (used in span and link text)
 * @param {number} rows[].cells - Number of cells/links to generate for this row
 * @param {boolean} [rows[].expandable=false] - Whether the row has a toggle button
 * @param {boolean} [rows[].expanded=false] - Whether the row is initially expanded (shows child rows without hidden class)
 * @param {boolean} [rows[].hidden=false] - Whether the row should have the 'hidden' class
 * @param {number|string} [rows[].tabindex] - Explicit tabindex for the row (overrides default: first row = "0", others = "-1")
 * @param {string} [rows[].toggleUrl] - URL for the toggle button's data-toggle-url attribute
 * @param {Array<Object>} [rows[].childRows] - Nested array of child row configurations
 * @returns {string} HTML string for the treegrid container with rows
 *
 * Example:
 * renderFixtureHtml([
 *   {
 *     label: "Row 1",
 *     cells: 2,
 *     expandable: true,
 *     childRows: [
 *       { label: "Sub Row 1", cells: 2, hidden: true },
 *       { label: "Sub Row 2", cells: 2, hidden: true }
 *     ]
 *   },
 *   { label: "Row 2", cells: 3, tabindex: "0" }
 * ])
 */
function renderFixtureHtml(rows) {
  // Flatten nested structure into a single array with levels
  const flatRows = [];
  let isFirstOverall = true;

  function flattenRows(rowsArray, level = 1, parentExpanded = false) {
    rowsArray.forEach((row) => {
      // Infer expandable from toggleUrl or childRows presence
      const hasToggleUrl = !!row.toggleUrl;
      const hasChildRows = row.childRows && row.childRows.length > 0;
      const expandable = row.expandable ?? (hasToggleUrl || hasChildRows);
      const expanded = row.expanded ?? false;

      const processedRow = {
        label: row.label,
        cells: row.cells,
        expandable,
        expanded,
        hidden: row.hidden ?? !parentExpanded,
        toggleUrl: row.toggleUrl,
        tabindex: row.tabindex,
        level,
        isFirstOverall,
      };
      isFirstOverall = false;
      flatRows.push(processedRow);

      // Recursively process child rows, passing the expanded state
      if (hasChildRows) {
        flattenRows(row.childRows, level + 1, expanded);
      }
    });
  }

  flattenRows(rows, 1, true);

  // Group rows by level and calculate aria-posinset and aria-setsize
  const levelGroups = new Map();
  flatRows.forEach((row) => {
    if (!levelGroups.has(row.level)) {
      levelGroups.set(row.level, []);
    }
    levelGroups.get(row.level).push(row);
  });

  // Add position info to each row
  flatRows.forEach((row) => {
    const levelRows = levelGroups.get(row.level);
    row.posinset = levelRows.indexOf(row) + 1;
    row.setsize = levelRows.length;
  });

  // Generate HTML for each row
  const rowsHtml = flatRows
    .map((row) => {
      const classes = row.hidden
        ? 'class="treegrid-row hidden"'
        : 'class="treegrid-row"';
      const ariaExpanded = row.expandable
        ? `aria-expanded="${row.expanded ? "true" : "false"}"`
        : "";
      const initialTabindex =
        row.tabindex !== undefined
          ? row.tabindex
          : row.isFirstOverall
            ? "0"
            : "-1";

      const toggleButton = row.expandable
        ? `<button class="treegrid-row-toggle" data-action="click->treegrid#toggleRow" aria-label="${row.expanded ? "Collapse" : "Expand"}" data-treegrid-target="rowToggle" tabindex="-1"${row.toggleUrl ? ` data-toggle-url="${row.toggleUrl}"` : ""}></button>`
        : "";

      const cellTabindex =
        row.tabindex !== undefined
          ? row.tabindex
          : row.isFirstOverall
            ? "0"
            : "-1";
      const links = Array.from({ length: row.cells }, (_, i) => {
        return `<a href="#" tabindex="${cellTabindex}">${row.label} Link ${i + 1}</a>`;
      }).join("\n              ");

      return `
        <div ${classes} role="row" aria-level="${row.level}" aria-posinset="${row.posinset}" aria-setsize="${row.setsize}" ${ariaExpanded} tabindex="${initialTabindex}" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            ${toggleButton}
            <div>
              <span>${row.label}</span>
              ${links}
            </div>
          </div>
        </div>`;
    })
    .join("\n");

  return `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
${rowsHtml}
      </div>
    `;
}

async function flushStimulus() {
  await new Promise((resolve) => setTimeout(resolve, 0));
}

function dispatchKeydownEvent(element, key, options = {}) {
  element.dispatchEvent(
    new KeyboardEvent("keydown", {
      key,
      bubbles: true,
      cancelable: true,
      ...options,
    }),
  );
}

describe("treegrid controller", () => {
  let application;

  beforeEach(() => {
    globalThis.fetch = vi.fn();
    globalThis.Turbo = {
      renderStreamMessage: vi.fn(),
    };
  });

  afterEach(() => {
    application?.stop();
    document.body.innerHTML = "";
    vi.restoreAllMocks();
  });

  describe("controller lifecycle", () => {
    it("registers event listeners on connect and removes them on disconnect", async () => {
      document.body.innerHTML = renderFixtureHtml([
        { label: "Row 1", cells: 2 },
      ]);
      const element = document.querySelector("[data-controller='treegrid']");

      const addSpy = vi.spyOn(element, "addEventListener");
      const removeSpy = vi.spyOn(element, "removeEventListener");

      application = Application.start();
      application.register("treegrid", TreegridController);
      await flushStimulus();

      expect(addSpy).toHaveBeenCalledWith("keydown", expect.any(Function));
      expect(addSpy).toHaveBeenCalledWith("focusin", expect.any(Function));
      expect(addSpy).toHaveBeenCalledTimes(2);

      element.removeAttribute("data-controller");
      await flushStimulus();

      expect(removeSpy).toHaveBeenCalledWith("keydown", expect.any(Function));
      expect(removeSpy).toHaveBeenCalledWith("focusin", expect.any(Function));
      expect(removeSpy).toHaveBeenCalledTimes(2);
    });

    it("sets data-controller-connected attribute to true and sets tabindex for each row and cell on connect", async () => {
      // Use hardcoded HTML with button initially having tabindex 0
      // to test that the controller handles toggle buttons correctly
      document.body.innerHTML = `
        <div data-controller="treegrid"
            data-treegrid-expand-text-value="Expand"
            data-treegrid-collapse-text-value="Collapse">
          <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" aria-expanded="false" tabindex="0" data-treegrid-target="row">
            <div role="gridcell" aria-colindex="1" style="display: contents;">
              <button class="treegrid-row-toggle" data-action="click->treegrid#toggleRow" aria-label="Expand" data-treegrid-target="rowToggle" tabindex="0"></button>
            </div>
            <div role="gridcell" aria-colindex="2" style="display: contents;">
              <a href="#" tabindex="0">Row 1 Link 1</a>
            </div>
          </div>
          <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="0" data-treegrid-target="row">
            <div role="gridcell" aria-colindex="1" style="display: contents;">
              <a href="#" tabindex="0">Row 2 Link 1</a>
            </div>
          </div>
        </div>
      `;

      application = Application.start();
      application.register("treegrid", TreegridController);
      await flushStimulus();

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const element = document.querySelector("[data-controller='treegrid']");
      expect(element).not.toBeNull();
      expect(element.getAttribute("data-controller-connected")).toBe("true");

      const firstRow = document.querySelector(".treegrid-row");
      const toggleButton = firstRow.querySelector(".treegrid-row-toggle");
      const firstRowLink = firstRow.querySelector("a");

      // First Row should have tabindex 0 (first row in connect())
      expect(firstRow.tabIndex).toBe(0);

      // First Row Links should have tabindex 0 (managed by controller in setTabIndexForElementsInRow)
      expect(firstRowLink.tabIndex).toBe(0);

      // Toggle button should have tabindex -1 (managed by controller in setTabIndexForElementsInRow)
      expect(toggleButton.tabIndex).toBe(-1);

      const secondRow = document.querySelectorAll(".treegrid-row")[1];
      const secondRowLink = secondRow.querySelector("a");

      // Second Row should have tabindex -1 (not the first row)
      expect(secondRow.tabIndex).toBe(-1);
      // Second Row Links should have tabindex -1 (managed by controller in setTabIndexForElementsInRow)
      expect(secondRowLink.tabIndex).toBe(-1);
    });
  });

  describe("Toggle row button behaviour", () => {
    beforeEach(() => {
      application = Application.start();
      application.register("treegrid", TreegridController);
    });

    it("toggles the row expansion state and updates aria attributes and button text", async () => {
      document.body.innerHTML = renderFixtureHtml([
        {
          label: "Row 1",
          cells: 2,
          childRows: [{ label: "Sub Row 1", cells: 2, hidden: true }],
        },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      const childRow = document.querySelector(".treegrid-row.hidden");
      expect(row).not.toBeNull();
      expect(childRow).not.toBeNull();
      const toggleButton = row.querySelector(".treegrid-row-toggle");

      // Simulate click to expand the row
      toggleButton.click();

      // Wait for Stimulus mutation observer to process the click action
      await flushStimulus();

      expect(row.getAttribute("aria-expanded")).toBe("true");
      expect(toggleButton.getAttribute("aria-label")).toBe("Collapse");
      expect(childRow.classList.contains("hidden")).toBe(false);

      // Simulate click to collapse the row
      toggleButton.click();

      // Wait for Stimulus mutation observer to process the click action
      await flushStimulus();

      expect(row.getAttribute("aria-expanded")).toBe("false");
      expect(toggleButton.getAttribute("aria-label")).toBe("Expand");
      expect(childRow.classList.contains("hidden")).toBe(true);
    });

    it("fetches data from the server when toggling a row with a data-toggle-url attribute", async () => {
      document.body.innerHTML = renderFixtureHtml([
        {
          label: "Row 1",
          cells: 2,
          toggleUrl: "http://localhost/mocked-url",
        },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      const toggleButton = row.querySelector(".treegrid-row-toggle");

      // Mock fetch response
      fetch.mockResolvedValueOnce({
        ok: true,
        text: async () => "<div>Mocked response</div>",
      });

      // Simulate click to expand the row
      toggleButton.click();

      // Wait for Stimulus mutation observer to process the click action
      await flushStimulus();

      expect(fetch).toHaveBeenCalledWith(
        "http://localhost/mocked-url?tabindex=0",
        {
          credentials: "same-origin",
          headers: { Accept: "text/vnd.turbo-stream.html" },
        },
      );

      expect(globalThis.Turbo.renderStreamMessage).toHaveBeenCalledWith(
        "<div>Mocked response</div>",
      );
    });
  });

  describe("keyboard navigation", () => {
    beforeEach(() => {
      application = Application.start();
      application.register("treegrid", TreegridController);
    });

    const rowMoveCases = [
      ["ArrowDown", 0, 1],
      ["ArrowUp", 1, 0],
      ["PageUp", 3, 0],
      ["PageDown", 0, 3],
      ["Home", 3, 0],
      ["End", 0, 3],
    ];

    it.each(rowMoveCases)(
      "moves focus with %s from row %i to row %i",
      async (key, startRowIndex, expectedRowIndex) => {
        document.body.innerHTML = renderFixtureHtml([
          { label: "Row 1", cells: 2 },
          { label: "Row 2", cells: 2 },
          { label: "Row 3", cells: 2 },
          { label: "Row 4", cells: 2 },
        ]);

        await flushStimulus();

        const rows = document.querySelectorAll(".treegrid-row");
        rows[startRowIndex].focus();

        dispatchKeydownEvent(rows[startRowIndex], key);

        await flushStimulus();
        expect(document.activeElement).toBe(rows[expectedRowIndex]);
      },
    );

    const rowDoesNotMoveCases = [
      ["ArrowUp", 0],
      ["ArrowDown", 3],
      ["PageUp", 0],
      ["PageDown", 3],
      ["Home", 0],
      ["End", 3],
    ];

    it.each(rowDoesNotMoveCases)(
      "does not move focus with %s from row %i",
      async (key, startRowIndex) => {
        document.body.innerHTML = renderFixtureHtml([
          { label: "Row 1", cells: 2 },
          { label: "Row 2", cells: 2 },
          { label: "Row 3", cells: 2 },
          { label: "Row 4", cells: 2 },
        ]);

        await flushStimulus();

        const rows = document.querySelectorAll(".treegrid-row");
        rows[startRowIndex].focus();

        dispatchKeydownEvent(rows[startRowIndex], key);

        await flushStimulus();
        expect(document.activeElement).toBe(rows[startRowIndex]);
      },
    );

    const cellMoveCases = [
      ["ArrowRight", 0, 1],
      ["ArrowLeft", 1, 0],
      ["Home", 1, 0],
      ["End", 0, 1],
    ];

    it.each(cellMoveCases)(
      "moves focus with %s from cell %i to cell %i",
      async (key, startCellIndex, expectedCellIndex) => {
        document.body.innerHTML = renderFixtureHtml([
          { label: "Row 1", cells: 2 },
        ]);

        await flushStimulus();

        const row = document.querySelector(".treegrid-row");
        const cells = row.querySelectorAll("a");
        cells[startCellIndex].focus();

        dispatchKeydownEvent(cells[startCellIndex], key);

        await flushStimulus();
        expect(document.activeElement).toBe(cells[expectedCellIndex]);
      },
    );

    const cellDoesNotMoveCases = [
      ["ArrowRight", 1],
      ["End", 1],
    ];

    it.each(cellDoesNotMoveCases)(
      "does not move focus with %s from cell %i",
      async (key, startCellIndex) => {
        document.body.innerHTML = renderFixtureHtml([
          { label: "Row 1", cells: 2 },
        ]);

        await flushStimulus();

        const row = document.querySelector(".treegrid-row");
        const cells = row.querySelectorAll("a");
        cells[startCellIndex].focus();

        dispatchKeydownEvent(cells[startCellIndex], key);

        await flushStimulus();
        expect(document.activeElement).toBe(cells[startCellIndex]);
      },
    );

    const rowCellMoveCases = [
      ["ArrowDown", 0, 0, 1, 0],
      ["ArrowDown", 0, 1, 1, 1],
      ["ArrowDown", 0, 2, 1, 1], // Row 2 has only 2 cells, so should focus on last available cell
      ["ArrowUp", 1, 0, 0, 0],
      ["ArrowUp", 1, 1, 0, 1],
      ["ArrowUp", 1, 1, 0, 1],
    ];

    it.each(rowCellMoveCases)(
      "moves focus with %s from row cell (%i, %i) to cell (%i, %i)",
      async (
        key,
        startRowIndex,
        startCellIndex,
        expectedRowIndex,
        expectedCellIndex,
      ) => {
        document.body.innerHTML = renderFixtureHtml([
          { label: "Row 1", cells: 3 },
          { label: "Row 2", cells: 2 },
          { label: "Row 3", cells: 3 },
        ]);

        await flushStimulus();

        const rows = document.querySelectorAll(".treegrid-row");
        const startRow = rows[startRowIndex];
        const startRowCells = startRow.querySelectorAll("a");
        startRowCells[startCellIndex].focus();

        dispatchKeydownEvent(startRowCells[startCellIndex], key);

        await flushStimulus();
        const expectedRow = rows[expectedRowIndex];
        const expectedRowCells = expectedRow.querySelectorAll("a");
        expect(document.activeElement).toBe(
          expectedRowCells[expectedCellIndex],
        );
      },
    );

    it("expands the row on Arrow Right when the row is focused and expandable", async () => {
      document.body.innerHTML = renderFixtureHtml([
        {
          label: "Row 1",
          cells: 2,
          childRows: [{ label: "Child Row 1", cells: 2, hidden: true }],
        },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      expect(row).not.toBeNull();
      const toggleButton = row.querySelector(".treegrid-row-toggle");

      // Focus the row
      row.focus();
      expect(document.activeElement).toBe(row);

      // Simulate Arrow Right key press
      dispatchKeydownEvent(row, "ArrowRight");

      // Wait for Stimulus mutation observer to process the keydown action
      await flushStimulus();

      // The row should now be expanded
      expect(row.getAttribute("aria-expanded")).toBe("true");
      expect(toggleButton.getAttribute("aria-label")).toBe("Collapse");
    });

    it("moves focus with Arrow Right from row to the first cell when row is not expandable", async () => {
      document.body.innerHTML = renderFixtureHtml([
        { label: "Row 1", cells: 2 },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      expect(row).not.toBeNull();

      // Focus the row
      row.focus();
      expect(document.activeElement).toBe(row);

      // Simulate Arrow Right key press
      dispatchKeydownEvent(row, "ArrowRight");

      // Wait for Stimulus mutation observer to process the keydown action
      await flushStimulus();

      // The first link in the row should now be focused
      const firstLink = row.querySelector("a");
      expect(document.activeElement).toBe(firstLink);
    });

    it("moves focus with Arrow Left from first cell to the row", async () => {
      document.body.innerHTML = renderFixtureHtml([
        { label: "Row 1", cells: 2 },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      expect(row).not.toBeNull();

      const links = row.querySelectorAll("a");
      expect(links.length).toBe(2);

      // Focus on the first cell
      links[0].focus();
      expect(document.activeElement).toBe(links[0]);

      // Simulate Arrow Left key press to navigate back to the row
      dispatchKeydownEvent(links[0], "ArrowLeft");

      // Wait for Stimulus mutation observer to process the keydown action
      await flushStimulus();

      // The row should now be focused
      expect(document.activeElement).toBe(row);
    });

    it("collapses the row on Arrow Left when the row is focused and expanded", async () => {
      document.body.innerHTML = renderFixtureHtml([
        {
          label: "Row 1",
          expanded: true,
          cells: 2,
          childRows: [
            { label: "Child Row 1", cells: 2 },
            { label: "Child Row 2", cells: 2 },
          ],
        },
        { label: "Row 2", cells: 2 },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      expect(row).not.toBeNull();
      const toggleButton = row.querySelector(".treegrid-row-toggle");

      // Focus the row
      row.focus();
      expect(document.activeElement).toBe(row);

      // Simulate Arrow Left key press
      dispatchKeydownEvent(row, "ArrowLeft");

      // Wait for Stimulus mutation observer to process the keydown action
      await flushStimulus();

      // The row should now be collapsed
      expect(row.getAttribute("aria-expanded")).toBe("false");
      expect(toggleButton.getAttribute("aria-label")).toBe("Expand");
    });

    it("does nothing on Arrow Left when the row is focused and expanded", async () => {
      document.body.innerHTML = renderFixtureHtml([
        {
          label: "Row 1",
          cells: 2,
          expanded: false,
          childRows: [{ label: "Child Row 1", cells: 2 }],
        },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      expect(row).not.toBeNull();

      // Verify the row is expandable but not expanded
      expect(row.hasAttribute("aria-expanded")).toBe(true);
      expect(row.getAttribute("aria-expanded")).toBe("false");

      // Focus on the row
      row.focus();
      expect(document.activeElement).toBe(row);

      // Simulate Arrow Left key press on the collapsed row
      dispatchKeydownEvent(row, "ArrowLeft");

      // Wait for Stimulus mutation observer to process the keydown action
      await flushStimulus();

      // Focus should still be on the row (nothing happened)
      expect(document.activeElement).toBe(row);

      // The row should still be collapsed
      expect(row.getAttribute("aria-expanded")).toBe("false");

      // Child row should still be hidden
      const childRow = document.querySelector(".treegrid-row:nth-of-type(2)");
      expect(childRow.classList.contains("hidden")).toBe(true);
    });

    it("keydown event listener does nothing when unhandled key is pressed", async () => {
      document.body.innerHTML = renderFixtureHtml([
        { label: "Row 1", cells: 2 },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      expect(row).not.toBeNull();

      // Focus the row
      row.focus();
      expect(document.activeElement).toBe(row);

      // Simulate an unhandled key press (e.g., "A")
      dispatchKeydownEvent(row, "A");

      // Wait for Stimulus mutation observer to process the keydown action
      await flushStimulus();

      // The row should still be focused
      expect(document.activeElement).toBe(row);
    });

    it("ignores focusin event when focus moves to non-row element", async () => {
      document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="1" tabindex="0" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#">Row 1 Link 1</a>
            </div>
          </div>
        </div>
        <button id="external-button" tabindex="0">External Button</button>
      </div>
    `;

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      expect(row).not.toBeNull();

      const externalButton = document.getElementById("external-button");
      expect(externalButton).not.toBeNull();

      // Focus on the row first
      row.focus();
      expect(document.activeElement).toBe(row);

      // Focus on the external button that is not a row and not inside a row
      externalButton.focus();
      expect(document.activeElement).toBe(externalButton);

      // Wait for Stimulus mutation observer to process the focusin event
      await flushStimulus();

      // The focus should remain on the external button (the handler should return early since getContainingRow returns null)
      expect(document.activeElement).toBe(externalButton);
    });

    it("ignores Arrow Down when ctrlKey is pressed", async () => {
      document.body.innerHTML = renderFixtureHtml([
        { label: "Row 1", cells: 2 },
        { label: "Row 2", cells: 2 },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const rows = document.querySelectorAll(".treegrid-row");
      expect(rows.length).toBe(2);

      // Focus on the first row
      rows[0].focus();
      expect(document.activeElement).toBe(rows[0]);

      // Simulate Ctrl+Arrow Down key press
      dispatchKeydownEvent(rows[0], "ArrowDown", { ctrlKey: true });

      // Wait for Stimulus mutation observer to process the keydown action
      await flushStimulus();

      // The focus should remain on the first row
      expect(document.activeElement).toBe(rows[0]);
    });

    it("ignores Arrow Up when shiftKey is pressed", async () => {
      document.body.innerHTML = renderFixtureHtml([
        { label: "Row 1", cells: 2 },
        { label: "Row 2", cells: 2 },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const rows = document.querySelectorAll(".treegrid-row");
      expect(rows.length).toBe(2);

      // Focus on the second row
      rows[1].focus();
      expect(document.activeElement).toBe(rows[1]);

      // Simulate Shift+Arrow Up key press
      dispatchKeydownEvent(rows[1], "ArrowUp", { shiftKey: true });

      // Wait for Stimulus mutation observer to process the keydown action
      await flushStimulus();

      // The focus should remain on the second row
      expect(document.activeElement).toBe(rows[1]);
    });

    it("ignores Arrow Right when ctrlKey is pressed", async () => {
      document.body.innerHTML = renderFixtureHtml([
        { label: "Row 1", cells: 2 },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      expect(row).not.toBeNull();

      const links = row.querySelectorAll("a");
      expect(links.length).toBe(2);

      // Focus on the first cell
      links[0].focus();
      expect(document.activeElement).toBe(links[0]);

      // Simulate Ctrl+Arrow Right key press
      dispatchKeydownEvent(links[0], "ArrowRight", { ctrlKey: true });

      // Wait for Stimulus mutation observer to process the keydown action
      await flushStimulus();

      // The focus should move to the next cell (not blocked by ctrl key when on a cell)
      expect(document.activeElement).toBe(links[1]);
    });

    it("navigates cells when Arrow Right with Shift is pressed on a row", async () => {
      document.body.innerHTML = renderFixtureHtml([
        { label: "Row 1", cells: 3 },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const row = document.querySelector(".treegrid-row");
      expect(row).not.toBeNull();

      // Focus on the row
      row.focus();
      expect(document.activeElement).toBe(row);

      // Simulate Shift+Arrow Right key press on the row
      dispatchKeydownEvent(row, "ArrowRight", { shiftKey: true });

      // Wait for Stimulus mutation observer to process the keydown action
      await flushStimulus();

      // Focus should move to the first cell (navigateRow was called)
      const links = row.querySelectorAll("a");
      expect(document.activeElement).toBe(links[0]);
    });

    it("handles focusin event when row is already focused and focus moves within same row", async () => {
      document.body.innerHTML = renderFixtureHtml([
        { label: "Row 1", cells: 2 },
        { label: "Row 2", cells: 2 },
      ]);

      // Wait for Stimulus mutation observer to process connection
      await flushStimulus();

      const rows = document.querySelectorAll(".treegrid-row");
      expect(rows.length).toBe(2);

      const row1 = rows[0];
      const row1Links = row1.querySelectorAll("a");
      const row2 = rows[1];

      // Focus on the first row
      row1.focus();
      expect(document.activeElement).toBe(row1);
      expect(row1.tabIndex).toBe(0);

      // Now focus on a link within the same row
      // This triggers a focusin event with the link as target
      // The focusin handler should recognize it's in row1 and update tabindex accordingly
      row1Links[0].focus();
      expect(document.activeElement).toBe(row1Links[0]);

      // Wait for Stimulus focusin event to be processed
      await flushStimulus();

      // Row 1 should still have tabindex 0 (for keyboard navigation)
      expect(row1.tabIndex).toBe(0);

      // Row 2 should have tabindex -1 (not focused)
      expect(row2.tabIndex).toBe(-1);

      // Verify the cell link has tabindex 0
      expect(row1Links[0].tabIndex).toBe(0);

      // The other link in row 1 should have tabindex 0 as well (for this row)
      expect(row1Links[1].tabIndex).toBe(0);
    });
  });
});
