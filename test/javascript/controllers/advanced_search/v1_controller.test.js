import { Application } from "@hotwired/stimulus";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import AdvancedSearchController from "../../../../app/javascript/controllers/advanced_search/v1_controller.js";

const identifier = "advanced-search--v1";
const G = "GROUP_INDEX_PLACEHOLDER";
const C = "CONDITION_INDEX_PLACEHOLDER";
const name = `q[groups_attributes][${G}][conditions_attributes][${C}]`;
const id = `q_groups_attributes_${G}_conditions_attributes_${C}`;
const target = (value) => `[data-${identifier}-target='${value}']`;
const tick = () => new Promise((resolve) => setTimeout(resolve, 0));
const valueTemplate = (controls) =>
  `<div class="value form-field">${controls}</div>`;
const textValue = valueTemplate(
  `<input name="${name}[value]" id="${id}_value">`,
);
const conditionTemplate = `
  <fieldset data-${identifier}-target="conditionsContainer"
    data-${identifier}-legend-template="Condition __INDEX__">
    <legend>Condition CONDITION_LEGEND_INDEX_PLACEHOLDER</legend>
    <div class="form-field">
      <label for="${id}_field">Field</label>
      <input name="${name}[field]" id="${id}_field" aria-describedby="${id}_error" data-action="change->${identifier}#handleFieldChange">
      <span id="${id}_error"></span><span id="unchanged"></span><span id=""></span>
    </div>
    <div class="form-field invisible @max-xl:hidden">
      <select name="${name}[operator]" data-action="change->${identifier}#handleOperatorChange"><option value=""></option></select>
    </div>
    ${textValue}
    <button data-action="${identifier}#removeCondition">Remove condition</button>
  </fieldset>`;
const groupTemplate = `
  <fieldset data-${identifier}-target="groupsContainer" data-${identifier}-legend-template="Group __INDEX__">
    <legend>Group GROUP_LEGEND_INDEX_PLACEHOLDER</legend>
    <div><button data-action="${identifier}#addCondition">Add condition</button>
      <button data-action="${identifier}#removeGroup">Remove group</button></div>
  </fieldset>`;

