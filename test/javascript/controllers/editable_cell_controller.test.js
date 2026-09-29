import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import EditableCellController from "../../../app/javascript/controllers/editable_cell_controller.js";

const DEFAULT_ROWS = `
  <tr id="metadata_row_42">
    <td>Sample 42</td>
    <td data-editable-cell-target="editableCell">Canada</td>
  </tr>
  <tr id="metadata_row_7">
    <td>Sample 7</td>
    <td data-editable-cell-target="editableCell"></td>
  </tr>
`;

function fixture(rows, { withCancel = true } = {}) {
  const cancelButton = withCancel
    ? '<button value="cancel">Cancel</button>'
    : "";
  return `
    <div data-controller="editable-cell">
      <template data-editable-cell-target="formTemplate"><form>
        <input name="sample_id" value="SAMPLE_ID_PLACEHOLDER" />
        <input name="field" value="FIELD_ID_PLACEHOLDER" />
        <input name="value" value="FIELD_VALUE_PLACEHOLDER" />
        <input name="cell_id" value="CELL_ID_PLACEHOLDER" />
      </form></template>
      <div data-editable-cell-target="formContainer"></div>
      <template data-editable-cell-target="confirmDialogTemplate"><dialog>
        <p data-message-type="wov" class="hidden">ORIGINAL_VALUE to NEW_VALUE</p>
        <p data-message-type="wonv" class="hidden">clear ORIGINAL_VALUE</p>
        <p data-message-type="woov" class="hidden">set NEW_VALUE</p>
        ${cancelButton}
        <button value="confirm">Confirm</button>
      </dialog></template>
      <div data-editable-cell-target="confirmDialogContainer"></div>
      <table>
        <thead><tr>
          <th data-field-id="name">Name</th>
          <th data-field-id="country">Country</th>
        </tr></thead>
        <tbody>${rows}</tbody>
      </table>
    </div>
  `;
}

const cells = () =>
  document.querySelectorAll('[data-editable-cell-target="editableCell"]');
const formContainer = () =>
  document.querySelector('[data-editable-cell-target="formContainer"]');
const dialogContainer = () =>
  document.querySelector(
    '[data-editable-cell-target="confirmDialogContainer"]',
  );
const dialogEl = () => dialogContainer().querySelector("dialog");

function keydown(cell, key) {
  const event = new KeyboardEvent("keydown", {
    key,
    bubbles: true,
    cancelable: true,
  });
  cell.dispatchEvent(event);
  return event;
}

async function dispatchBlur(cell) {
  cell.dispatchEvent(new FocusEvent("blur", { bubbles: true }));
  await Promise.resolve();
  await Promise.resolve();
}

