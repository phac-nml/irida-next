import { Application } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import AdvancedSearchV1Controller from "../../../../app/javascript/controllers/advanced_search/v1_controller.js";

function renderFixture() {
  document.body.innerHTML = `
    <div
      data-controller="advanced-search--v1"
      data-advanced-search--v1-enum-fields-value="{}"
      data-advanced-search--v1-enum-operations-value='{"standard":{}}'
      data-advanced-search--v1-numeric-fields-value='["byte_size"]'
      data-advanced-search--v1-numeric-operations-value='{"Equals":"=","Between":"between"}'
      data-advanced-search--v1-operations-value='{"standard":{"Equals":"=","Contains":"contains","Between":"between"}}'
    >
      <fieldset data-advanced-search--v1-target="groupsContainer">
        <fieldset data-advanced-search--v1-target="conditionsContainer" data-advanced-search-selected-field="">
          <div class="form-field">
            <select name="q[groups_attributes][0][conditions_attributes][0][field]"
              data-action="change->advanced-search--v1#handleFieldChange">
              <option value=""></option>
              <option value="filename">filename</option>
              <option value="byte_size">byte_size</option>
            </select>
          </div>
          <div class="form-field">
            <select name="q[groups_attributes][0][conditions_attributes][0][operator]"></select>
          </div>
          <div class="value">
            <input name="q[groups_attributes][0][conditions_attributes][0][value]">
          </div>
        </fieldset>
      </fieldset>
    </div>
  `;
}

async function startController() {
  const application = Application.start();
  application.register("advanced-search--v1", AdvancedSearchV1Controller);
  await Promise.resolve();
  return application;
}

function controllerInstance(application) {
  return application.getControllerForElementAndIdentifier(
    document.querySelector('[data-controller="advanced-search--v1"]'),
    "advanced-search--v1",
  );
}

function fieldSelect() {
  return document.querySelector("[name$='[field]']");
}

function operatorSelect() {
  return document.querySelector("[name$='[operator]']");
}

function operatorValues() {
  return Array.from(operatorSelect().options).map((option) => option.value);
}

describe("advanced-search--v1 numeric operator dropdown", () => {
  let application;

  beforeEach(() => {
    renderFixture();
  });

  afterEach(() => {
    application?.stop();
    document.body.innerHTML = "";
  });

  it("restricts operator options to numeric operators when byte_size is selected", async () => {
    application = await startController();
    controllerInstance(application);

    const field = fieldSelect();
    field.value = "byte_size";
    field.dispatchEvent(new Event("change", { bubbles: true }));

    expect(operatorValues()).toContain("between");
    expect(operatorValues()).not.toContain("contains");
  });

  it("restores the full standard operator list when filename is selected", async () => {
    application = await startController();
    controllerInstance(application);

    const field = fieldSelect();
    field.value = "filename";
    field.dispatchEvent(new Event("change", { bubbles: true }));

    expect(operatorValues()).toContain("contains");
  });

  it("updates operator options correctly when switching between filename and byte_size", async () => {
    application = await startController();
    controllerInstance(application);

    const field = fieldSelect();

    field.value = "filename";
    field.dispatchEvent(new Event("change", { bubbles: true }));
    expect(operatorValues()).toContain("contains");
    expect(operatorValues()).toContain("between");

    field.value = "byte_size";
    field.dispatchEvent(new Event("change", { bubbles: true }));
    expect(operatorValues()).not.toContain("contains");
    expect(operatorValues()).toContain("between");

    field.value = "filename";
    field.dispatchEvent(new Event("change", { bubbles: true }));
    expect(operatorValues()).toContain("contains");
    expect(operatorValues()).toContain("between");
  });
});