describe(identifier, () => {
  let application;
  let controller;
  let root;
  const groups = () => [
    ...root.querySelectorAll(`fieldset${target("groupsContainer")}`),
  ];
  const conditions = (group = groups()[0]) => [
    ...group.querySelectorAll(target("conditionsContainer")),
  ];
  const field = (condition = conditions()[0]) =>
    condition.querySelector("[name$='[field]']");
  const operator = (condition = conditions()[0]) =>
    condition.querySelector("[name$='[operator]']");
  const value = (condition = conditions()[0]) =>
    condition.querySelector(".value");
  const button = (element, action) =>
    element.querySelector(`button[data-action='${identifier}#${action}']`);
  const change = (input, next) => {
    input.value = next;
    input.dispatchEvent(new Event("change", { bubbles: true }));
  };
  const close = (
    event = new CustomEvent("viral--dialog:close", { cancelable: true }),
  ) => {
    controller.close(event);
    return event;
  };

  async function mount({ open = true, existing = "" } = {}) {
    document.body.innerHTML = `<div data-controller="${identifier}"
      data-${identifier}-open-value="${open}" data-${identifier}-status-value="true"
      data-${identifier}-confirm-close-text-value="Discard changes?">
      <div data-${identifier}-target="searchGroupsContainer"></div>
      ${Object.entries({
        searchGroupsTemplate: existing,
        groupTemplate,
        conditionTemplate,
        valueTemplate: textValue,
        betweenValueTemplate:
          valueTemplate(`<input name="${name}[value][]">`) +
          valueTemplate(`<input name="${name}[value][]">`),
        listValueTemplate: valueTemplate(`<input name="${name}[value][]">`),
        selectValueTemplate: valueTemplate(
          `<select name="${name}[value]"><option value=""></option></select>`,
        ),
        listSelectValueTemplate: valueTemplate(
          `<select multiple name="${name}[value][]"></select>`,
        ),
        emptySearchTemplate:
          '<input type="hidden" name="q[groups_attributes]" value="">',
      })
        .map(
          ([key, html]) =>
            `<template data-${identifier}-target="${key}">${html}</template>`,
        )
        .join("")}
    </div>`;
    root = document.querySelector(`[data-controller='${identifier}']`);
    application = Application.start();
    application.register(identifier, AdvancedSearchController);
    await tick();
    controller = application.getControllerForElementAndIdentifier(
      root,
      identifier,
    );
    controller.operationsValue = {
      standard: {
        Equals: "=",
        In: "in",
        "Not in": "not_in",
        "Text in": "text_in",
        "Text not in": "text_not_in",
        Between: "between",
        "Not between": "not_between",
        Exists: "exists",
        "Not exists": "not_exists",
      },
      metadata: { Text: { Contains: "contains" }, Numeric: { Greater: ">" } },
    };
    controller.enumOperationsValue = {
      standard: { Equals: "=", In: "in" },
      metadata: { "Enum metadata": "=" },
    };
  }

  beforeEach(async () => {
    await mount();
  });
  afterEach(async () => {
    document.body.replaceChildren();
    await tick();
    application.stop();
  });

  it("seeds a blank group on open and focuses its field", () => {
    expect(groups()).toHaveLength(1);
    expect(conditions()).toHaveLength(1);
    expect(field()).toHaveFocus();
    expect(field().name).toBe(
      "q[groups_attributes][0][conditions_attributes][0][field]",
    );
    expect(button(groups()[0], "removeGroup")).toHaveClass("hidden");
  });

  it("renders saved searches and only reacts to morph while open, detaching on disconnect", async () => {
    const saved = controller.searchGroupsContainerTarget.innerHTML;
    controller.searchGroupsTemplateTarget.innerHTML = saved;
    controller.openValue = false;
    controller.clear();
    document.dispatchEvent(new Event("turbo:morph"));
    expect(groups()).toHaveLength(0);
    controller.openValue = true;
    document.dispatchEvent(new Event("turbo:morph"));
    expect(groups()).toHaveLength(1);
    const render = vi.spyOn(controller, "renderSearch");
    root.remove();
    await tick();
    document.dispatchEvent(new Event("turbo:morph"));
    expect(render).not.toHaveBeenCalled();
  });

  it("adds and removes conditions through bound actions, renumbering names, IDs and label/error links", async () => {
    button(groups()[0], "addCondition").click();
    await tick();
    expect(conditions()).toHaveLength(2);
    const survivor = conditions()[1];
    button(conditions()[0], "removeCondition").click();
    expect(conditions()).toEqual([survivor]);
    expect(field(survivor)).toHaveFocus();
    expect(field(survivor).name).toBe(
      "q[groups_attributes][0][conditions_attributes][0][field]",
    );
    expect(survivor.querySelector("label").htmlFor).toBe(field(survivor).id);
    expect(field(survivor).getAttribute("aria-describedby")).toBe(
      "q_groups_attributes_0_conditions_attributes_0_error",
    );
    expect(survivor.querySelector("legend")).toHaveTextContent("Condition 1");
    button(survivor, "removeCondition").click();
    expect(conditions()).toHaveLength(1);
    expect(conditions()[0]).not.toBe(survivor);
    expect(field()).toHaveFocus();
  });

  it("focuses the preceding condition after removing the last of several", async () => {
    button(groups()[0], "addCondition").click();
    await tick();
    button(conditions()[1], "removeCondition").click();
    expect(field()).toHaveFocus();
  });

  it.each([0, 1])(
    "removes group %i, reindexes survivors and hides the final remove button",
    async (index) => {
      controller.addGroup();
      await tick();
      expect(button(groups()[0], "removeGroup")).not.toHaveClass("hidden");
      button(groups()[index], "removeGroup").click();
      expect(groups()).toHaveLength(1);
      expect(groups()[0].querySelector("legend")).toHaveTextContent("Group 1");
      expect(field().name).toContain("[groups_attributes][0]");
      expect(field()).toHaveFocus();
      expect(button(groups()[0], "removeGroup")).toHaveClass("hidden");
      controller.removeGroup({ currentTarget: groups()[0] });
      expect(groups()).toHaveLength(1);
    },
  );

  it("clears form to an explicit blank query", () => {
    controller.clearForm();
    expect(groups()).toHaveLength(0);
    expect(root.querySelector('[name="q[groups_attributes]"]')).toHaveValue("");
  });

  it.each([true, false])(
    "confirms dirty close and respects acceptance=%s",
    (accepted) => {
      const confirm = vi.spyOn(window, "confirm").mockReturnValue(accepted);
      const event = close();
      expect(confirm).toHaveBeenCalledWith("Discard changes?");
      expect(event.defaultPrevented).toBe(!accepted);
      expect(groups()).toHaveLength(accepted ? 0 : 1);
    },
  );

  it.each(["single", "list", "multiple", "missing"])(
    "closes unchanged %s values without confirmation",
    (kind) => {
      if (kind === "list")
        value().innerHTML =
          '<input name="q[value][]" value="one"><input name="q[value][]" value="two">';
      if (kind === "multiple")
        value().innerHTML =
          '<select multiple name="q[value][]"><option selected>one</option><option selected>two</option></select>';
      if (kind === "missing")
        conditions()[0]
          .querySelectorAll("input, select")
          .forEach((input) => input.remove());
      controller.searchGroupsTemplateTarget.innerHTML =
        controller.searchGroupsContainerTarget.innerHTML;
      const confirm = vi.spyOn(window, "confirm");
      expect(
        close(new KeyboardEvent("keydown", { key: "Escape", cancelable: true }))
          .defaultPrevented,
      ).toBe(false);
      expect(groups()).toHaveLength(0);
      expect(confirm).not.toHaveBeenCalled();
    },
  );

  it.each(["field", "operator", "single", "list", "multiple"])(
    "preserves edited saved %s values when discard is rejected",
    (kind) => {
      change(field(), "name");
      change(operator(), "=");
      if (kind === "list") {
        value().innerHTML = '<input name="q[value][]" value="original">';
      } else if (kind === "multiple") {
        value().innerHTML =
          '<select multiple name="q[value][]"><option selected>original</option><option>edited</option></select>';
      }
      controller.searchGroupsTemplateTarget.innerHTML =
        controller.searchGroupsContainerTarget.innerHTML;
      controller.renderExistingSearch();
      const edited =
        kind === "field"
          ? field()
          : kind === "operator"
            ? operator()
            : value().querySelector("input, select");
      edited.value = kind === "operator" ? "in" : "edited";
      const confirm = vi.spyOn(window, "confirm").mockReturnValue(false);

      const event = close();

      expect(confirm).toHaveBeenCalledExactlyOnceWith("Discard changes?");
      expect(event.defaultPrevented).toBe(true);
      expect(edited.value).toBe(kind === "operator" ? "in" : "edited");
      expect(edited.isConnected).toBe(true);
    },
  );

  it("blocks synthetic keydown close and restores applied state when status is false", () => {
    expect(
      close(new Event("keydown", { cancelable: true })).defaultPrevented,
    ).toBe(true);
    controller.searchGroupsTemplateTarget.innerHTML =
      controller.searchGroupsContainerTarget.innerHTML;
    field().value = "edited";
    controller.statusValue = false;
    expect(close().defaultPrevented).toBe(false);
    expect(field()).toHaveValue("");
  });

  it.each([true, false])(
    "blocks invalid close and focuses only a visible enabled error field (available=%s)",
    (available) => {
      controller.hasErrorsValue = true;
      root.insertAdjacentHTML(
        "beforeend",
        '<input aria-invalid="true" disabled><input aria-invalid="true">',
      );
      if (available) {
        field().setAttribute("aria-invalid", "true");
        Object.defineProperty(field(), "offsetParent", { value: root });
        field().blur();
      }
      const event = new Event("close", { cancelable: true });
      const stop = vi.spyOn(event, "stopImmediatePropagation");
      close(event);
      expect(event.defaultPrevented).toBe(true);
      expect(stop).toHaveBeenCalledOnce();
      if (available) expect(field()).toHaveFocus();
    },
  );

  it.each([
    "=",
    "in",
    "not_in",
    "text_in",
    "text_not_in",
    "between",
    "not_between",
    "exists",
    "not_exists",
    "",
  ])("renders the appropriate value control for %s", (operation) => {
    change(field(), "name");
    change(operator(), operation);
    expect(conditions()[0].querySelectorAll(".value")).toHaveLength(
      operation.includes("between") ? 2 : 1,
    );
    expect(value().classList.contains("invisible")).toBe(
      operation === "" || operation.includes("exists"),
    );
    const suffix =
      operation.includes("between") || operation.endsWith("in")
        ? "[value][]"
        : "[value]";
    expect(value().querySelector("input").name).toBe(
      `q[groups_attributes][0][conditions_attributes][0]${suffix}`,
    );
    change(operator(), "=");
    expect(conditions()[0].querySelectorAll(".value")).toHaveLength(1);
  });

  it.each([
    [
      "status",
      { values: ["draft", "in-progress"], labels: { draft: "Draft label" } },
      "=",
      ["", "draft", "in-progress"],
      ["", "Draft label", "In Progress"],
    ],
    [
      "status",
      { values: ["needs_review"] },
      "in",
      ["needs_review"],
      ["Needs Review"],
    ],
    [
      "metadata.status",
      { values: ["draft"] },
      "=",
      ["", "draft"],
      ["", "Draft"],
    ],
    ["status", { labels: { draft: "Draft" } }, "=", [""], [""]],
    ["status", {}, "=", [""], [""]],
    ["status", null, "=", [""], [""]],
  ])(
    "populates enum %s using %j with %s",
    (selected, config, operation, values, labels) => {
      controller.enumFieldsValue = { [selected]: config };
      change(field(), selected);
      if (selected.startsWith("metadata."))
        expect(operator().options[1].text).toBe("Enum metadata");
      change(operator(), operation);
      const select = value().querySelector("select");
      expect([...select.options].map((o) => o.value)).toEqual(values);
      expect([...select.options].map((o) => o.text)).toEqual(labels);
      expect(value()).not.toHaveClass("invisible");
      change(operator(), operation);
      expect(value().querySelector("select").options).toHaveLength(
        values.length,
      );
    },
  );

  it("uses grouped metadata operators, or standard operators when metadata is unavailable", () => {
    change(field(), "metadata.age");
    expect(
      [...operator().querySelectorAll("optgroup")].map((g) => g.label),
    ).toEqual(["Text", "Numeric"]);
    controller.operationsValue = { standard: { Equals: "=" } };
    change(field(), "metadata.other");
    expect(operator().querySelector("optgroup")).toBeNull();
    controller.enumFieldsValue = { "metadata.enum": { values: ["one"] } };
    change(field(), "metadata.enum");
    expect(operator().options[1]).toHaveTextContent("Equals");
  });

  it("resets values on a field change, preserves them for duplicate events, and hides operators when blank", () => {
    change(field(), "name");
    change(operator(), "=");
    value().querySelector("input").value = "preserve";
    change(field(), "name");
    expect(value().querySelector("input")).toHaveValue("preserve");
    value().insertAdjacentHTML(
      "beforeend",
      "<select><option selected>old</option></select>",
    );
    change(field(), "metadata.age");
    expect(value().querySelector("input")).toHaveValue("");
    expect(value().querySelector("select").selectedIndex).toBe(-1);
    change(field(), "");
    expect(operator().parentElement).toHaveClass("invisible", "@max-xl:hidden");
  });

  it("reads the submitted field when a combobox display input dispatches change", () => {
    field().value = "  name  ";
    const display = document.createElement("input");
    conditions()[0].append(display);
    controller.handleFieldChange({ target: display });
    expect(operator().options[1].value).toBe("=");
    expect(conditions()[0].dataset.advancedSearchSelectedField).toBe("name");
  });

  it("ignores events outside conditions or groups and missing operators or value containers", () => {
    controller.addCondition({ currentTarget: root });
    controller.removeCondition({ currentTarget: root });
    controller.handleOperatorChange({ target: root });
    controller.handleFieldChange({ target: root });
    controller.addGroup();
    controller.removeGroup({ currentTarget: root });
    const orphan = conditions()[0];
    root.append(orphan);
    controller.removeCondition({ currentTarget: orphan });
    controller.handleOperatorChange({ target: operator(orphan) });
    operator(orphan).remove();
    controller.handleFieldChange({ target: field(orphan) });
    const current = conditions(groups()[1])[0];
    value(current).remove();
    field(current).value = "name";
    controller.handleFieldChange({ target: field(current) });
    controller.handleOperatorChange({ target: operator(current) });
    expect(groups()).toHaveLength(2);
  });

  it("supports groups without action containers, legends, or remove buttons", () => {
    controller.groupTemplateTarget.innerHTML = `<fieldset data-${identifier}-target="groupsContainer"></fieldset>`;
    controller.addGroup();
    expect(conditions(groups()[1])).toHaveLength(1);
    expect(field(conditions(groups()[1])[0])).toHaveFocus();
    controller.conditionTemplateTarget.innerHTML = `<fieldset data-${identifier}-target="conditionsContainer"><input type="hidden"><input id="fallback"></fieldset>`;
    controller.addGroup();
    expect(document.getElementById("fallback")).toHaveFocus();
    controller.conditionTemplateTarget.innerHTML = `<fieldset data-${identifier}-target="conditionsContainer"></fieldset>`;
    controller.addGroup();
    expect(conditions(groups()[3])).toHaveLength(1);
  });

  it("handles enum templates without select controls or value containers", () => {
    controller.enumFieldsValue = { status: { values: ["draft"] } };
    change(field(), "status");
    controller.selectValueTemplateTarget.innerHTML = textValue;
    change(operator(), "=");
    expect(value().querySelector("select")).toBeNull();
    controller.selectValueTemplateTarget.innerHTML = "";
    change(operator(), "=");
    expect(value()).toBeNull();
  });
  it("leaves focus unchanged when the remaining group has no conditions", () => {
    controller.addGroup();
    conditions(groups()[0])[0].remove();
    controller.removeGroup({ currentTarget: groups()[1] });
    expect(groups()).toHaveLength(1);
    expect(conditions()).toHaveLength(0);
  });

  it("ignores reindexing a group outside the search container", () => {
    const group = groups()[0];
    root.append(group);
    controller.addCondition({ currentTarget: group });
    expect(conditions(group)).toHaveLength(2);
    expect(controller.searchGroupsContainerTarget.children).toHaveLength(0);
  });
});
