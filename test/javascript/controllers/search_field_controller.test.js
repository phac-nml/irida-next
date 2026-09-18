import { Application, Controller } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import SearchFieldController from "../../../app/javascript/controllers/search_field_controller.js";

function renderFixture() {
  document.body.innerHTML = `
    <form>
      <div data-controller="search-field">
        <input data-search-field-target="input" value="" type="search" />
        <button data-search-field-target="clearButton" class="hidden" type="button">Clear</button>
        <button data-search-field-target="submitButton" type="submit">Search</button>
      </div>
    </form>
  `;
}

async function startController() {
  const application = Application.start();
  application.register("search-field", SearchFieldController);
  await Promise.resolve();
  return application;
}

function controllerFor(application) {
  return application.getControllerForElementAndIdentifier(
    document.querySelector("[data-controller~='search-field']"),
    "search-field",
  );
}

describe("search-field", () => {
  let application;

  beforeEach(() => {
    renderFixture();
  });

  afterEach(() => {
    application?.stop();
    document.body.innerHTML = "";
  });

  it("shows the clear button only when the user has typed content", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller='search-field']"),
      "search-field",
    );
    const input = document.querySelector("[data-search-field-target='input']");
    const clearButton = document.querySelector(
      "[data-search-field-target='clearButton']",
    );
    const submitButton = document.querySelector(
      "[data-search-field-target='submitButton']",
    );

    input.value = "abc";
    controller.handleInput();

    expect(clearButton.classList.contains("hidden")).toBe(false);
    expect(submitButton.classList.contains("hidden")).toBe(true);
  });

  it("clears the field and submits the parent form", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      document.querySelector("[data-controller='search-field']"),
      "search-field",
    );
    const form = document.querySelector("form");
    const input = document.querySelector("[data-search-field-target='input']");
    const clearButton = document.querySelector(
      "[data-search-field-target='clearButton']",
    );
    const submitButton = document.querySelector(
      "[data-search-field-target='submitButton']",
    );

    form.requestSubmit = vi.fn();
    input.value = "abc";
    clearButton.classList.remove("hidden");
    submitButton.classList.add("hidden");

    controller.clear();

    expect(input.value).toBe("");
    expect(clearButton.classList.contains("hidden")).toBe(true);
    expect(submitButton.classList.contains("hidden")).toBe(false);
    expect(form.requestSubmit).toHaveBeenCalledTimes(1);
  });

  it("clear() does nothing when there is no input target", async () => {
    document.body.innerHTML = `
      <form>
        <div data-controller="search-field"></div>
      </form>
    `;
    application = await startController();
    const controller = controllerFor(application);
    const form = document.querySelector("form");
    form.requestSubmit = vi.fn();

    controller.clear();

    expect(form.requestSubmit).not.toHaveBeenCalled();
  });

  it("clear() empties the input without submitting when there is no form", async () => {
    document.body.innerHTML = `
      <div data-controller="search-field">
        <input data-search-field-target="input" value="abc" type="search" />
        <button data-search-field-target="clearButton" type="button">Clear</button>
        <button data-search-field-target="submitButton" type="submit">Search</button>
      </div>
    `;
    application = await startController();
    const controller = controllerFor(application);

    expect(() => controller.clear()).not.toThrow();
    expect(
      document.querySelector("[data-search-field-target='input']").value,
    ).toBe("");
  });

  it("updateButtons() does nothing when button targets are missing", async () => {
    document.body.innerHTML = `
      <form>
        <div data-controller="search-field">
          <input data-search-field-target="input" value="" type="search" />
        </div>
      </form>
    `;
    application = await startController();
    const controller = controllerFor(application);

    expect(() => controller.updateButtons()).not.toThrow();
  });

  it("showSubmitHideClear() reveals the submit button and hides clear", async () => {
    application = await startController();
    const controller = controllerFor(application);
    const clearButton = document.querySelector(
      "[data-search-field-target='clearButton']",
    );
    const submitButton = document.querySelector(
      "[data-search-field-target='submitButton']",
    );
    clearButton.classList.remove("hidden");
    submitButton.classList.add("hidden");

    controller.showSubmitHideClear();

    expect(submitButton.classList.contains("hidden")).toBe(false);
    expect(clearButton.classList.contains("hidden")).toBe(true);
  });

  it("showClearHideSubmit() reveals the clear button and hides submit", async () => {
    application = await startController();
    const controller = controllerFor(application);
    const clearButton = document.querySelector(
      "[data-search-field-target='clearButton']",
    );
    const submitButton = document.querySelector(
      "[data-search-field-target='submitButton']",
    );

    controller.showClearHideSubmit();

    expect(clearButton.classList.contains("hidden")).toBe(false);
    expect(submitButton.classList.contains("hidden")).toBe(true);
  });

  it("updateFocus() focuses the input target when present", async () => {
    application = await startController();
    const controller = controllerFor(application);
    const input = document.querySelector("[data-search-field-target='input']");

    controller.updateFocus();

    expect(input).toHaveFocus();
  });

  it("onFocusin/onFocusout toggle turbo-permanent based on the related target", async () => {
    application = await startController();
    const controller = controllerFor(application);
    const input = document.querySelector("[data-search-field-target='input']");
    const outsideElement = document.createElement("button");
    document.body.appendChild(outsideElement);

    controller.onFocusin({ relatedTarget: outsideElement });
    expect(input).toHaveAttribute("data-turbo-permanent", "");

    controller.onFocusout({ relatedTarget: outsideElement });
    expect(input).not.toHaveAttribute("data-turbo-permanent");
  });

  it("onFocusin/onFocusout ignore focus moving within the control", async () => {
    application = await startController();
    const controller = controllerFor(application);
    const input = document.querySelector("[data-search-field-target='input']");
    const insideElement = document.querySelector(
      "[data-search-field-target='clearButton']",
    );
    input.setAttribute("data-turbo-permanent", "");

    controller.onFocusin({ relatedTarget: insideElement });
    controller.onFocusout({ relatedTarget: insideElement });

    expect(input).toHaveAttribute("data-turbo-permanent", "");
  });

  it("clear() clears the selection outlet when connected", async () => {
    const selectionClear = vi.fn();
    class SelectionStub extends Controller {
      clear() {
        selectionClear();
      }
    }
    document.body.innerHTML = `
      <form>
        <div id="selection" data-controller="selection"></div>
        <div data-controller="search-field"
          data-search-field-selection-outlet="#selection">
          <input data-search-field-target="input" value="abc" type="search" />
          <button data-search-field-target="clearButton" type="button">Clear</button>
          <button data-search-field-target="submitButton" type="submit">Search</button>
        </div>
      </form>
    `;
    application = Application.start();
    application.register("search-field", SearchFieldController);
    application.register("selection", SelectionStub);
    await Promise.resolve();
    const controller = controllerFor(application);
    document.querySelector("form").requestSubmit = vi.fn();

    controller.clear();

    expect(selectionClear).toHaveBeenCalledTimes(1);
  });

  it("beforeSubmit() renders existing search on connected advanced-search outlets", async () => {
    const renderV1 = vi.fn();
    const renderV2 = vi.fn();
    class AdvancedV1Stub extends Controller {
      renderExistingSearch() {
        renderV1();
      }
    }
    class AdvancedV2Stub extends Controller {
      renderExisting() {
        renderV2();
      }
    }
    document.body.innerHTML = `
      <form>
        <div id="v1" data-controller="advanced-search--v1"></div>
        <div id="v2" data-controller="advanced-search--v2--builder"></div>
        <div data-controller="search-field"
          data-search-field-advanced-search--v1-outlet="#v1"
          data-search-field-advanced-search--v2--builder-outlet="#v2">
          <input data-search-field-target="input" value="" type="search" />
          <button data-search-field-target="clearButton" type="button">Clear</button>
          <button data-search-field-target="submitButton" type="submit">Search</button>
        </div>
      </form>
    `;
    application = Application.start();
    application.register("search-field", SearchFieldController);
    application.register("advanced-search--v1", AdvancedV1Stub);
    application.register("advanced-search--v2--builder", AdvancedV2Stub);
    await Promise.resolve();
    const controller = controllerFor(application);

    controller.beforeSubmit();

    expect(renderV1).toHaveBeenCalledTimes(1);
    expect(renderV2).toHaveBeenCalledTimes(1);
  });

  it("beforeSubmit() is a no-op when no advanced-search outlets are connected", async () => {
    application = await startController();
    const controller = controllerFor(application);

    expect(() => controller.beforeSubmit()).not.toThrow();
  });
});
