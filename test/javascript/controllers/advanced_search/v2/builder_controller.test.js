import { Application } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it } from "vitest";
import BuilderController from "../../../../../app/javascript/controllers/advanced_search/v2/builder_controller.js";
import ListInputController from "../../../../../app/javascript/controllers/list_input_controller.js";

// Rails `fields_for` produces these name/id patterns for the group/condition nesting.
// The JS builder must preserve them exactly so submitted params match the server contract
// (the same `q[groups_attributes][G][conditions_attributes][C][...]` shape that
// SamplesAdvancedSearchHelper#samples_advanced_search_params builds).
const G = "GROUP_INDEX_PLACEHOLDER";
const C = "CONDITION_INDEX_PLACEHOLDER";

function conditionTemplateInner() {
  const base = `q[groups_attributes][${G}][conditions_attributes][${C}]`;
  const id = `q_groups_attributes_${G}_conditions_attributes_${C}`;
  return `
    <fieldset
      data-advanced-search--v2--builder-target="conditionsContainer"
      data-advanced-search--v2--builder-group-index="${G}"
      data-advanced-search--v2--builder-condition-index="${C}"
      data-advanced-search--v2--builder-legend-template="Condition __INDEX__"
      data-advanced-search-selected-field=""
    >
      <legend>Condition CONDITION_LEGEND_INDEX_PLACEHOLDER</legend>
      <div class="form-field">
        <select id="${id}_field" name="${base}[field]"
          data-action="change->advanced-search--v2--builder#handleFieldChange">
          <option value=""></option>
          <option value="name">name</option>
        </select>
      </div>
      <div class="form-field">
        <select id="${id}_operator" name="${base}[operator]"
          data-action="advanced-search--v2--builder#handleOperatorChange">
          <option value=""></option>
          <option value="=">=</option>
        </select>
      </div>
      <div class="value form-field">
        <input id="${id}_value" name="${base}[value]" type="text">
      </div>
      <button type="button" data-action="advanced-search--v2--builder#removeCondition">x</button>
    </fieldset>
  `;
}

function groupTemplateInner() {
  return `
    <fieldset
      data-advanced-search--v2--builder-target="groupsContainer"
      data-advanced-search--v2--builder-group-index="${G}"
      data-advanced-search--v2--builder-legend-template="Group __INDEX__"
    >
      <legend>Group GROUP_LEGEND_INDEX_PLACEHOLDER</legend>
      <div>
        <button type="button" data-action="advanced-search--v2--builder#addCondition">Add condition</button>
        <button type="button" class="hidden" data-action="advanced-search--v2--builder#removeGroup">Remove group</button>
      </div>
    </fieldset>
  `;
}

function renderFixture({ existingGroups = "" } = {}) {
  document.body.innerHTML = `
    <div
      data-controller="advanced-search--v2--builder"
      data-advanced-search--v2--builder-enum-fields-value="{}"
      data-advanced-search--v2--builder-enum-operations-value='{"standard":{}}'
      data-advanced-search--v2--builder-operations-value='{"standard":{"Equals":"="}}'
    >
      <div data-advanced-search--v2--builder-target="searchGroupsContainer"></div>
      <template data-advanced-search--v2--builder-target="searchGroupsTemplate">${existingGroups}</template>
      <template data-advanced-search--v2--builder-target="groupTemplate">${groupTemplateInner()}</template>
      <template data-advanced-search--v2--builder-target="conditionTemplate">${conditionTemplateInner()}</template>
      <template data-advanced-search--v2--builder-target="valueTemplate"></template>
      <template data-advanced-search--v2--builder-target="betweenValueTemplate"></template>
      <template data-advanced-search--v2--builder-target="listValueTemplate"></template>
      <template data-advanced-search--v2--builder-target="listSelectValueTemplate"></template>
      <template data-advanced-search--v2--builder-target="selectValueTemplate"></template>
      <template data-advanced-search--v2--builder-target="emptySearchTemplate">
        <input type="hidden" name="q[groups_attributes]" value="">
      </template>
    </div>
  `;
}

async function startController() {
  const application = Application.start();
  application.register("advanced-search--v2--builder", BuilderController);
  application.register("list-input", ListInputController);
  await Promise.resolve();
  return application;
}

// Lets Stimulus' MutationObserver bind actions on dynamically inserted elements.
function tick() {
  return new Promise((resolve) => setTimeout(resolve, 0));
}

function builderElement() {
  return document.querySelector(
    '[data-controller="advanced-search--v2--builder"]',
  );
}

