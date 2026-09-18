import { Application } from "@hotwired/stimulus";
import { waitFor } from "@testing-library/dom";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import BuilderController from "../../../../../app/javascript/controllers/advanced_search/v2/builder_controller.js";
import DialogController from "../../../../../app/javascript/controllers/advanced_search/v2/dialog_controller.js";
import ViralDialogController from "../../../../../app/javascript/controllers/viral/dialog_controller.js";
import { Controller } from "@hotwired/stimulus";

// jsdom does not provide layout for focus-trap's tabbable-node checks.
vi.mock("focus-trap", () => ({
  createFocusTrap: () => ({ activate: vi.fn(), deactivate: vi.fn() }),
}));

function renderFixture({ hasErrors = false, status = true } = {}) {
  const conditionName = "q[groups_attributes][0][conditions_attributes][0]";
  document.body.innerHTML = `
    <div
      id="advanced-search"
      data-controller="advanced-search--v2--dialog"
      data-action="viral--dialog:close->advanced-search--v2--dialog#close"
      data-advanced-search--v2--dialog-advanced-search--v2--builder-outlet="#advanced-search-builder"
      data-advanced-search--v2--dialog-status-value="${status}"
      data-advanced-search--v2--dialog-has-errors-value="${hasErrors}"
      data-advanced-search--v2--dialog-confirm-close-text-value="Discard changes?"
    >
      <div data-controller="viral--dialog" data-viral--dialog-open-value="false">
        <button type="button" data-viral--dialog-target="trigger"
          data-action="advanced-search--v2--dialog#renderSearch viral--dialog#open">Open</button>
        <dialog data-viral--dialog-target="dialog"
          data-action="keydown.esc->viral--dialog#handleEsc">
          <button type="button" data-viral--dialog-target="closeButton"
            data-action="click->viral--dialog#handleClose">Close</button>
          <div id="advanced-search-builder" data-controller="advanced-search--v2--builder"
            data-advanced-search--v2--builder-initial-state-value='[[{"field":"name","operator":"=","values":["original"]}]]'>
            <div data-advanced-search--v2--builder-target="searchGroupsContainer"></div>
            <template data-advanced-search--v2--builder-target="searchGroupsTemplate">
              <fieldset data-advanced-search--v2--builder-target="groupsContainer"
                data-advanced-search--v2--builder-group-index="0">
                <fieldset data-advanced-search--v2--builder-target="conditionsContainer"
                  data-advanced-search--v2--builder-group-index="0"
                  data-advanced-search--v2--builder-condition-index="0">
                  <input name="${conditionName}[field]" value="name">
                  <input name="${conditionName}[operator]" value="=">
                  <input name="${conditionName}[value]" value="original" aria-invalid="${hasErrors}">
                </fieldset>
              </fieldset>
            </template>
          </div>
        </dialog>
      </div>
    </div>
  `;

  const dialog = document.querySelector("dialog");
  dialog.showModal = vi.fn(() => {
    dialog.open = true;
  });
  dialog.close = vi.fn(() => {
    dialog.open = false;
  });
  return dialog;
}

