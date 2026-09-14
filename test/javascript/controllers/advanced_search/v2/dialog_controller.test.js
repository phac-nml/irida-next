import { Application } from "@hotwired/stimulus";
import { waitFor } from "@testing-library/dom";
import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import BuilderController from "../../../../../app/javascript/controllers/advanced_search/v2/builder_controller.js";
import DialogController from "../../../../../app/javascript/controllers/advanced_search/v2/dialog_controller.js";
import ViralDialogController from "../../../../../app/javascript/controllers/viral/dialog_controller.js";

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