function groups() {
  return Array.from(
    document.querySelectorAll(
      "fieldset[data-advanced-search--v2--builder-target='groupsContainer']",
    ),
  );
}

function conditions(group) {
  return Array.from(
    group.querySelectorAll(
      "fieldset[data-advanced-search--v2--builder-target='conditionsContainer']",
    ),
  );
}

function fieldNames() {
  return Array.from(document.querySelectorAll("[name$='[field]']")).map((el) =>
    el.getAttribute("name"),
  );
}

describe("advanced-search--v2--builder", () => {
  let application;

  beforeEach(() => {
    renderFixture();
  });

  afterEach(() => {
    application?.stop();
    document.body.innerHTML = "";
  });

  it("render() seeds one group with one condition using index 0 params", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      builderElement(),
      "advanced-search--v2--builder",
    );
    controller.render();

    expect(groups()).toHaveLength(1);
    expect(conditions(groups()[0])).toHaveLength(1);
    expect(fieldNames()).toEqual([
      "q[groups_attributes][0][conditions_attributes][0][field]",
    ]);
  });

  it("addCondition appends conditions with incrementing indices", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      builderElement(),
      "advanced-search--v2--builder",
    );
    controller.render();
    await tick();

    groups()[0]
      .querySelector(
        "button[data-action='advanced-search--v2--builder#addCondition']",
      )
      .click();
    await tick();

    expect(conditions(groups()[0])).toHaveLength(2);
    expect(fieldNames()).toEqual([
      "q[groups_attributes][0][conditions_attributes][0][field]",
      "q[groups_attributes][0][conditions_attributes][1][field]",
    ]);
  });

  it("addGroup appends a second group at index 1 with its own condition", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      builderElement(),
      "advanced-search--v2--builder",
    );
    controller.render();
    controller.addGroup();

    expect(groups()).toHaveLength(2);
    expect(fieldNames()).toEqual([
      "q[groups_attributes][0][conditions_attributes][0][field]",
      "q[groups_attributes][1][conditions_attributes][0][field]",
    ]);
  });

  it("removeGroup reindexes remaining groups to a contiguous 0-based sequence", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      builderElement(),
      "advanced-search--v2--builder",
    );
    controller.render();
    controller.addGroup();
    await tick();

    // Remove the first group; the survivor must reindex from 1 -> 0.
    groups()[0]
      .querySelector(
        "button[data-action='advanced-search--v2--builder#removeGroup']",
      )
      .click();
    await tick();

    expect(groups()).toHaveLength(1);
    expect(fieldNames()).toEqual([
      "q[groups_attributes][0][conditions_attributes][0][field]",
    ]);
  });

  it("removeCondition reindexes the remaining conditions in the group", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      builderElement(),
      "advanced-search--v2--builder",
    );
    controller.render();
    await tick();
    controller.addGroup();
    await tick();

    // Second group starts with one condition; add a second, then remove the first.
    const group = groups()[1];
    group
      .querySelector(
        "button[data-action='advanced-search--v2--builder#addCondition']",
      )
      .click();
    await tick();
    group
      .querySelectorAll(
        "button[data-action='advanced-search--v2--builder#removeCondition']",
      )[0]
      .click();
    await tick();

    expect(conditions(groups()[1])).toHaveLength(1);
    expect(fieldNames()).toEqual([
      "q[groups_attributes][0][conditions_attributes][0][field]",
      "q[groups_attributes][1][conditions_attributes][0][field]",
    ]);
  });

  it("re-adds an empty condition when the last one in a group is removed", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      builderElement(),
      "advanced-search--v2--builder",
    );
    controller.render();
    await tick();

    groups()[0]
      .querySelector(
        "button[data-action='advanced-search--v2--builder#removeCondition']",
      )
      .click();
    await tick();

    expect(conditions(groups()[0])).toHaveLength(1);
    expect(fieldNames()).toEqual([
      "q[groups_attributes][0][conditions_attributes][0][field]",
    ]);
  });

  it("replaces enum options without appending duplicates on re-selection", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      builderElement(),
      "advanced-search--v2--builder",
    );
    controller.enumFieldsValue = {
      status: {
        values: ["draft", "published"],
        labels: { draft: "Draft", published: "Published" },
      },
    };
    controller.enumOperationsValue = {
      standard: {
        Equals: "=",
        In: "in",
      },
    };
    controller.operationsValue = {
      standard: {
        Equals: "=",
        In: "in",
      },
    };
    controller.render();
    await tick();

    const group = groups()[0];
    const condition = document.createElement("fieldset");
    condition.setAttribute(
      "data-advanced-search--v2--builder-target",
      "conditionsContainer",
    );
    condition.dataset.advancedSearchSelectedField = "";
    condition.innerHTML = `
      <div class="form-field">
        <select name="q[groups_attributes][0][conditions_attributes][0][field]">
          <option value=""></option>
          <option value="status">status</option>
        </select>
      </div>
      <div class="form-field">
        <select name="q[groups_attributes][0][conditions_attributes][0][operator]">
          <option value=""></option>
          <option value="in">in</option>
        </select>
      </div>
      <div class="value form-field">
        <select name="q[groups_attributes][0][conditions_attributes][0][value][]">
          <option value=""></option>
        </select>
      </div>
    `;
    group.appendChild(condition);

    const field = condition.querySelector("[name$='[field]']");
    const operator = condition.querySelector("[name$='[operator]']");
    const template = controller.listSelectValueTemplateTarget;
    template.innerHTML = `
      <div class="value form-field">
        <select name="q[groups_attributes][0][conditions_attributes][0][value][]">
          <option value=""></option>
        </select>
      </div>
    `;

    field.value = "status";
    controller.handleFieldChange({ target: field });
    operator.value = "in";
    controller.handleOperatorChange({ target: operator });

    expect(
      Array.from(
        condition.querySelector("select[name$='[value][]']").options,
      ).map((option) => option.value),
    ).toEqual(["draft", "published"]);

    field.value = "status";
    controller.handleFieldChange({ target: field });
    operator.value = "in";
    controller.handleOperatorChange({ target: operator });

    expect(
      Array.from(
        condition.querySelector("select[name$='[value][]']").options,
      ).map((option) => option.value),
    ).toEqual(["draft", "published"]);
  });

  it("clearForm replaces the builder with the blank groups_attributes hidden field", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      builderElement(),
      "advanced-search--v2--builder",
    );
    controller.render();
    controller.clearForm();

    expect(groups()).toHaveLength(0);
    expect(
      document.querySelector("input[name='q[groups_attributes]']").value,
    ).toBe("");
  });

  it.each(["group", "condition"])(
    "keeps newly pasted list values in the surviving condition after removing a %s",
    async (removedNode) => {
      const form = document.createElement("form");
      const builder = builderElement();
      // Move the rendered fixture into a form so assertions use submitted values.
      builder.replaceWith(form);
      form.appendChild(builder);
      application = await startController();
      const controller = application.getControllerForElementAndIdentifier(
        builderElement(),
        "advanced-search--v2--builder",
      );
      controller.operationsValue = { standard: { In: "in" } };
      const name = `q[groups_attributes][${G}][conditions_attributes][${C}][value][]`;
      controller.listValueTemplateTarget.innerHTML = `
        <div class="value form-field">
          <div data-controller="list-input" data-list-input-filters-value="[]">
            <template data-list-input-target="template">
              <span class="filter-item search-tag">
                <input type="hidden" name="${name}">
                <span class="label"></span>
              </span>
            </template>
            <div data-list-input-target="tags">
              <input name="${name}" data-list-input-target="input"
                data-action="paste->list-input#handlePaste">
            </div>
          </div>
        </div>`;
      controller.render();
      await tick();
      if (removedNode === "group") {
        controller.addGroup();
      } else {
        groups()[0]
          .querySelector("button[data-action$='#addCondition']")
          .click();
      }
      await tick();

      const survivor = conditions(groups().at(-1)).at(-1);
      const field = survivor.querySelector("[name$='[field]']");
      field.value = "name";
      field.dispatchEvent(new Event("change", { bubbles: true }));
      const operator = survivor.querySelector("[name$='[operator]']");
      operator.value = "in";
      operator.dispatchEvent(new Event("change", { bubbles: true }));
      await tick();

      const paste = (value) => {
        const event = new Event("paste", { bubbles: true, cancelable: true });
        Object.defineProperty(event, "clipboardData", {
          value: { getData: () => value },
        });
        survivor
          .querySelector("[data-list-input-target='input']")
          .dispatchEvent(event);
      };
      paste("before-removal");
      groups()[0]
        .querySelector(
          `button[data-action$='#remove${removedNode === "group" ? "Group" : "Condition"}']`,
        )
        .click();
      await tick();
      paste("after-removal");

      const values = Array.from(new FormData(form)).filter(
        ([key, value]) => key.endsWith("[value][]") && value !== "",
      );
      const expectedName =
        "q[groups_attributes][0][conditions_attributes][0][value][]";
      expect(values).toEqual([
        [expectedName, "before-removal"],
        [expectedName, "after-removal"],
      ]);
    },
  );
});