describe.each(["Escape", "close button"])(
  "dialog dismissal by %s",
  (dismissal) => {
    let application;
    let dialog;
    let closeEvent;
    let confirm;

    beforeEach(() => {
      closeEvent = null;
      confirm = vi.spyOn(window, "confirm");
    });

    afterEach(async () => {
      document.body.replaceChildren();
      await Promise.resolve();
      application?.stop();
    });

    async function openDialog(options) {
      dialog = renderFixture(options);
      document
        .getElementById("advanced-search")
        .addEventListener("viral--dialog:close", (event) => {
          closeEvent = event;
        });

      application = Application.start();
      application.register("advanced-search--v2--dialog", DialogController);
      application.register("advanced-search--v2--builder", BuilderController);
      application.register("viral--dialog", ViralDialogController);

      await waitFor(() => {
        expect(
          document.querySelector("[data-controller='viral--dialog']"),
        ).toHaveAttribute("data-controller-connected", "true");
      });
      document.querySelector("[data-viral--dialog-target='trigger']").click();

      await waitFor(() => {
        expect(dialog.open).toBe(true);
        expect(valueInput()).toHaveValue("original");
      });
    }

    function valueInput() {
      return dialog.querySelector("[name$='[value]']");
    }

    function dismiss() {
      if (dismissal === "Escape") {
        dialog.dispatchEvent(
          new KeyboardEvent("keydown", {
            key: "Escape",
            bubbles: true,
            cancelable: true,
          }),
        );
      } else {
        dialog
          .querySelector("[data-viral--dialog-target='closeButton']")
          .click();
      }

      expect(closeEvent).toBeInstanceOf(CustomEvent);
      expect(closeEvent.type).toBe("viral--dialog:close");
    }

    it("closes a clean builder without confirmation", async () => {
      await openDialog();

      dismiss();

      expect(confirm).not.toHaveBeenCalled();
      expect(closeEvent.defaultPrevented).toBe(false);
      expect(dialog.open).toBe(false);
      expect(valueInput()).toBeNull();
      expect(
        document.querySelector("[data-viral--dialog-target='trigger']"),
      ).toHaveFocus();
    });

    it("closes and discards edits when confirmation is accepted", async () => {
      await openDialog();
      valueInput().value = "edited";
      confirm.mockReturnValue(true);

      dismiss();

      expect(confirm).toHaveBeenCalledExactlyOnceWith("Discard changes?");
      expect(closeEvent.defaultPrevented).toBe(false);
      expect(dialog.open).toBe(false);
      expect(valueInput()).toBeNull();
    });

    it("keeps the dialog and edited values when confirmation is rejected", async () => {
      await openDialog();
      valueInput().value = "edited";
      confirm.mockReturnValue(false);

      dismiss();

      expect(confirm).toHaveBeenCalledExactlyOnceWith("Discard changes?");
      expect(closeEvent.defaultPrevented).toBe(true);
      expect(dialog.open).toBe(true);
      expect(valueInput()).toHaveValue("edited");
    });

    it("preserves invalid values and focuses the invalid field without confirmation", async () => {
      await openDialog({ hasErrors: true });
      const input = valueInput();
      input.value = "invalid edit";
      // jsdom has no layout; expose this rendered input as visible to the adapter.
      Object.defineProperty(input, "offsetParent", {
        value: input.parentElement,
      });

      dismiss();

      expect(confirm).not.toHaveBeenCalled();
      expect(closeEvent.defaultPrevented).toBe(true);
      expect(dialog.open).toBe(true);
      expect(input).toHaveValue("invalid edit");
      expect(input).toHaveFocus();
    });

    it("restores the applied search without confirmation when status is false", async () => {
      await openDialog({ status: false });
      valueInput().value = "edited";

      dismiss();

      expect(confirm).not.toHaveBeenCalled();
      expect(closeEvent.defaultPrevented).toBe(false);
      expect(dialog.open).toBe(false);
      expect(valueInput()).toHaveValue("original");
    });
  },
);

