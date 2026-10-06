import { afterEach, describe, expect, it, vi } from "vitest";
import {
  startApplication,
  stopApplication,
} from "../../../../helpers/stimulus.js";
import CreateController from "../../../../../../app/javascript/controllers/projects/samples/metadata/create_controller.js";

const P = "projects--samples--metadata--create";

function template({ focusTarget = true } = {}) {
  return `
    <template data-${P}-target="fieldTemplate">
      <div class="metadata-field-wrapper">
        ${focusTarget ? `<span id="key_PLACEHOLDER" tabindex="-1"></span>` : ""}
        <div class="form-field">
          <input type="text" id="sample_key_PLACEHOLDER" name="sample[key_PLACEHOLDER]"
                 class="border-slate-300 dark:border-slate-600">
          <div id="sample_key_PLACEHOLDER_error" class="invisible">
            <span class="hidden"><span class="grow"></span></span>
          </div>
        </div>
        <div class="form-field">
          <input type="text" id="sample_value_PLACEHOLDER" name="sample[value_PLACEHOLDER]"
                 class="border-slate-300 dark:border-slate-600">
          <div id="sample_value_PLACEHOLDER_error" class="invisible">
            <span class="hidden"><span class="grow"></span></span>
          </div>
        </div>
        <button type="button" data-action="${P}#removeField">remove</button>
      </div>
    </template>`;
}

