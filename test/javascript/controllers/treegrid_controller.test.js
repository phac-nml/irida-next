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

describe("treegrid controller", () => {
  let application;

  beforeEach(() => {
    globalThis.fetch = vi.fn();
    globalThis.Turbo = {
      renderStreamMessage: vi.fn(),
    };
    application = Application.start();
    application.register("treegrid", TreegridController);
  });

  afterEach(() => {
    application?.stop();
    document.body.innerHTML = "";
    vi.restoreAllMocks();
  });

  it("initializes the treegrid controller and correctly sets tabindex for each row", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2, tabindex: "0" },
      {
        label: "Row 2",
        expanded: true,
        cells: 2,
        tabindex: "0",
        childRows: [{ label: "Sub Row 1", cells: 2, tabindex: "0" }],
      },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const element = document.querySelector("[data-controller='treegrid']");
    expect(element).not.toBeNull();
    expect(element.getAttribute("data-controller-connected")).toBe("true");

    // tabindex is set correctly for each row and its child elements
    Array.from(element.getElementsByClassName("treegrid-row")).forEach(
      (row, index) => {
        expect(row.getAttribute("tabindex")).toBe(index === 0 ? "0" : "-1");
        Array.from(row.querySelectorAll("button, a")).forEach((el) => {
          if (el.classList.contains("treegrid-row-toggle")) {
            expect(el.getAttribute("tabindex")).toBe("-1");
          } else {
            expect(el.getAttribute("tabindex")).toBe(index === 0 ? "0" : "-1");
          }
        });
      },
    );
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
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    const childRow = document.querySelector(".treegrid-row.hidden");
    expect(row).not.toBeNull();
    expect(childRow).not.toBeNull();
    const toggleButton = row.querySelector(".treegrid-row-toggle");

    // Simulate click to expand the row
    toggleButton.click();

    // Wait for Stimulus mutation observer to process the click action
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(row.getAttribute("aria-expanded")).toBe("true");
    expect(toggleButton.getAttribute("aria-label")).toBe("Collapse");
    expect(childRow.classList.contains("hidden")).toBe(false);

    // Simulate click to collapse the row
    toggleButton.click();

    // Wait for Stimulus mutation observer to process the click action
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(row.getAttribute("aria-expanded")).toBe("false");
    expect(toggleButton.getAttribute("aria-label")).toBe("Expand");
    expect(childRow.classList.contains("hidden")).toBe(true);
  });

  it("does not toggle the row expansion state if the row is not expandable", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 2 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();
    const toggleButton = row.querySelector(".treegrid-row-toggle");
    expect(toggleButton).toBeNull();

    // Simulate click on the row (should not toggle since there's no toggle button)
    row.click();

    // Wait for Stimulus mutation observer to process the click action
    await new Promise((resolve) => setTimeout(resolve, 0));

    expect(row.getAttribute("aria-expanded")).toBe(null);
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
    await new Promise((resolve) => setTimeout(resolve, 0));

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
    await new Promise((resolve) => setTimeout(resolve, 0));

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

  it("focuses the next row when Arrow Down is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus the first row
    rows[0].focus();
    expect(document.activeElement).toBe(rows[0]);

    // Simulate Arrow Down key press
    const arrowDownEvent = new KeyboardEvent("keydown", {
      key: "ArrowDown",
      bubbles: true,
      cancelable: true,
    });
    rows[0].dispatchEvent(arrowDownEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The second row should now be focused
    expect(document.activeElement).toBe(rows[1]);
  });

  it("focuses the previous row when Arrow Up is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus the second row
    rows[1].focus();
    expect(document.activeElement).toBe(rows[1]);

    // Simulate Arrow Up key press
    const arrowUpEvent = new KeyboardEvent("keydown", {
      key: "ArrowUp",
      bubbles: true,
      cancelable: true,
    });
    rows[1].dispatchEvent(arrowUpEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The first row should now be focused
    expect(document.activeElement).toBe(rows[0]);
  });

  it("keeps focus on the first row when Arrow Up is pressed on the first row", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus the first row
    rows[0].focus();
    expect(document.activeElement).toBe(rows[0]);

    // Simulate Arrow Up key press
    const arrowUpEvent = new KeyboardEvent("keydown", {
      key: "ArrowUp",
      bubbles: true,
      cancelable: true,
    });
    rows[0].dispatchEvent(arrowUpEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The first row should still be focused
    expect(document.activeElement).toBe(rows[0]);
  });

  it("keeps focus on the last row when Arrow Down is pressed on the last row", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus the last row
    rows[1].focus();
    expect(document.activeElement).toBe(rows[1]);

    // Simulate Arrow Down key press
    const arrowDownEvent = new KeyboardEvent("keydown", {
      key: "ArrowDown",
      bubbles: true,
      cancelable: true,
    });
    rows[1].dispatchEvent(arrowDownEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The last row should still be focused
    expect(document.activeElement).toBe(rows[1]);
  });

  it("handles arrow key down navigation with rows having different cell counts", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 3 },
      { label: "Row 2", cells: 2 },
      { label: "Row 3", cells: 3 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(3);

    // Focus on the 3rd cell (index 2) of the first row
    const row1Links = rows[0].querySelectorAll("a");
    expect(row1Links.length).toBe(3);
    row1Links[2].focus();
    expect(document.activeElement).toBe(row1Links[2]);

    // Simulate Arrow Down key press to navigate to row 2
    const arrowDownEvent1 = new KeyboardEvent("keydown", {
      key: "ArrowDown",
      bubbles: true,
      cancelable: true,
    });
    row1Links[2].dispatchEvent(arrowDownEvent1);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The row 2 should now be focused (row 2 has only 2 cells, so should focus on last available cell or same index if available)
    const row2Links = rows[1].querySelectorAll("a");
    expect(row2Links.length).toBe(2);
    // Focus should be on the cell that matches the column position (capped at available cells)
    expect(document.activeElement).toBe(row2Links[1]);

    // Simulate Arrow Down key press to navigate to row 3
    const arrowDownEvent2 = new KeyboardEvent("keydown", {
      key: "ArrowDown",
      bubbles: true,
      cancelable: true,
    });
    row2Links[1].dispatchEvent(arrowDownEvent2);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The row 3 should now be focused on the same column position (cell at index 1)
    const row3Links = rows[2].querySelectorAll("a");
    expect(row3Links.length).toBe(3);
    expect(document.activeElement).toBe(row3Links[1]);
  });

  it("navigates the cells in the row when navigating with Arrow Right", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 2 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    // Focus the row
    row.focus();
    expect(document.activeElement).toBe(row);

    // Simulate Arrow Right key press
    const arrowRightEvent = new KeyboardEvent("keydown", {
      key: "ArrowRight",
      bubbles: true,
      cancelable: true,
    });
    row.dispatchEvent(arrowRightEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The first link in the row should now be focused
    const firstLink = row.querySelector("a");
    expect(document.activeElement).toBe(firstLink);

    // Simulate Arrow Right key press
    firstLink.dispatchEvent(arrowRightEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The second link in the row should now be focused
    const secondLink = row.querySelectorAll("a")[1];
    expect(document.activeElement).toBe(secondLink);
  });

  it("navigates the cells in the row when navigating with Arrow Left", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 2 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    // Focus the second link in the row
    const secondLink = row.querySelectorAll("a")[1];
    secondLink.focus();
    expect(document.activeElement).toBe(secondLink);

    // Simulate Arrow Left key press
    const arrowLeftEvent = new KeyboardEvent("keydown", {
      key: "ArrowLeft",
      bubbles: true,
      cancelable: true,
    });
    secondLink.dispatchEvent(arrowLeftEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The first link in the row should now be focused
    const firstLink = row.querySelector("a");
    expect(document.activeElement).toBe(firstLink);
  });

  it("focuses the row when pressing Arrow Left on the first cell", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 2 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    const links = row.querySelectorAll("a");
    expect(links.length).toBe(2);

    // Focus on the first cell
    links[0].focus();
    expect(document.activeElement).toBe(links[0]);

    // Simulate Arrow Left key press to navigate back to the row
    const arrowLeftEvent = new KeyboardEvent("keydown", {
      key: "ArrowLeft",
      bubbles: true,
      cancelable: true,
    });
    links[0].dispatchEvent(arrowLeftEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The row should now be focused
    expect(document.activeElement).toBe(row);
  });

  it("expands the row on Arrow Right when the row is focused and has a toggle button", async () => {
    document.body.innerHTML = renderFixtureHtml([
      {
        label: "Row 1",
        cells: 2,
        childRows: [{ label: "Child Row 1", cells: 2, hidden: true }],
      },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();
    const toggleButton = row.querySelector(".treegrid-row-toggle");

    // Focus the row
    row.focus();
    expect(document.activeElement).toBe(row);

    // Simulate Arrow Right key press
    const arrowRightEvent = new KeyboardEvent("keydown", {
      key: "ArrowRight",
      bubbles: true,
      cancelable: true,
    });
    row.dispatchEvent(arrowRightEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The row should now be expanded
    expect(row.getAttribute("aria-expanded")).toBe("true");
    expect(toggleButton.getAttribute("aria-label")).toBe("Collapse");
  });

  it("collapses the row on Arrow Left when the row is focused and has a toggle button", async () => {
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
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();
    const toggleButton = row.querySelector(".treegrid-row-toggle");

    // Focus the row
    row.focus();
    expect(document.activeElement).toBe(row);

    // Simulate Arrow Left key press
    const arrowLeftEvent = new KeyboardEvent("keydown", {
      key: "ArrowLeft",
      bubbles: true,
      cancelable: true,
    });
    row.dispatchEvent(arrowLeftEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The row should now be collapsed
    expect(row.getAttribute("aria-expanded")).toBe("false");
    expect(toggleButton.getAttribute("aria-label")).toBe("Expand");
  });

  it("focuses the first row when home key is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus the second row
    rows[1].focus();
    expect(document.activeElement).toBe(rows[1]);

    // Simulate Home key press
    const homeEvent = new KeyboardEvent("keydown", {
      key: "Home",
      bubbles: true,
      cancelable: true,
    });
    rows[1].dispatchEvent(homeEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The first row should now be focused
    expect(document.activeElement).toBe(rows[0]);
  });

  it("focuses the first cell in the row when home key is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 2 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    // Focus the second link in the row
    const secondLink = row.querySelectorAll("a")[1];
    secondLink.focus();
    expect(document.activeElement).toBe(secondLink);

    // Simulate Home key press
    const homeEvent = new KeyboardEvent("keydown", {
      key: "Home",
      bubbles: true,
      cancelable: true,
    });
    secondLink.dispatchEvent(homeEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The first focusable cell in the row should now be focused (the first link)
    const firstLink = row.querySelector("a");
    expect(document.activeElement).toBe(firstLink);
  });

  it("focuses the last row when end key is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus the first row
    rows[0].focus();
    expect(document.activeElement).toBe(rows[0]);

    // Simulate End key press
    const endEvent = new KeyboardEvent("keydown", {
      key: "End",
      bubbles: true,
      cancelable: true,
    });
    rows[0].dispatchEvent(endEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The last row should now be focused
    expect(document.activeElement).toBe(rows[1]);
  });

  it("focuses the last cell in the row when end key is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 2 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    // Focus the first link in the row
    const firstLink = row.querySelector("a");
    firstLink.focus();
    expect(document.activeElement).toBe(firstLink);

    // Simulate End key press
    const endEvent = new KeyboardEvent("keydown", {
      key: "End",
      bubbles: true,
      cancelable: true,
    });
    firstLink.dispatchEvent(endEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The last focusable cell in the row should now be focused (the second link)
    const secondLink = row.querySelectorAll("a")[1];
    expect(document.activeElement).toBe(secondLink);
  });

  it("focuses the first row when page up key is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus the second row
    rows[1].focus();
    expect(document.activeElement).toBe(rows[1]);

    // Simulate Page Up key press
    const pageUpEvent = new KeyboardEvent("keydown", {
      key: "PageUp",
      bubbles: true,
      cancelable: true,
    });
    rows[1].dispatchEvent(pageUpEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The first row should now be focused
    expect(document.activeElement).toBe(rows[0]);
  });

  it("focuses the last row when page down key is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus the first row
    rows[0].focus();
    expect(document.activeElement).toBe(rows[0]);

    // Simulate Page Down key press
    const pageDownEvent = new KeyboardEvent("keydown", {
      key: "PageDown",
      bubbles: true,
      cancelable: true,
    });
    rows[0].dispatchEvent(pageDownEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The last row should now be focused
    expect(document.activeElement).toBe(rows[1]);
  });

  it("keydown event listener does nothing when unhandled key is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 2 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    // Focus the row
    row.focus();
    expect(document.activeElement).toBe(row);

    // Simulate an unhandled key press (e.g., "A")
    const unhandledKeyEvent = new KeyboardEvent("keydown", {
      key: "A",
      bubbles: true,
      cancelable: true,
    });
    row.dispatchEvent(unhandledKeyEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The row should still be focused
    expect(document.activeElement).toBe(row);
  });

  it("removes event listeners when the controller is disconnected", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 2 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const controller = application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller='treegrid']"),
      "treegrid",
    );
    expect(controller).not.toBeNull();

    // Spy on the event listeners to ensure they are removed
    const keydownSpy = vi.spyOn(controller, "keydown");
    const focusinSpy = vi.spyOn(controller, "focusin");

    const element = document.querySelector("[data-controller='treegrid']");
    expect(element).not.toBeNull();

    // Disconnect the controller
    element.removeAttribute("data-controller");

    // Simulate Arrow Down key press
    const arrowDownEvent = new KeyboardEvent("keydown", {
      key: "ArrowDown",
      bubbles: true,
      cancelable: true,
    });
    element.dispatchEvent(arrowDownEvent);

    expect(keydownSpy).not.toHaveBeenCalled();
    expect(focusinSpy).not.toHaveBeenCalled();

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The first row should still be focused since the controller is disconnected
    const rows = document.querySelectorAll(".treegrid-row");
    expect(document.activeElement).not.toBe(rows[0]);
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
    await new Promise((resolve) => setTimeout(resolve, 0));

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
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The focus should remain on the external button (the handler should return early since getContainingRow returns null)
    expect(document.activeElement).toBe(externalButton);
  });

  it("ignores Arrow Down when ctrlKey is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus on the first row
    rows[0].focus();
    expect(document.activeElement).toBe(rows[0]);

    // Simulate Ctrl+Arrow Down key press
    const ctrlArrowDownEvent = new KeyboardEvent("keydown", {
      key: "ArrowDown",
      ctrlKey: true,
      bubbles: true,
      cancelable: true,
    });

    rows[0].dispatchEvent(ctrlArrowDownEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The focus should remain on the first row
    expect(document.activeElement).toBe(rows[0]);
  });

  it("ignores Arrow Up when shiftKey is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus on the second row
    rows[1].focus();
    expect(document.activeElement).toBe(rows[1]);

    // Simulate Shift+Arrow Up key press
    const shiftArrowUpEvent = new KeyboardEvent("keydown", {
      key: "ArrowUp",
      shiftKey: true,
      bubbles: true,
      cancelable: true,
    });

    rows[1].dispatchEvent(shiftArrowUpEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The focus should remain on the second row
    expect(document.activeElement).toBe(rows[1]);
  });

  it("ignores Arrow Right when ctrlKey is pressed", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 2 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    const links = row.querySelectorAll("a");
    expect(links.length).toBe(2);

    // Focus on the first cell
    links[0].focus();
    expect(document.activeElement).toBe(links[0]);

    // Simulate Ctrl+Arrow Right key press
    const ctrlArrowRightEvent = new KeyboardEvent("keydown", {
      key: "ArrowRight",
      ctrlKey: true,
      bubbles: true,
      cancelable: true,
    });

    links[0].dispatchEvent(ctrlArrowRightEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The focus should move to the next cell (not blocked by ctrl key when on a cell)
    expect(document.activeElement).toBe(links[1]);
  });

  it("navigates cells when Arrow Right is pressed on a cell regardless of row focus", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 3 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    const links = row.querySelectorAll("a");

    // Focus on the middle cell
    links[1].focus();
    expect(document.activeElement).toBe(links[1]);

    // Simulate Arrow Right (no ctrl/shift - cell should move right regardless)
    const arrowRightEvent = new KeyboardEvent("keydown", {
      key: "ArrowRight",
      bubbles: true,
      cancelable: true,
    });

    links[1].dispatchEvent(arrowRightEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should move to the last cell
    expect(document.activeElement).toBe(links[2]);
  });

  it("handles navigation when cellIndex exceeds available cells in row", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 3 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    const row1Links = rows[0].querySelectorAll("a");
    const row2Links = rows[1].querySelectorAll("a");

    // Focus on the last cell (index 1) of row 1
    row1Links[1].focus();
    expect(document.activeElement).toBe(row1Links[1]);

    // Navigate down to row 2 - should maintain cell index if available
    const arrowDownEvent = new KeyboardEvent("keydown", {
      key: "ArrowDown",
      bubbles: true,
      cancelable: true,
    });

    row1Links[1].dispatchEvent(arrowDownEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should be on cell 1 of row 2
    expect(document.activeElement).toBe(row2Links[1]);
  });

  it("collapses multi-level nested rows when parent is collapsed", async () => {
    document.body.innerHTML = renderFixtureHtml([
      {
        label: "Parent",
        cells: 1,
        expanded: true,
        childRows: [
          {
            label: "Child 1",
            cells: 1,
            expanded: true,
            childRows: [{ label: "Grandchild 1", cells: 1 }],
          },
          {
            label: "Child 2",
            cells: 1,
          },
        ],
      },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(4); // Parent, Child1, Grandchild1, Child2

    const parentRow = rows[0];
    const childRow1 = rows[1];
    const grandchildRow1 = rows[2];
    const childRow2 = rows[3];

    // All rows should be visible initially
    expect(parentRow.classList.contains("hidden")).toBe(false);
    expect(childRow1.classList.contains("hidden")).toBe(false);
    expect(grandchildRow1.classList.contains("hidden")).toBe(false);
    expect(childRow2.classList.contains("hidden")).toBe(false);

    // Get the toggle button for the parent row
    const parentToggleButton = parentRow.querySelector(".treegrid-row-toggle");
    expect(parentToggleButton).not.toBeNull();

    // Click to collapse the parent row
    parentToggleButton.click();

    // Wait for Stimulus mutation observer to process
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Parent should still be visible, but all children should be hidden
    expect(parentRow.classList.contains("hidden")).toBe(false);
    expect(childRow1.classList.contains("hidden")).toBe(true);
    expect(grandchildRow1.classList.contains("hidden")).toBe(true);
    expect(childRow2.classList.contains("hidden")).toBe(true);

    // Toggle button should now show "Expand"
    expect(parentToggleButton.getAttribute("aria-label")).toBe("Expand");
  });

  it("expands parent row and shows all descendant rows", async () => {
    document.body.innerHTML = renderFixtureHtml([
      {
        label: "Parent",
        cells: 1,
        expanded: false,
        childRows: [
          {
            label: "Child 1",
            cells: 1,
            expanded: false,
            childRows: [{ label: "Grandchild 1", cells: 1 }],
          },
          {
            label: "Child 2",
            cells: 1,
          },
        ],
      },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    const parentRow = rows[0];
    const childRow1 = rows[1];
    const grandchildRow1 = rows[2];
    const childRow2 = rows[3];

    // Children should be hidden initially
    expect(childRow1.classList.contains("hidden")).toBe(true);
    expect(childRow2.classList.contains("hidden")).toBe(true);

    // Grandchild should be hidden (parent is not expanded)
    expect(grandchildRow1.classList.contains("hidden")).toBe(true);

    // Get the toggle button for the parent row
    const parentToggleButton = parentRow.querySelector(".treegrid-row-toggle");

    // Click to expand the parent row
    parentToggleButton.click();

    // Wait for Stimulus mutation observer to process
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Parent should still be visible
    expect(parentRow.classList.contains("hidden")).toBe(false);

    // Direct children should now be visible
    expect(childRow1.classList.contains("hidden")).toBe(false);
    expect(childRow2.classList.contains("hidden")).toBe(false);

    // Grandchild should still be hidden (child1 is not expanded)
    expect(grandchildRow1.classList.contains("hidden")).toBe(true);

    // Toggle button should now show "Collapse"
    expect(parentToggleButton.getAttribute("aria-label")).toBe("Collapse");
  });

  it("navigates cells when Arrow Right with Shift is pressed on a row", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 3 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    // Focus on the row
    row.focus();
    expect(document.activeElement).toBe(row);

    // Simulate Shift+Arrow Right key press on the row
    // Since shiftKey is true, the condition on line 63 evaluates to false,
    // triggering the else branch which calls navigateRow(+1)
    const shiftArrowRightEvent = new KeyboardEvent("keydown", {
      key: "ArrowRight",
      shiftKey: true,
      bubbles: true,
      cancelable: true,
    });

    row.dispatchEvent(shiftArrowRightEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should move to the first cell (navigateRow was called)
    const links = row.querySelectorAll("a");
    expect(document.activeElement).toBe(links[0]);
  });

  it("does nothing when Arrow Left is pressed on a focused collapsed row", async () => {
    document.body.innerHTML = renderFixtureHtml([
      {
        label: "Row 1",
        cells: 2,
        expanded: false,
        childRows: [{ label: "Child Row 1", cells: 2 }],
      },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    // Verify the row is expandable but not expanded
    expect(row.hasAttribute("aria-expanded")).toBe(true);
    expect(row.getAttribute("aria-expanded")).toBe("false");

    // Focus on the row
    row.focus();
    expect(document.activeElement).toBe(row);

    // Simulate Arrow Left key press on the collapsed row
    // Since the row is not expanded, the inner if condition evaluates to false
    // and nothing should happen
    const arrowLeftEvent = new KeyboardEvent("keydown", {
      key: "ArrowLeft",
      bubbles: true,
      cancelable: true,
    });

    row.dispatchEvent(arrowLeftEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should still be on the row (nothing happened)
    expect(document.activeElement).toBe(row);

    // The row should still be collapsed
    expect(row.getAttribute("aria-expanded")).toBe("false");

    // Child row should still be hidden
    const childRow = document.querySelector(".treegrid-row:nth-of-type(2)");
    expect(childRow.classList.contains("hidden")).toBe(true);
  });

  it("handles focusin event when row is already focused and focus moves within same row", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

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
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Row 1 should still have tabindex 0 (for keyboard navigation)
    expect(row1.tabIndex).toBe(0);

    // Row 2 should have tabindex -1 (not focused)
    expect(row2.tabIndex).toBe(-1);

    // Verify the cell link has tabindex 0
    expect(row1Links[0].tabIndex).toBe(0);

    // The other link in row 1 should have tabindex 0 as well (for this row)
    expect(row1Links[1].tabIndex).toBe(0);
  });

  it("navigates to next cell when within valid bounds (line 127)", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 3 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    const links = row.querySelectorAll("a");
    expect(links.length).toBe(3);

    // Focus on the first cell
    links[0].focus();
    expect(document.activeElement).toBe(links[0]);

    // Navigate right to the second cell
    // This triggers line 127: rowFocusableTargets[newIndex].focus();
    // where newIndex = 0 + 1 = 1, which is within bounds (1 < 3)
    const arrowRightEvent = new KeyboardEvent("keydown", {
      key: "ArrowRight",
      bubbles: true,
      cancelable: true,
    });

    links[0].dispatchEvent(arrowRightEvent);

    // Wait for Stimulus mutation observer to process
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should be on the second cell (line 127 executed)
    expect(document.activeElement).toBe(links[1]);

    // Navigate right again to the third cell
    links[1].dispatchEvent(arrowRightEvent);

    // Wait for Stimulus mutation observer to process
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should be on the third cell (line 127 executed again)
    expect(document.activeElement).toBe(links[2]);
  });

  it("does not navigate right when last cell is focused", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 3 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    const links = row.querySelectorAll("a");
    expect(links.length).toBe(3);

    // Focus on the last cell (index 2)
    links[2].focus();
    expect(document.activeElement).toBe(links[2]);

    // Try to navigate right from the last cell
    // This triggers newIndex = 2 + 1 = 3
    // Condition: 3 < 3 is false (out of bounds)
    // Line 127 does NOT execute, focus remains on current cell
    const arrowRightEvent = new KeyboardEvent("keydown", {
      key: "ArrowRight",
      bubbles: true,
      cancelable: true,
    });

    links[2].dispatchEvent(arrowRightEvent);

    // Wait for Stimulus mutation observer to process
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should still be on the last cell (line 127 NOT executed)
    expect(document.activeElement).toBe(links[2]);
  });

  it("navigates to last cell when End key is pressed and already on last cell", async () => {
    document.body.innerHTML = renderFixtureHtml([{ label: "Row 1", cells: 3 }]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const row = document.querySelector(".treegrid-row");
    expect(row).not.toBeNull();

    const links = row.querySelectorAll("a");
    expect(links.length).toBe(3);

    // Focus on the first cell
    links[0].focus();
    expect(document.activeElement).toBe(links[0]);

    // Press End to navigate to the last cell
    // This should execute: newIndex = 3 - 1 = 2
    // And focus the cell at index 2
    const endEvent = new KeyboardEvent("keydown", {
      key: "End",
      bubbles: true,
      cancelable: true,
    });

    links[0].dispatchEvent(endEvent);

    // Wait for Stimulus mutation observer to process
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should be on the last cell (index 2)
    expect(document.activeElement).toBe(links[2]);

    // Press End again when already on the last cell
    // This should calculate newIndex = 3 - 1 = 2 again
    // But the condition `if (document.activeElement !== newCell)` is false
    // so newCell.focus() is not called (already focused)
    links[2].dispatchEvent(endEvent);

    // Wait for Stimulus mutation observer to process
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should still be on the last cell
    expect(document.activeElement).toBe(links[2]);
  });

  it("navigates to last row when End key is pressed on row and stays there", async () => {
    document.body.innerHTML = renderFixtureHtml([
      { label: "Row 1", cells: 2 },
      { label: "Row 2", cells: 2 },
      { label: "Row 3", cells: 2 },
    ]);

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(3);

    const row1 = rows[0];
    const row3 = rows[2];

    // Focus on the first row
    row1.focus();
    expect(document.activeElement).toBe(row1);

    // Press End while focused on row 1
    // This triggers: this.rowTargets.includes(event.target) = true
    // Calls this.#moveToExtremeRow(+1)
    // newRow = rows[3 - 1] = rows[2] (last row)
    // Since row1 !== row3, it calls this.#focus(row3, cellIndex)
    const endEvent = new KeyboardEvent("keydown", {
      key: "End",
      bubbles: true,
      cancelable: true,
    });

    row1.dispatchEvent(endEvent);

    // Wait for Stimulus mutation observer to process
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should be on the last row or one of its cells
    const row3Links = row3.querySelectorAll("a");
    expect([row3, row3Links[0], row3Links[1]]).toContain(
      document.activeElement,
    );

    // Press End again when already on the last row
    // This triggers: this.rowTargets.includes(event.target) = false (focused on cell)
    // But we'll focus on the row and try again
    row3.focus();

    await new Promise((resolve) => setTimeout(resolve, 0));

    row3.dispatchEvent(endEvent);

    // Wait for Stimulus mutation observer to process
    await new Promise((resolve) => setTimeout(resolve, 0));

    // Focus should still be on row 3
    // The condition `if (currentRow !== newRow)` is false
    // so no additional move happens
    const activeRow = document.activeElement.closest(".treegrid-row");
    expect(activeRow).toBe(row3);
  });
});
