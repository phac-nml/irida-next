import { Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import {
  startApplication,
  stopApplication,
} from "../../../../helpers/stimulus.js";
import CompleteController from "../../../../../../app/javascript/controllers/projects/samples/metadata/complete_controller.js";

describe("projects/samples/metadata CompleteController", () => {
  let application;

  afterEach(async () => {
    await stopApplication(application);
  });

  it("submits the filters outlet on connect", async () => {
    const submit = vi.fn();
    class FiltersController extends Controller {
      submit() {
        submit();
      }
    }

    document.body.innerHTML = `
      <div id="filters" data-controller="filters"></div>
      <div data-controller="projects--samples--metadata--complete"
           data-projects--samples--metadata--complete-filters-outlet="#filters"></div>`;

    application = startApplication();
    application.register("filters", FiltersController);
    application.register(
      "projects--samples--metadata--complete",
      CompleteController,
    );
    await Promise.resolve();

    expect(submit).toHaveBeenCalledOnce();
  });
});
