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
});
