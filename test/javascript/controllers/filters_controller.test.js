import { Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import { startApplication, stopApplication } from "../helpers/stimulus.js";
import FiltersController from "../../../app/javascript/controllers/filters_controller.js";

class SelectionProbe extends Controller {
  clear() {
    this.element.dataset.selection = "";
  }
}

describe("filters", () => {
  let application;
  afterEach(async () => {
    await stopApplication(application);
  });
  it.each([true, false])(
    "submits filters with a selection outlet present=%s",
    async (outlet) => {
      document.body.innerHTML = `<div id="selection" data-controller="selection" data-selection="sample-1"></div>
      <form data-controller="filters" ${outlet ? 'data-filters-selection-outlet="#selection"' : ""}>
        <select data-action="change->filters#submit"><option>All</option></select>
      </form>`;
      application = startApplication();
      application.register("selection", SelectionProbe);
      application.register("filters", FiltersController);
      await Promise.resolve();
      const form = document.querySelector("form");
      const submit = vi
        .spyOn(form, "requestSubmit")
        .mockImplementation(() => {});
      document
        .querySelector("select")
        .dispatchEvent(new Event("change", { bubbles: true }));
      expect(submit).toHaveBeenCalledOnce();
      expect(document.querySelector("#selection").dataset.selection).toBe(
        outlet ? "" : "sample-1",
      );
    },
  );
});
