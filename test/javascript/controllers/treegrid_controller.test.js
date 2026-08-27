import { Application } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";

import TreegridController from "../../../app/javascript/controllers/treegrid_controller.js";

async function mock(mockedUri, stub) {
  const { Module } = await import("module");

  Module._load_original = Module._load;
  Module._load = (uri, parent) => {
    if (uri === mockedUri) return stub;
    return Module._load_original(uri, parent);
  };
}

vi.hoisted(async () => {
  const tabbable = await vi.importActual("tabbable");

  return mock("tabbable", {
    ...tabbable,
    tabbable: (node, options) =>
      tabbable.tabbable(node, { ...options, displayCheck: "none" }),
    focusable: (node, options) =>
      tabbable.focusable(node, { ...options, displayCheck: "none" }),
    isFocusable: (node, options) =>
      tabbable.isFocusable(node, { ...options, displayCheck: "none" }),
    isTabbable: (node, options) =>
      tabbable.isTabbable(node, { ...options, displayCheck: "none" }),
  });
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
        <div class="treegrid-row" role="row" aria-level="1" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <button class="treegrid-row-toggle" data-action="click->treegrid#toggleRow" aria-label="Expand" data-treegrid-target="rowToggle" tabindex="-1"></button>
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
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
        <div class="treegrid-row hidden" role="row" aria-level="2" aria-posinset="1" aria-setsize="1" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
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
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="1" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
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

    expect(row.getAttribute("aria-expanded")).toBe("false");
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
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
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
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
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
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
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
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="1" aria-setsize="2" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
          <div role="gridcell" aria-colindex="1" style="display: contents;">
            <div>
              <span>Row 1</span>
              <a href="#" tabindex="-1">Row 1 Link 1</a>
              <a href="#" tabindex="-1">Row 1 Link 2</a>
            </div>
          </div>
        </div>
        <div class="treegrid-row" role="row" aria-level="1" aria-posinset="2" aria-setsize="2" aria-expanded="false" tabindex="-1" data-treegrid-target="row">
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
});
