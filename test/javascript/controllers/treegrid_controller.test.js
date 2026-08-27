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
  });

  it("initializes the treegrid controller and correctly sets tabindex for each row", async () => {
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-expanded="false" tabindex="0" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <button class="treegrid-row-toggle" data-action="click->treegrid#toggleRow" aria-label="Expand" data-treegrid-target="rowToggle" tabindex="-1"></button>
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="0">Row 1 Link 1</a>
              <a href="#" tabindex="0">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" tabindex="0" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 2</span>
              <a href="#" tabindex="0">Row 2 Link 1</a>
              <a href="#" tabindex="0">Row 2 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="1" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <button class="treegrid-row-toggle" data-action="click->treegrid#toggleRow" aria-label="Expand" data-treegrid-target="rowToggle" tabindex="-1"></button>
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row hidden" role="row" aria-level="2" aria-posinset="1" aria-setsize="1" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Sub Row 1</span>
              <a href="#" tabindex="-1">Sub Row 1 Link 1</a>
              <a href="#" tabindex="-1">Sub Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="1" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="1" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <button class="treegrid-row-toggle" data-action="click->treegrid#toggleRow" aria-label="Expand" data-treegrid-target="rowToggle" tabindex="-1" data-toggle-url="http://localhost/mocked-url"></button>
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 2</span>
              <a href="#" tabindex="-1">Row 2 Link 1</a>
              <a href="#" tabindex="-1">Row 2 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 2</span>
              <a href="#" tabindex="-1">Row 2 Link 1</a>
              <a href="#" tabindex="-1">Row 2 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 2</span>
              <a href="#" tabindex="-1">Row 2 Link 1</a>
              <a href="#" tabindex="-1">Row 2 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 2</span>
              <a href="#" tabindex="-1">Row 2 Link 1</a>
              <a href="#" tabindex="-1">Row 2 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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

  it("focuses the correct cell in the new row when navigating with Arrow Up and Arrow Down", async () => {
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 2</span>
              <a href="#" tabindex="-1">Row 2 Link 1</a>
              <a href="#" tabindex="-1">Row 2 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

    // Wait for Stimulus mutation observer to process connection
    await new Promise((resolve) => setTimeout(resolve, 0));

    const rows = document.querySelectorAll(".treegrid-row");
    expect(rows.length).toBe(2);

    // Focus the first row and the second link
    const firstRowLinks = rows[0].querySelectorAll("a");
    firstRowLinks[1].focus();
    expect(document.activeElement).toBe(firstRowLinks[1]);

    // Simulate Arrow Down key press
    const arrowDownEvent = new KeyboardEvent("keydown", {
      key: "ArrowDown",
      bubbles: true,
      cancelable: true,
    });
    firstRowLinks[1].dispatchEvent(arrowDownEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The second row should now be focused on the second link
    const secondRowLinks = rows[1].querySelectorAll("a");
    expect(document.activeElement).toBe(secondRowLinks[1]);

    // Simulate Arrow Up key press
    const arrowUpEvent = new KeyboardEvent("keydown", {
      key: "ArrowUp",
      bubbles: true,
      cancelable: true,
    });
    secondRowLinks[1].dispatchEvent(arrowUpEvent);

    // Wait for Stimulus mutation observer to process the keydown action
    await new Promise((resolve) => setTimeout(resolve, 0));

    // The first row should now be focused on the second link
    expect(document.activeElement).toBe(firstRowLinks[1]);
  });

  it("navigates the cells in the row when navigating with Arrow Right", async () => {
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="1" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="1" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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

  it("expands the row on Arrow Right when the row is focused and has a toggle button", async () => {
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="1" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <button class="treegrid-row-toggle" data-action="click->treegrid#toggleRow" aria-label="Expand" data-treegrid-target="rowToggle" tabindex="-1"></button>
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row hidden" role="row" aria-level="2" aria-posinset="1" aria-setsize="1" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Child Row 1</span>
              <a href="#" tabindex="-1">Child Row 1 Link 1</a>
              <a href="#" tabindex="-1">Child Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" aria-expanded="true" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <button class="treegrid-row-toggle" data-action="click->treegrid#toggleRow" aria-label="Collapse" data-treegrid-target="rowToggle" tabindex="-1"></button>
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="2" aria-posinset="1" aria-setsize="1" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Child Row 1</span>
              <a href="#" tabindex="-1">Child Row 1 Link 1</a>
              <a href="#" tabindex="-1">Child Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Child Row 1</span>
              <a href="#" tabindex="-1">Child Row 1 Link 1</a>
              <a href="#" tabindex="-1">Child Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 2</span>
              <a href="#" tabindex="-1">Row 2 Link 1</a>
              <a href="#" tabindex="-1">Row 2 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 2</span>
              <a href="#" tabindex="-1">Row 2 Link 1</a>
              <a href="#" tabindex="-1">Row 2 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 2</span>
              <a href="#" tabindex="-1">Row 2 Link 1</a>
              <a href="#" tabindex="-1">Row 2 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 2</span>
              <a href="#" tabindex="-1">Row 2 Link 1</a>
              <a href="#" tabindex="-1">Row 2 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
    document.body.innerHTML = `
      <div class="treegrid-container" role="treegrid" aria-readonly="true" data-controller="treegrid" data-treegrid-expand-text-value="Expand" data-treegrid-collapse-text-value="Collapse">
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
      </div>
    `;

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
});