describe("dialog adapter delegation", () => {
  let application;
  const builderSpies = {
    render: vi.fn(),
    clearForm: vi.fn(),
    clear: vi.fn(),
    isDirty: vi.fn(() => false),
  };

  class BuilderStub extends Controller {
    render() {
      builderSpies.render();
    }
    clearForm() {
      builderSpies.clearForm();
    }
    clear() {
      builderSpies.clear();
    }
    isDirty() {
      return builderSpies.isDirty();
    }
  }

  function mount({ open = false, withBuilder = true, status = true } = {}) {
    const outletAttr = withBuilder
      ? `data-advanced-search--v2--dialog-advanced-search--v2--builder-outlet="#builder"`
      : "";
    document.body.innerHTML = `
      <div id="advanced-search"
        data-controller="advanced-search--v2--dialog"
        ${outletAttr}
        data-advanced-search--v2--dialog-open-value="${open}"
        data-advanced-search--v2--dialog-status-value="${status}"
        data-advanced-search--v2--dialog-confirm-close-text-value="Discard?">
        ${withBuilder ? `<div id="builder" data-controller="advanced-search--v2--builder"></div>` : ""}
      </div>
    `;
    application = Application.start();
    application.register("advanced-search--v2--dialog", DialogController);
    application.register("advanced-search--v2--builder", BuilderStub);
    return application;
  }

  function dialogController() {
    return application.getControllerForElementAndIdentifier(
      document.getElementById("advanced-search"),
      "advanced-search--v2--dialog",
    );
  }

  afterEach(async () => {
    document.body.replaceChildren();
    // Let the Stimulus MutationObserver run disconnect() and detach the
    // document-level turbo:morph listener before the next test mounts.
    await new Promise((resolve) => setTimeout(resolve, 0));
    application?.stop();
    application = null;
  });

  it("renders the builder when the outlet connects while already open", async () => {
    mount({ open: true });

    await waitFor(() => {
      expect(builderSpies.render).toHaveBeenCalled();
    });
  });

  it("does not render on outlet connect when closed", async () => {
    mount({ open: false });

    await waitFor(() => {
      expect(dialogController()).toBeDefined();
    });
    expect(builderSpies.render).not.toHaveBeenCalled();
  });

  it("re-renders on turbo:morph when open and stays idle when closed", async () => {
    mount({ open: false });
    await waitFor(() => expect(dialogController()).toBeDefined());

    document.dispatchEvent(new CustomEvent("turbo:morph"));
    expect(builderSpies.render).not.toHaveBeenCalled();

    dialogController().openValue = true;
    document.dispatchEvent(new CustomEvent("turbo:morph"));
    expect(builderSpies.render).toHaveBeenCalledTimes(1);
  });

  it("stops listening for turbo:morph after disconnect", async () => {
    mount({ open: true });
    await waitFor(() => expect(builderSpies.render).toHaveBeenCalled());
    const callsBefore = builderSpies.render.mock.calls.length;

    document.getElementById("advanced-search").remove();
    await new Promise((resolve) => setTimeout(resolve, 0));
    document.dispatchEvent(new CustomEvent("turbo:morph"));

    expect(builderSpies.render.mock.calls.length).toBe(callsBefore);
  });

  it("clearForm() delegates to the builder outlet when connected", async () => {
    mount();
    await waitFor(() => expect(dialogController()).toBeDefined());

    dialogController().clearForm();

    expect(builderSpies.clearForm).toHaveBeenCalledTimes(1);
  });

  it("clearForm() is a no-op without a builder outlet", async () => {
    mount({ withBuilder: false });
    await waitFor(() => expect(dialogController()).toBeDefined());

    expect(() => dialogController().clearForm()).not.toThrow();
    expect(builderSpies.clearForm).not.toHaveBeenCalled();
  });

  it("renderSearch() is a no-op without a builder outlet", async () => {
    mount({ withBuilder: false });
    await waitFor(() => expect(dialogController()).toBeDefined());

    expect(() => dialogController().renderSearch()).not.toThrow();
    expect(builderSpies.render).not.toHaveBeenCalled();
  });

  it("close() treats a missing builder outlet as clean and clears without confirmation", async () => {
    mount({ withBuilder: false, status: true });
    await waitFor(() => expect(dialogController()).toBeDefined());
    const event = {
      preventDefault: vi.fn(),
      stopImmediatePropagation: vi.fn(),
    };

    dialogController().close(event);

    expect(event.preventDefault).not.toHaveBeenCalled();
    expect(builderSpies.clear).not.toHaveBeenCalled();
  });
});