describe("projects/samples/metadata CreateController", () => {
  let application;

  afterEach(async () => {
    vi.useRealTimers();
    await stopApplication(application);
  });

  async function mount({ tmpl = template() } = {}) {
    document.body.innerHTML = `
      <div data-controller="${P}"
           data-${P}-key-missing-value="Key required"
           data-${P}-value-missing-value="Value required"
           data-${P}-form-error-value="Form has errors">
        <div data-${P}-target="formFieldError" class="hidden">
          <span data-${P}-target="formFieldErrorMessage"></span>
        </div>
        <form data-${P}-target="form">
          <div data-${P}-target="metadataToAdd"></div>
          ${tmpl}
          <div data-${P}-target="fieldsContainer"></div>
        </form>
      </div>`;
    application = startApplication();
    application.register(P, CreateController);
    await Promise.resolve();

    const element = document.querySelector(`[data-controller='${P}']`);
    const form = element.querySelector("form");
    form.requestSubmit = vi.fn();
    return {
      element,
      form,
      metadataToAdd: element.querySelector(
        `[data-${P}-target='metadataToAdd']`,
      ),
      fieldsContainer: element.querySelector(
        `[data-${P}-target='fieldsContainer']`,
      ),
      formFieldError: element.querySelector(
        `[data-${P}-target='formFieldError']`,
      ),
      formFieldErrorMessage: element.querySelector(
        `[data-${P}-target='formFieldErrorMessage']`,
      ),
      controller: application.getControllerForElementAndIdentifier(element, P),
    };
  }

  function wrappers() {
    return document.querySelectorAll(".metadata-field-wrapper");
  }

  function fill(index, key, value) {
    const keyInput = document.getElementById(`sample_key_${index}`);
    const valueInput = document.getElementById(`sample_value_${index}`);
    if (key !== undefined) keyInput.value = key;
    if (value !== undefined) valueInput.value = value;
    return { keyInput, valueInput };
  }

  function submit(controller) {
    vi.useFakeTimers();
    controller.buildMetadata({ preventDefault: () => {} });
    vi.advanceTimersByTime(50);
    vi.useRealTimers();
  }

  it("adds an initial field on connect", async () => {
    await mount();

    expect(wrappers().length).toBe(1);
    expect(document.getElementById("sample_key_0")).not.toBeNull();
  });

  it("adds further fields and focuses the new key input", async () => {
    const { controller } = await mount();

    controller.addField();

    expect(wrappers().length).toBe(2);
    expect(document.getElementById("sample_key_1")).not.toBeNull();
  });

  it("handles a missing focus target for a new field", async () => {
    // Template without the key_<id> element exercises the optional-chaining
    // no-op branch in the focus helper.
    const { controller } = await mount({
      tmpl: template({ focusTarget: false }),
    });

    expect(() => controller.addField()).not.toThrow();
    expect(wrappers().length).toBe(2);
  });

  it("logs an error when the field template is empty", async () => {
    const spy = vi.spyOn(console, "error").mockImplementation(() => {});

    await mount({
      tmpl: `<template data-${P}-target="fieldTemplate"></template>`,
    });

    expect(wrappers().length).toBe(0);
    expect(spy).toHaveBeenCalled();
  });

  it("removes a field and re-adds one when none remain", async () => {
    const { controller, fieldsContainer } = await mount();
    controller.addField();
    expect(wrappers().length).toBe(2);

    // Remove the first field: one remains, no re-add.
    controller.removeField({
      target: fieldsContainer.querySelector("button"),
    });
    expect(wrappers().length).toBe(1);

    // Remove the last field: ensureMinimumFields re-adds one.
    controller.removeField({
      target: fieldsContainer.querySelector("button"),
    });
    expect(wrappers().length).toBe(1);
  });

  it("warns and returns when removing a field without a key input", async () => {
    const spy = vi.spyOn(console, "warn").mockImplementation(() => {});
    const { controller, fieldsContainer } = await mount();

    fieldsContainer.insertAdjacentHTML(
      "beforeend",
      `<div class="metadata-field-wrapper"><button id="orphan">x</button></div>`,
    );
    controller.removeField({ target: document.getElementById("orphan") });

    expect(spy).toHaveBeenCalled();
  });

  it("removes a field that has no value input", async () => {
    const { controller, fieldsContainer } = await mount();

    fieldsContainer.insertAdjacentHTML(
      "beforeend",
      `<div class="metadata-field-wrapper" id="key-only">
         <input type="text" id="sample_key_9" class="border-slate-300 dark:border-slate-600">
         <button id="remove-key-only">x</button>
       </div>`,
    );
    controller.removeField({
      target: document.getElementById("remove-key-only"),
    });

    expect(document.getElementById("key-only")).toBeNull();
  });

  it("logs an error when the field container cannot be found", async () => {
    const spy = vi.spyOn(console, "error").mockImplementation(() => {});
    const { controller } = await mount();

    controller.removeField({ target: document.body });

    expect(spy).toHaveBeenCalled();
  });

  it("submits valid metadata as hidden inputs and clears field names", async () => {
    const { controller, form, metadataToAdd } = await mount();
    const { keyInput, valueInput } = fill(0, "organism", "salmonella");

    submit(controller);

    const hidden = metadataToAdd.querySelector("input[type='hidden']");
    expect(hidden.name).toBe("sample[create_fields][organism]");
    expect(hidden.value).toBe("salmonella");
    expect(keyInput.name).toBe("");
    expect(valueInput.name).toBe("");
    expect(form.requestSubmit).toHaveBeenCalledOnce();
  });

  it("updates an existing hidden input only when the value changes", async () => {
    const { controller, metadataToAdd } = await mount();
    fill(0, "organism", "salmonella");
    submit(controller);

    // Same value: no update, still a single hidden input.
    submit(controller);
    let hidden = metadataToAdd.querySelectorAll("input[type='hidden']");
    expect(hidden.length).toBe(1);
    expect(hidden[0].value).toBe("salmonella");

    // Changed value: existing hidden input is updated in place.
    document.getElementById("sample_value_0").value = "listeria";
    submit(controller);
    hidden = metadataToAdd.querySelectorAll("input[type='hidden']");
    expect(hidden.length).toBe(1);
    expect(hidden[0].value).toBe("listeria");
  });

  it("shows field and form errors for invalid entries and clears them once fixed", async () => {
    const { controller, formFieldError, formFieldErrorMessage } = await mount();
    fill(0, "", "");

    submit(controller);

    const keyInput = document.getElementById("sample_key_0");
    const keyError = document.getElementById("sample_key_0_error");
    expect(keyInput.getAttribute("aria-invalid")).toBe("true");
    expect(keyError.querySelector("span.grow").textContent).toBe(
      "Key required",
    );
    expect(formFieldError.classList.contains("hidden")).toBe(false);
    expect(formFieldErrorMessage.innerHTML).toBe("Form has errors");

    // Submitting again while still invalid re-uses the already-shown error.
    submit(controller);
    expect(keyError.querySelector("span.grow").textContent).toBe(
      "Key required",
    );

    // Fixing the field clears the errors and submits.
    fill(0, "organism", "salmonella");
    submit(controller);
    expect(keyInput.hasAttribute("aria-invalid")).toBe(false);
    expect(keyError.querySelector("span.grow").textContent).toBe("");
    expect(formFieldError.classList.contains("hidden")).toBe(true);
  });

  it("flags only the missing half of a partially filled field", async () => {
    const { controller } = await mount();
    fill(0, "organism", "");

    submit(controller);

    expect(
      document.getElementById("sample_key_0").hasAttribute("aria-invalid"),
    ).toBe(false);
    expect(
      document.getElementById("sample_value_0").getAttribute("aria-invalid"),
    ).toBe("true");
    expect(
      document.getElementById("sample_value_0_error").querySelector("span.grow")
        .textContent,
    ).toBe("Value required");
  });

  it("flags a missing key while leaving a filled value untouched", async () => {
    const { controller } = await mount();
    fill(0, "", "salmonella");

    submit(controller);

    expect(
      document.getElementById("sample_key_0").getAttribute("aria-invalid"),
    ).toBe("true");
    expect(
      document.getElementById("sample_value_0").hasAttribute("aria-invalid"),
    ).toBe(false);
  });

  it("skips fields missing an input during processing", async () => {
    const spy = vi.spyOn(console, "warn").mockImplementation(() => {});
    const { controller, fieldsContainer, form } = await mount();
    fill(0, "organism", "salmonella");

    fieldsContainer.insertAdjacentHTML(
      "beforeend",
      `<div class="metadata-field-wrapper">
         <input type="text" id="sample_key_9" class="border-slate-300 dark:border-slate-600">
       </div>`,
    );

    submit(controller);

    expect(spy).toHaveBeenCalled();
    expect(form.requestSubmit).toHaveBeenCalledOnce();
  });

  it("logs the metadata error and shows a form error when hidden-input creation fails", async () => {
    const spy = vi.spyOn(console, "error").mockImplementation(() => {});
    const { controller, metadataToAdd, formFieldError } = await mount();
    fill(0, "organism", "salmonella");

    // Removing the metadataToAdd target makes hidden-input creation throw.
    metadataToAdd.remove();

    submit(controller);

    expect(spy).toHaveBeenCalled();
    expect(formFieldError.classList.contains("hidden")).toBe(false);
  });

  it("tolerates fields with missing error containers or spans", async () => {
    const { controller, fieldsContainer } = await mount();

    // Wrapper without error containers or a form-field wrapper.
    fieldsContainer.insertAdjacentHTML(
      "beforeend",
      `<div class="metadata-field-wrapper">
         <input type="text" id="sample_key_50" value="" class="border-slate-300 dark:border-slate-600">
         <input type="text" id="sample_value_50" value="filled" class="border-slate-300 dark:border-slate-600">
       </div>`,
    );
    // Wrapper whose error containers have no inner span.
    fieldsContainer.insertAdjacentHTML(
      "beforeend",
      `<div class="metadata-field-wrapper">
         <input type="text" id="sample_key_51" value="" class="border-slate-300 dark:border-slate-600">
         <div id="sample_key_51_error"></div>
         <input type="text" id="sample_value_51" value="filled" class="border-slate-300 dark:border-slate-600">
         <div id="sample_value_51_error"></div>
       </div>`,
    );

    expect(() => submit(controller)).not.toThrow();
    expect(
      document.getElementById("sample_key_50").getAttribute("aria-invalid"),
    ).toBe("true");
    expect(
      document.getElementById("sample_key_51").getAttribute("aria-invalid"),
    ).toBe("true");
  });
});
