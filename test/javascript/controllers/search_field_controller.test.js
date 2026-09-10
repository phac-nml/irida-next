import { Application } from "@hotwired/stimulus";
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
});