describe("editable cell controller", () => {
  let application;
  let focusSpy;
  let innerTextDescriptor;

  beforeEach(() => {
    // jsdom's innerText getter returns undefined for parsed content; mirror it
    // to textContent so the controller's innerText reads/writes behave.
    innerTextDescriptor = Object.getOwnPropertyDescriptor(
      HTMLElement.prototype,
      "innerText",
    );
    Object.defineProperty(HTMLElement.prototype, "innerText", {
      configurable: true,
      get() {
        return this.textContent;
      },
      set(value) {
        this.textContent = value;
      },
    });

    // jsdom has no modal top layer or <dialog> methods; model only the
    // browser method boundary so controller logic can be exercised.
    HTMLDialogElement.prototype.showModal = function () {
      this.open = true;
    };
    HTMLDialogElement.prototype.close = function () {
      this.open = false;
      this.dispatchEvent(new Event("close"));
    };
    focusSpy = vi.spyOn(HTMLElement.prototype, "focus");
  });

  afterEach(async () => {
    await stopApplication(application);
    document.body.innerHTML = "";
    delete HTMLDialogElement.prototype.showModal;
    delete HTMLDialogElement.prototype.close;
    if (innerTextDescriptor) {
      Object.defineProperty(
        HTMLElement.prototype,
        "innerText",
        innerTextDescriptor,
      );
    } else {
      delete HTMLElement.prototype.innerText;
    }
  });

  async function mount(rows = DEFAULT_ROWS, options = {}) {
    document.body.innerHTML = fixture(rows, options);
    const submitSpy = vi
      .spyOn(HTMLFormElement.prototype, "requestSubmit")
      .mockImplementation(() => {});
    application = startApplication();
    application.register("editable-cell", EditableCellController);
    await Promise.resolve();
    await new Promise((resolve) => requestAnimationFrame(resolve));
    const controller = application.getControllerForElementAndIdentifier(
      document.querySelector('[data-controller="editable-cell"]'),
      "editable-cell",
    );
    return { controller, submitSpy };
  }

  it("makes each cell editable on connect and focuses cells flagged for refocus", async () => {
    await mount(`
      <tr id="metadata_row_42">
        <td>Sample 42</td>
        <td data-editable-cell-target="editableCell" data-refocus>Canada</td>
      </tr>
    `);

    const cell = cells()[0];
    expect(cell.getAttribute("contenteditable")).toBe("true");
    expect(cell.id).not.toBe("");
    expect(focusSpy.mock.contexts).toContain(cell);
  });

  it("submits an update form when a changed value is confirmed with Enter", async () => {
    const { submitSpy } = await mount();
    const cell = cells()[0];
    cell.innerText = "Mexico";

    const event = keydown(cell, "Enter");

    expect(event.defaultPrevented).toBe(true);
    expect(submitSpy).toHaveBeenCalledTimes(1);
    expect(cell.hasAttribute("contenteditable")).toBe(false);

    const input = (name) =>
      formContainer().querySelector(`input[name="${name}"]`).value;
    expect(input("sample_id")).toBe("42");
    expect(input("field")).toBe("country");
    expect(input("value")).toBe("Mexico");
    expect(input("cell_id")).toBe(cell.id);
  });

  it("ignores Enter when the value is unchanged", async () => {
    const { submitSpy } = await mount();
    const cell = cells()[0];

    const event = keydown(cell, "Enter");

    expect(event.defaultPrevented).toBe(true);
    expect(submitSpy).not.toHaveBeenCalled();
  });

  it("ignores non-Enter keystrokes", async () => {
    const { submitSpy } = await mount();
    const cell = cells()[0];

    const event = keydown(cell, "a");

    expect(event.defaultPrevented).toBe(false);
    expect(submitSpy).not.toHaveBeenCalled();
  });

  it("logs an error and does not submit when the item id cannot be parsed", async () => {
    const consoleError = vi
      .spyOn(console, "error")
      .mockImplementation(() => {});
    const { controller, submitSpy } = await mount(`
      <tr id="norow">
        <td>Sample</td>
        <td data-editable-cell-target="editableCell">Canada</td>
      </tr>
    `);
    const cell = cells()[0];
    cell.innerText = "Mexico";

    controller.submit(cell);

    expect(consoleError).toHaveBeenCalled();
    expect(submitSpy).not.toHaveBeenCalled();
  });

  it("does nothing when submitting or confirming an unchanged value", async () => {
    const { controller, submitSpy } = await mount();
    const cell = cells()[0];

    controller.submit(cell);
    await controller.showConfirmDialog(cell);

    expect(submitSpy).not.toHaveBeenCalled();
    expect(dialogEl()).toBeNull();
  });

  it("returns early from blur for input events and unchanged cells", async () => {
    const { controller } = await mount();
    const cell = cells()[0];

    await controller.blur({ type: "input" });
    await dispatchBlur(cell);

    expect(dialogEl()).toBeNull();
  });

  it("opens the confirm dialog on blur and submits when confirmed", async () => {
    const { submitSpy } = await mount();
    const cell = cells()[0];
    cell.innerText = "Mexico";

    await dispatchBlur(cell);

    const dialog = dialogEl();
    expect(dialog).not.toBeNull();
    expect(dialog.open).toBe(true);
    expect(
      dialog
        .querySelector('[data-message-type="wov"]')
        .classList.contains("hidden"),
    ).toBe(false);

    dialog.querySelector('button[value="confirm"]').click();

    expect(submitSpy).toHaveBeenCalledTimes(1);
    expect(dialog.open).toBe(false);
  });

  it("resets the value when the confirm dialog is cancelled", async () => {
    const { submitSpy } = await mount();
    const cell = cells()[0];
    cell.innerText = "Mexico";

    await dispatchBlur(cell);

    dialogEl().querySelector('button[value="cancel"]').click();

    expect(submitSpy).not.toHaveBeenCalled();
    expect(cell.innerText).toBe("Canada");
  });

  it("ignores clicks on non-button dialog content", async () => {
    await mount();
    const cell = cells()[0];
    cell.innerText = "Mexico";

    await dispatchBlur(cell);
    const dialog = dialogEl();
    const closeSpy = vi.spyOn(dialog, "close");

    dialog.querySelector('[data-message-type="wov"]').click();

    expect(closeSpy).not.toHaveBeenCalled();
    expect(dialog.open).toBe(true);
  });

  it("shows the clear-value message when the new value is empty", async () => {
    await mount();
    const cell = cells()[0];
    cell.innerText = "";

    await dispatchBlur(cell);

    const dialog = dialogEl();
    expect(
      dialog
        .querySelector('[data-message-type="wonv"]')
        .classList.contains("hidden"),
    ).toBe(false);
  });

  it("shows the set-value message when the original value was empty", async () => {
    await mount();
    const emptyCell = cells()[1];
    emptyCell.innerText = "Ontario";

    await dispatchBlur(emptyCell);

    const dialog = dialogEl();
    expect(
      dialog
        .querySelector('[data-message-type="woov"]')
        .classList.contains("hidden"),
    ).toBe(false);
  });

  it("opens the dialog even when no cancel button is present", async () => {
    await mount(DEFAULT_ROWS, { withCancel: false });
    const cell = cells()[0];
    cell.innerText = "Mexico";

    await dispatchBlur(cell);

    const dialog = dialogEl();
    expect(dialog).not.toBeNull();
    expect(dialog.open).toBe(true);
    expect(dialog.querySelector('button[value="cancel"]')).toBeNull();
  });
});
