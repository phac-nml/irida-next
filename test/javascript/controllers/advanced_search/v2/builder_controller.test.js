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

function listValueTemplateInner(values = []) {
  const name = `q[groups_attributes][${G}][conditions_attributes][${C}][value][]`;
  return `
    <div class="value form-field">
      <div data-controller="list-input" data-list-input-filters-value='${JSON.stringify(values)}'>
        <template data-list-input-target="template">
          <span class="filter-item search-tag">
            <input type="hidden" name="${name}">
            <span class="label"></span>
            <button type="button" data-action="list-input#remove">Remove value</button>
          </span>
        </template>
        <div data-list-input-target="tags">
          <input name="${name}" data-list-input-target="input"
            data-action="paste->list-input#handlePaste">
        </div>
      </div>
    </div>`;
}

function renderFixture({ existingGroups = "", initialState = [] } = {}) {
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
  builderElement().setAttribute(
    "data-advanced-search--v2--builder-initial-state-value",
    JSON.stringify(initialState),
  );
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

function controllerInstance(application) {
  return application.getControllerForElementAndIdentifier(
    builderElement(),
    "advanced-search--v2--builder",
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

  it("removeGroup keeps surviving keys while updating displayed numbers", async () => {
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      builderElement(),
      "advanced-search--v2--builder",
    );
    controller.render();
    controller.addGroup();
    await tick();

    // Removing group 0 must not change group 1's control names or IDs.
    groups()[0]
      .querySelector(
        "button[data-action='advanced-search--v2--builder#removeGroup']",
      )
      .click();
    await tick();

    expect(groups()).toHaveLength(1);
    expect(fieldNames()).toEqual([
      "q[groups_attributes][1][conditions_attributes][0][field]",
    ]);
    expect(groups()[0].querySelector("legend").textContent).toBe("Group 1");
    controller.addGroup();
    expect(fieldNames()).toEqual([
      "q[groups_attributes][1][conditions_attributes][0][field]",
      "q[groups_attributes][2][conditions_attributes][0][field]",
    ]);
    expect(groups()[1].querySelector("legend").textContent).toBe("Group 2");
  });

  it("removeCondition keeps surviving keys while updating displayed numbers", async () => {
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
      "q[groups_attributes][1][conditions_attributes][1][field]",
    ]);
    expect(conditions(group)[0].querySelector("legend").textContent).toBe(
      "Condition 1",
    );
    group.querySelector("button[data-action$='#addCondition']").click();
    expect(fieldNames().at(-1)).toBe(
      "q[groups_attributes][1][conditions_attributes][2][field]",
    );
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
      "q[groups_attributes][0][conditions_attributes][1][field]",
    ]);
  });

  it("replaces enum options under surviving keys without appending duplicates", async () => {
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
    group.querySelector("button[data-action$='#addCondition']").click();
    await tick();
    group.querySelector("button[data-action$='#removeCondition']").click();
    const condition = conditions(group)[0];

    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML =
      '<option value=""></option><option value="status">Status</option>';
    const operator = condition.querySelector("[name$='[operator]']");
    const template = controller.listSelectValueTemplateTarget;
    template.innerHTML = `
      <div class="value form-field">
        <select multiple name="q[groups_attributes][${G}][conditions_attributes][${C}][value][]">
          <option value=""></option>
        </select>
      </div>
    `;

    field.value = "status";
    field.dispatchEvent(new Event("change", { bubbles: true }));
    operator.value = "in";
    operator.dispatchEvent(new Event("change", { bubbles: true }));

    expect(
      Array.from(
        condition.querySelector("select[name$='[value][]']").options,
      ).map((option) => option.value),
    ).toEqual(["draft", "published"]);
    expect(condition.querySelector("select[name$='[value][]']").name).toBe(
      "q[groups_attributes][0][conditions_attributes][1][value][]",
    );

    field.value = "status";
    field.dispatchEvent(new Event("change", { bubbles: true }));
    operator.value = "in";
    operator.dispatchEvent(new Event("change", { bubbles: true }));

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

  it.each([false, true])(
    "compares hydrated saved list values with the query baseline (removed: %s)",
    async (removeValues) => {
      application = await startController();
      const controller = application.getControllerForElementAndIdentifier(
        builderElement(),
        "advanced-search--v2--builder",
      );
      controller.render();
      const condition = conditions(groups()[0])[0];
      condition
        .querySelector("option[value='name']")
        .setAttribute("selected", "");
      condition.querySelector("[name$='[operator]']").innerHTML =
        '<option value="in" selected>In</option>';
      condition.querySelector(".value").outerHTML = listValueTemplateInner([
        "Canada",
        "France",
      ])
        .replaceAll(G, "0")
        .replaceAll(C, "0");
      controller.searchGroupsTemplateTarget.innerHTML =
        controller.searchGroupsContainerTarget.innerHTML;
      controller.initialStateValue = [
        [
          {
            field: "name",
            operator: "in",
            values: ["Canada", "France"],
          },
        ],
      ];
      controller.renderExisting();
      await tick();

      if (removeValues) {
        controller.searchGroupsContainerTarget
          .querySelectorAll("button[data-action='list-input#remove']")
          .forEach((button) => button.click());
      }

      expect(controller.isDirty()).toBe(removeValues);

      // Restoring server state also reconnects the list-input child controller.
      controller.renderExisting();
      await tick();
      expect(controller.isDirty()).toBe(false);
    },
  );

  it("allocates new keys after restoring existing sparse groups and conditions", async () => {
    const existingGroup = groupTemplateInner()
      .replaceAll(G, "3")
      .replace("GROUP_LEGEND_INDEX_PLACEHOLDER", "1")
      .replace(
        "<div>",
        conditionTemplateInner()
          .replaceAll(G, "3")
          .replaceAll(C, "7")
          .replace("CONDITION_LEGEND_INDEX_PLACEHOLDER", "1") + "<div>",
      );
    renderFixture({ existingGroups: existingGroup });
    application = await startController();
    const controller = application.getControllerForElementAndIdentifier(
      builderElement(),
      "advanced-search--v2--builder",
    );
    controller.renderExisting();
    await tick();
    groups()[0].querySelector("button[data-action$='#addCondition']").click();
    controller.addGroup();

    expect(fieldNames()).toEqual([
      "q[groups_attributes][3][conditions_attributes][7][field]",
      "q[groups_attributes][3][conditions_attributes][8][field]",
      "q[groups_attributes][4][conditions_attributes][0][field]",
    ]);
  });

  it.each([
    {
      kind: "scalar",
      operator: "=",
      values: [42],
      inputs: '<input name="value" value="42">',
    },
    {
      kind: "between",
      operator: "between",
      values: ["", "20"],
      inputs:
        '<input name="value[]" value=""><input name="value[]" value="20">',
    },
    {
      kind: "multiselect",
      operator: "in",
      values: ["b", "a", ""],
      inputs:
        '<select name="value[]" multiple><option value="a" selected>A</option><option value="b" selected>B</option></select>',
    },
  ])(
    "compares $kind query values with their rendered representation",
    async ({ kind, operator, values, inputs }) => {
      application = await startController();
      const controller = application.getControllerForElementAndIdentifier(
        builderElement(),
        "advanced-search--v2--builder",
      );
      controller.render();
      const condition = conditions(groups()[0])[0];
      const name = "q[groups_attributes][0][conditions_attributes][0]";
      condition.querySelector("[name$='[field]']").value = "name";
      condition.querySelector("[name$='[operator]']").innerHTML =
        `<option value="${operator}">${operator}</option>`;
      const valueContainer = condition.querySelector(".value");
      valueContainer.innerHTML = inputs.replaceAll(
        'name="value',
        `name="${name}[value]`,
      );
      controller.initialStateValue = [[{ field: "name", operator, values }]];

      expect(controller.isDirty()).toBe(false);
      if (kind === "multiselect") {
        valueContainer.querySelector("option").selected = false;
      } else if (kind === "between") {
        const [from, to] = valueContainer.querySelectorAll("input");
        from.value = "20";
        to.value = "";
      } else {
        valueContainer.querySelector("input").value = "43";
      }
      expect(controller.isDirty()).toBe(true);
    },
  );

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
      controller.listValueTemplateTarget.innerHTML = listValueTemplateInner();
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
        removedNode === "group"
          ? "q[groups_attributes][1][conditions_attributes][0][value][]"
          : "q[groups_attributes][0][conditions_attributes][1][value][]";
      expect(values).toEqual([
        [expectedName, "before-removal"],
        [expectedName, "after-removal"],
      ]);
    },
  );

  it("populates enum selects with derived labels when no label is provided", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.enumFieldsValue = {
      status: { values: ["not_started", "in_progress"] },
    };
    controller.selectValueTemplateTarget.innerHTML = `
      <div class="value form-field">
        <select name="q[groups_attributes][0][conditions_attributes][0][value]">
          <option value=""></option>
        </select>
      </div>`;
    controller.render();
    const condition = conditions(groups()[0])[0];
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML =
      '<option value=""></option><option value="status" selected>Status</option>';
    field.value = "status";
    const operator = condition.querySelector("[name$='[operator]']");
    operator.innerHTML = '<option value="=" selected>=</option>';
    operator.value = "=";

    controller.handleOperatorChange({ target: operator });

    const valueSelect = condition.querySelector("select[name$='[value]']");
    expect(
      Array.from(valueSelect.options).map((option) => option.text),
    ).toEqual(["Not Started", "In Progress"]);
  });

  it("hides and clears the value field for exists-style operators", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.valueTemplateTarget.innerHTML = `
      <div class="value form-field">
        <input name="q[groups_attributes][0][conditions_attributes][0][value]" value="x">
        <select name="q[groups_attributes][0][conditions_attributes][0][extra]">
          <option value="a" selected>a</option>
        </select>
      </div>`;
    controller.render();
    const condition = conditions(groups()[0])[0];
    condition.querySelector("[name$='[field]']").value = "name";
    const operator = condition.querySelector("[name$='[operator]']");
    operator.innerHTML = '<option value="exists" selected>exists</option>';
    operator.value = "exists";

    controller.handleOperatorChange({ target: operator });

    const value = condition.querySelector(".value");
    expect(value.classList.contains("invisible")).toBe(true);
    expect(value.querySelector("input").value).toBe("");
    expect(value.querySelector("select").selectedIndex).toBe(-1);
  });

  it("renders the between value template for range operators", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.betweenValueTemplateTarget.innerHTML = `
      <div class="value form-field">
        <input name="q[groups_attributes][0][conditions_attributes][0][value][]">
        <input name="q[groups_attributes][0][conditions_attributes][0][value][]">
      </div>`;
    controller.render();
    const condition = conditions(groups()[0])[0];
    condition.querySelector("[name$='[field]']").value = "created_at";
    const operator = condition.querySelector("[name$='[operator]']");
    operator.innerHTML = '<option value="between" selected>between</option>';
    operator.value = "between";

    controller.handleOperatorChange({ target: operator });

    expect(condition.querySelectorAll(".value input")).toHaveLength(2);
  });

  it("removes the extra value element when re-rendering after a between operator", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.valueTemplateTarget.innerHTML = `
      <div class="value form-field">
        <input name="q[groups_attributes][0][conditions_attributes][0][value]">
      </div>`;
    controller.render();
    const condition = conditions(groups()[0])[0];
    const extraValue = condition.querySelector(".value").cloneNode(true);
    condition.querySelector(".value").after(extraValue);
    const operator = condition.querySelector("[name$='[operator]']");
    operator.innerHTML = '<option value="=" selected>=</option>';
    operator.value = "=";

    controller.handleOperatorChange({ target: operator });

    expect(condition.querySelectorAll(".value")).toHaveLength(1);
  });

  it("ignores structural changes triggered outside a condition or group", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    const detached = document.createElement("button");
    const detachedSelect = document.createElement("select");

    expect(() =>
      controller.removeCondition({ currentTarget: detached }),
    ).not.toThrow();
    // Single group: the length guard short-circuits removeGroup.
    expect(() =>
      controller.removeGroup({ currentTarget: detached }),
    ).not.toThrow();
    controller.addGroup();
    // Two groups but the event originates outside any group.
    expect(() =>
      controller.removeGroup({ currentTarget: detached }),
    ).not.toThrow();
    expect(groups()).toHaveLength(2);
    expect(() =>
      controller.handleOperatorChange({ target: detachedSelect }),
    ).not.toThrow();
    expect(() =>
      controller.handleFieldChange({ target: detachedSelect }),
    ).not.toThrow();
  });

  it("ignores operator changes when the condition has no value field", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    const condition = conditions(groups()[0])[0];
    condition.querySelector(".value").remove();
    const operator = condition.querySelector("[name$='[operator]']");

    expect(() =>
      controller.handleOperatorChange({ target: operator }),
    ).not.toThrow();
  });

  it("ignores field changes when the condition has no operator field", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    const condition = conditions(groups()[0])[0];
    condition
      .querySelector("[name$='[operator]']")
      .closest(".form-field")
      .remove();
    const field = condition.querySelector("[name$='[field]']");
    field.value = "name";

    expect(() => controller.handleFieldChange({ target: field })).not.toThrow();
  });

  it("handles field changes when the condition has no value element", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    const condition = conditions(groups()[0])[0];
    condition.querySelector(".value").remove();
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML = '<option value="name" selected>name</option>';
    field.value = "name";

    expect(() => controller.handleFieldChange({ target: field })).not.toThrow();
  });

  it("skips re-rendering when the selected field is unchanged", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    const condition = conditions(groups()[0])[0];
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML = '<option value="name" selected>name</option>';
    field.value = "name";

    controller.handleFieldChange({ target: field });
    const operatorHtml = condition.querySelector(
      "[name$='[operator]']",
    ).innerHTML;
    controller.handleFieldChange({ target: field });

    expect(condition.querySelector("[name$='[operator]']").innerHTML).toBe(
      operatorHtml,
    );
  });

  it("hides the operator dropdown when the field is cleared", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    const condition = conditions(groups()[0])[0];
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML =
      '<option value="" selected></option><option value="name">name</option>';
    field.value = "name";
    controller.handleFieldChange({ target: field });
    field.value = "";

    controller.handleFieldChange({ target: field });

    const operatorContainer = condition
      .querySelector("[name$='[operator]']")
      .closest(".form-field");
    expect(operatorContainer.classList.contains("invisible")).toBe(true);
  });

  it("clears rendered value inputs when switching fields", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    const condition = conditions(groups()[0])[0];
    condition.querySelector(".value").innerHTML = `
      <select name="q[groups_attributes][0][conditions_attributes][0][value]">
        <option value="a" selected>a</option>
      </select>`;
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML = '<option value="name" selected>name</option>';
    field.value = "name";

    controller.handleFieldChange({ target: field });

    expect(condition.querySelector(".value select").selectedIndex).toBe(-1);
  });

  it("builds grouped metadata operator options for non-enum metadata fields", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.operationsValue = {
      standard: { Equals: "=" },
      metadata: { Numbers: { "Greater than": ">" } },
    };
    controller.render();
    const condition = conditions(groups()[0])[0];
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML =
      '<option value=""></option><option value="metadata.age" selected>age</option>';
    field.value = "metadata.age";

    controller.handleFieldChange({ target: field });

    const operator = condition.querySelector("[name$='[operator]']");
    expect(operator.querySelector("optgroup").label).toBe("Numbers");
  });

  it("uses enum metadata operators for enum metadata fields", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.enumFieldsValue = { "metadata.status": { values: ["a"] } };
    controller.operationsValue = {
      standard: { Equals: "=" },
      metadata: { Equals: "=" },
    };
    controller.enumOperationsValue = {
      standard: { Equals: "=" },
      metadata: { In: "in" },
    };
    controller.render();
    const condition = conditions(groups()[0])[0];
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML =
      '<option value=""></option><option value="metadata.status" selected>status</option>';
    field.value = "metadata.status";

    controller.handleFieldChange({ target: field });

    const operator = condition.querySelector("[name$='[operator]']");
    expect(
      Array.from(operator.options).map((option) => option.value),
    ).toContain("in");
  });

  it("skips groups without a remove-group button when toggling", async () => {
    const groupWithoutRemove = `
      <fieldset data-advanced-search--v2--builder-target="groupsContainer"
        data-advanced-search--v2--builder-group-index="0"
        data-advanced-search--v2--builder-legend-template="Group __INDEX__">
        <legend>Group 1</legend>
        <fieldset data-advanced-search--v2--builder-target="conditionsContainer"
          data-advanced-search--v2--builder-group-index="0"
          data-advanced-search--v2--builder-condition-index="0"
          data-advanced-search--v2--builder-legend-template="Condition __INDEX__">
          <legend>Condition 1</legend>
          <input name="q[groups_attributes][0][conditions_attributes][0][field]">
        </fieldset>
      </fieldset>`;
    renderFixture({ existingGroups: groupWithoutRemove });
    application = await startController();
    const controller = controllerInstance(application);
    controller.renderExisting();

    expect(() => controller.addGroup()).not.toThrow();
    expect(groups()).toHaveLength(2);
  });

  it("skips legend updates for containers without a legend", async () => {
    const groupWithoutLegend = `
      <fieldset data-advanced-search--v2--builder-target="groupsContainer"
        data-advanced-search--v2--builder-group-index="0"
        data-advanced-search--v2--builder-legend-template="Group __INDEX__">
        <fieldset data-advanced-search--v2--builder-target="conditionsContainer"
          data-advanced-search--v2--builder-group-index="0"
          data-advanced-search--v2--builder-condition-index="0">
          <input name="q[groups_attributes][0][conditions_attributes][0][field]">
        </fieldset>
        <div>
          <button type="button" data-action="advanced-search--v2--builder#addCondition">Add</button>
          <button type="button" data-action="advanced-search--v2--builder#removeGroup">Remove group</button>
        </div>
      </fieldset>`;
    renderFixture({ existingGroups: groupWithoutLegend });
    application = await startController();
    const controller = controllerInstance(application);
    controller.renderExisting();
    controller.addGroup();
    await tick();

    // Removing the second group re-numbers survivors; the first has no legend.
    groups()[1].querySelector("button[data-action$='#removeGroup']").click();
    await tick();

    expect(groups()).toHaveLength(1);
    expect(groups()[0].querySelector("legend")).toBeNull();
  });

  it("focuses a fallback input when the surviving condition has no field control", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    await tick();
    const group = groups()[0];
    group.querySelector("button[data-action$='#addCondition']").click();
    await tick();

    const survivor = conditions(group)[1];
    survivor.querySelector("[name$='[field]']").closest(".form-field").remove();
    conditions(group)[0]
      .querySelector("button[data-action$='#removeCondition']")
      .click();
    await tick();

    expect(survivor.contains(document.activeElement)).toBe(true);
  });

  it("serializes multi-select values from selected options", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    const condition = conditions(groups()[0])[0];
    const name = "q[groups_attributes][0][conditions_attributes][0]";
    condition.querySelector("[name$='[field]']").value = "name";
    condition.querySelector("[name$='[operator]']").innerHTML =
      '<option value="in" selected>in</option>';
    condition.querySelector(".value").innerHTML =
      `<select name="${name}[value][]" multiple>
        <option value="b" selected>B</option>
        <option value="a" selected>A</option>
      </select>`;
    controller.initialStateValue = [
      [{ field: "name", operator: "in", values: ["a", "b"] }],
    ];

    expect(controller.isDirty()).toBe(false);
    condition.querySelector("option[value='a']").selected = false;
    expect(controller.isDirty()).toBe(true);
  });

  it("returns early for exists operators when the template has no value node", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.valueTemplateTarget.innerHTML = "<span>no value node</span>";
    controller.render();
    const condition = conditions(groups()[0])[0];
    condition.querySelector("[name$='[field]']").value = "name";
    const operator = condition.querySelector("[name$='[operator]']");
    operator.innerHTML = '<option value="exists" selected>exists</option>';
    operator.value = "exists";

    expect(() =>
      controller.handleOperatorChange({ target: operator }),
    ).not.toThrow();
    expect(condition.querySelector(".value")).toBeNull();
  });

  it("ignores add-condition events fired outside a group", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();

    expect(() =>
      controller.addCondition({
        currentTarget: document.createElement("button"),
      }),
    ).not.toThrow();
  });

  it("appends a condition at the end when the group has no actions container", async () => {
    const groupWithoutActions = `
      <fieldset data-advanced-search--v2--builder-target="groupsContainer"
        data-advanced-search--v2--builder-group-index="0"
        data-advanced-search--v2--builder-legend-template="Group __INDEX__">
        <legend>Group 1</legend>
        <fieldset data-advanced-search--v2--builder-target="conditionsContainer"
          data-advanced-search--v2--builder-group-index="0"
          data-advanced-search--v2--builder-condition-index="0"
          data-advanced-search--v2--builder-legend-template="Condition __INDEX__">
          <legend>Condition 1</legend>
          <input name="q[groups_attributes][0][conditions_attributes][0][field]">
          <button type="button" data-action="advanced-search--v2--builder#removeCondition">x</button>
        </fieldset>
      </fieldset>`;
    renderFixture({ existingGroups: groupWithoutActions });
    application = await startController();
    const controller = controllerInstance(application);
    controller.renderExisting();
    await tick();

    groups()[0]
      .querySelector("button[data-action$='#removeCondition']")
      .click();
    await tick();

    expect(conditions(groups()[0])).toHaveLength(1);
  });

  it("handles removing a group when the surviving group has no conditions", async () => {
    const groupWithCondition = `
      <fieldset data-advanced-search--v2--builder-target="groupsContainer"
        data-advanced-search--v2--builder-group-index="0"
        data-advanced-search--v2--builder-legend-template="Group __INDEX__">
        <legend>Group 1</legend>
        <fieldset data-advanced-search--v2--builder-target="conditionsContainer"
          data-advanced-search--v2--builder-group-index="0"
          data-advanced-search--v2--builder-condition-index="0"
          data-advanced-search--v2--builder-legend-template="Condition 1">
          <legend>Condition 1</legend>
          <input name="q[groups_attributes][0][conditions_attributes][0][field]">
        </fieldset>
        <div>
          <button type="button" data-action="advanced-search--v2--builder#removeGroup">Remove group</button>
        </div>
      </fieldset>`;
    const emptyGroup = `
      <fieldset data-advanced-search--v2--builder-target="groupsContainer"
        data-advanced-search--v2--builder-group-index="1"
        data-advanced-search--v2--builder-legend-template="Group __INDEX__">
        <legend>Group 2</legend>
        <div>
          <button type="button" data-action="advanced-search--v2--builder#removeGroup">Remove group</button>
        </div>
      </fieldset>`;
    renderFixture({ existingGroups: groupWithCondition + emptyGroup });
    application = await startController();
    const controller = controllerInstance(application);
    controller.renderExisting();
    await tick();

    groups()[0].querySelector("button[data-action$='#removeGroup']").click();
    await tick();

    expect(groups()).toHaveLength(1);
  });

  it("renders enum options from labels when values are omitted", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.enumFieldsValue = { status: { labels: { draft: "Draft" } } };
    controller.selectValueTemplateTarget.innerHTML = `
      <div class="value form-field">
        <select name="q[groups_attributes][0][conditions_attributes][0][value]">
          <option value=""></option>
        </select>
      </div>`;
    controller.render();
    const condition = conditions(groups()[0])[0];
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML =
      '<option value=""></option><option value="status" selected>Status</option>';
    field.value = "status";
    const operator = condition.querySelector("[name$='[operator]']");
    operator.innerHTML = '<option value="=" selected>=</option>';
    operator.value = "=";

    controller.handleOperatorChange({ target: operator });

    expect(
      condition.querySelector("select[name$='[value]']").options,
    ).toHaveLength(0);
  });

  it("skips enum value population when the enum template has no value node", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.enumFieldsValue = { status: { values: ["a"] } };
    controller.selectValueTemplateTarget.innerHTML = "<span>no value</span>";
    controller.render();
    const condition = conditions(groups()[0])[0];
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML =
      '<option value=""></option><option value="status" selected>Status</option>';
    field.value = "status";
    const operator = condition.querySelector("[name$='[operator]']");
    operator.innerHTML = '<option value="=" selected>=</option>';
    operator.value = "=";

    expect(() =>
      controller.handleOperatorChange({ target: operator }),
    ).not.toThrow();
  });

  it("skips enum population when the enum config has no values or labels", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.enumFieldsValue = { status: {} };
    controller.selectValueTemplateTarget.innerHTML = `
      <div class="value form-field">
        <select name="q[groups_attributes][0][conditions_attributes][0][value]"></select>
      </div>`;
    controller.render();
    const condition = conditions(groups()[0])[0];
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML =
      '<option value=""></option><option value="status" selected>Status</option>';
    field.value = "status";
    const operator = condition.querySelector("[name$='[operator]']");
    operator.innerHTML = '<option value="=" selected>=</option>';
    operator.value = "=";

    controller.handleOperatorChange({ target: operator });

    expect(
      condition.querySelector("select[name$='[value]']").options,
    ).toHaveLength(0);
  });

  it("skips enum population when the value container has no select", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.enumFieldsValue = { status: { values: ["a"] } };
    controller.selectValueTemplateTarget.innerHTML = `
      <div class="value form-field">
        <input name="q[groups_attributes][0][conditions_attributes][0][value]">
      </div>`;
    controller.render();
    const condition = conditions(groups()[0])[0];
    const field = condition.querySelector("[name$='[field]']");
    field.innerHTML =
      '<option value=""></option><option value="status" selected>Status</option>';
    field.value = "status";
    const operator = condition.querySelector("[name$='[operator]']");
    operator.innerHTML = '<option value="=" selected>=</option>';
    operator.value = "=";

    expect(() =>
      controller.handleOperatorChange({ target: operator }),
    ).not.toThrow();
  });

  it("serializes non-multiple selects and plain list inputs as their values", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    const condition = conditions(groups()[0])[0];
    const name = "q[groups_attributes][0][conditions_attributes][0]";
    condition.querySelector("[name$='[field]']").value = "name";
    condition.querySelector("[name$='[operator]']").innerHTML =
      '<option value="in" selected>in</option>';
    condition.querySelector(".value").innerHTML = `
      <select name="${name}[value][]"><option value="x" selected>x</option></select>
      <input name="${name}[value][]" value="y">`;
    controller.initialStateValue = [
      [{ field: "name", operator: "in", values: ["x", "y"] }],
    ];

    expect(controller.isDirty()).toBe(false);
  });

  it("serializes query-state defaults for sparse conditions", async () => {
    application = await startController();
    const controller = controllerInstance(application);
    controller.render();
    controller.initialStateValue = [
      [{ operator: "between", values: [] }, { values: [null] }],
    ];

    expect(controller.isDirty()).toBe(true);
  });
});
