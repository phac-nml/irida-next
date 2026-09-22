import { Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import ListInputController from "../../../app/javascript/controllers/list_input_controller.js";

describe("list input controller", () => {
  let application, element, input, controller, clearSelection;
  afterEach(async () => {
    await stopApplication(application);
  });
  async function mount({ filters = [], count = true, selection = false } = {}) {
    document.body.innerHTML = `<div id="selection" data-controller="selection"></div>
      <div data-controller="list-input" ${selection ? 'data-list-input-selection-outlet="#selection"' : ""}>
        <template data-list-input-target="template"><span class="search-tag filter-item"><input type="hidden" name="filters[]"><span class="label"></span><button type="button" data-action="list-input#remove"><span>Remove</span></button></span></template>
        <div data-list-input-target="tags" data-action="click->list-input#focus">
          <input name="filters[]" data-list-input-target="input" data-action="keydown->list-input#handleInput paste->list-input#handlePaste turbo:morph-element->list-input#idempotentConnect">
          <div><button type="button" data-action="list-input#clear">Clear</button></div>
        </div>
        ${count ? '<span data-list-input-target="count"></span>' : ""}
      </div>`;
    element = document.querySelector('[data-controller="list-input"]');
    element.setAttribute(
      "data-list-input-filters-value",
      JSON.stringify(filters),
    );
    input = element.querySelector('[data-list-input-target="input"]');
    clearSelection = vi.fn();
    class SelectionOutlet extends Controller {
      clear() {
        clearSelection();
      }
    }
    application = startApplication();
    application.register("selection", SelectionOutlet);
    application.register("list-input", ListInputController);
    await Promise.resolve();
    await Promise.resolve();
    controller = application.getControllerForElementAndIdentifier(
      element,
      "list-input",
    );
  }
  function values() {
    return [...element.querySelectorAll('input[type="hidden"]')].map(
      (input) => input.value,
    );
  }
  function key(key, value = "") {
    input.value = value;
    const event = new KeyboardEvent("keydown", {
      key,
      bubbles: true,
      cancelable: true,
    });
    input.dispatchEvent(event);
    return event;
  }
  function paste(text, legacy = false) {
    const clipboard = { getData: vi.fn().mockReturnValue(text) };
    const event = new Event("paste", { bubbles: true, cancelable: true });
    if (legacy) vi.stubGlobal("clipboardData", clipboard);
    else Object.defineProperty(event, "clipboardData", { value: clipboard });
    input.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(true);
    expect(clipboard.getData).toHaveBeenCalledWith("text");
  }
  it("restores non-empty filters and their applied count", async () => {
    await mount({ filters: ["Alpha", "", null, "Beta"] });
    expect(values()).toEqual(["Alpha", "Beta"]);
    const count = element.querySelector('[data-list-input-target="count"]');
    expect(count.textContent).toBe("2");
    expect(count.classList.contains("inline-flex")).toBe(true);
  });
  it("hides a zero count and supports an omitted counter", async () => {
    await mount();
    expect(
      element
        .querySelector('[data-list-input-target="count"]')
        .classList.contains("hidden"),
    ).toBe(true);
    element.querySelector('[data-list-input-target="count"]').remove();
    await Promise.resolve();
    controller.afterSubmit();
    expect(values()).toEqual([]);
  });
  it("adds a trimmed tag on comma and keeps focus in the input", async () => {
    await mount();
    expect(key(",", "  Alpha  ").defaultPrevented).toBe(true);
    expect(values()).toEqual(["Alpha"]);
    expect(input.value).toBe("");
    expect(document.activeElement).toBe(input);
  });
  it.each([",", " "])(
    "prevents an empty %j delimiter from entering the field",
    async (value) => {
      await mount();
      expect(key(value, "  ").defaultPrevented).toBe(true);
      expect(values()).toEqual([]);
    },
  );
  it.each(["a", " ", "Backspace"])(
    "leaves normal editing alone for %j",
    async (value) => {
      await mount({ filters: ["Alpha"] });
      expect(key(value, "Beta").defaultPrevented).toBe(false);
      expect(input.value).toBe("Beta");
      expect(values()).toEqual(["Alpha"]);
    },
  );
  it("leaves an active input-method composition untouched", async () => {
    await mount();
    input.value = "Draft";
    const event = new KeyboardEvent("keydown", {
      key: ",",
      keyCode: 229,
      isComposing: true,
      bubbles: true,
      cancelable: true,
    });
    input.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(false);
    expect(values()).toEqual([]);
    expect(input.value).toBe("Draft");
  });
  it("does not mistake a shifted comma key for a comma delimiter", async () => {
    await mount();
    input.value = "Alpha";
    const event = new KeyboardEvent("keydown", {
      key: "<",
      keyCode: 188,
      shiftKey: true,
      bubbles: true,
      cancelable: true,
    });
    input.dispatchEvent(event);
    expect(event.defaultPrevented).toBe(false);
    expect(values()).toEqual([]);
    expect(input.value).toBe("Alpha");
  });
  it("moves the last tag back into an empty input on Backspace", async () => {
    await mount({ filters: ["Alpha", "Beta"] });
    expect(key("Backspace").defaultPrevented).toBe(true);
    expect(values()).toEqual(["Alpha"]);
    expect(input.value).toBe("Beta");
  });
  it("does nothing when Backspace has no tag to restore", async () => {
    await mount();
    expect(key("Backspace").defaultPrevented).toBe(false);
    expect(input.value).toBe("");
  });
  it.each([false, true])(
    "splits pasted lines and commas, dropping empty entries (legacy=%s)",
    async (legacy) => {
      await mount({ filters: ["Existing"] });
      paste(" Alpha, Beta\r\n\nGamma, , ", legacy);
      expect(values()).toEqual(["Existing", "Alpha", "Beta", "Gamma"]);
      expect(input.value).toBe("");
      expect(document.activeElement).toBe(input);
    },
  );
  it("renders pasted markup as text", async () => {
    await mount();
    paste("<img src=x onerror=alert(1)>");
    expect(values()).toEqual(["<img src=x onerror=alert(1)>"]);
    expect(element.querySelector("img")).toBeNull();
    expect(element.querySelector(".label").textContent).toBe(
      "<img src=x onerror=alert(1)>",
    );
  });
  it("removes a tag when the remove-button child is clicked", async () => {
    await mount({ filters: ["Alpha", "Beta"] });
    element.querySelector(".filter-item button span").click();
    expect(values()).toEqual(["Beta"]);
    expect(document.activeElement).toBe(input);
  });
  it("clears tags and input while retaining the controls after the input", async () => {
    await mount({ filters: ["Alpha"] });
    input.value = "Draft";
    element.querySelector('[data-action="list-input#clear"]').click();
    expect(values()).toEqual([]);
    expect(input.value).toBe("");
    expect(
      element.querySelector('[data-action="list-input#clear"]'),
    ).not.toBeNull();
  });
  it("stores the submitted values and clears its selection outlet", async () => {
    await mount({ filters: ["Alpha"], selection: true });
    input.value = "Beta";
    controller.afterSubmit();
    expect(controller.filtersValue).toEqual(["Alpha", "Beta"]);
    expect(clearSelection).toHaveBeenCalledOnce();
    expect(
      element.querySelector('[data-list-input-target="count"]').textContent,
    ).toBe("2");
    controller.afterClose();
    expect(values()).toEqual([]);
    expect(input.value).toBe("");
    input.dispatchEvent(new Event("turbo:morph-element", { bubbles: true }));
    expect(values()).toEqual(["Alpha", "Beta"]);
  });
  it("restores applied filters without duplication on morph and reconnect", async () => {
    await mount({ filters: ["Alpha"], count: false });
    paste("Draft");
    input.dispatchEvent(new Event("turbo:morph-element", { bubbles: true }));
    expect(values()).toEqual(["Alpha"]);
    element.remove();
    await Promise.resolve();
    document.body.append(element);
    await Promise.resolve();
    expect(values()).toEqual(["Alpha"]);
  });
});
