import { Controller } from "@hotwired/stimulus";
import { afterEach, describe, expect, it, vi } from "vitest";
import StandaloneController from "../../../../../app/javascript/controllers/advanced_search/v2/standalone_controller.js";
import {
  startApplication,
  stopApplication,
} from "../../../helpers/stimulus.js";

describe("advanced search v2 standalone controller", () => {
  let application;
  const renderSpy = vi.fn();

  class BuilderStub extends Controller {
    render() {
      renderSpy();
    }
  }

  afterEach(async () => {
    renderSpy.mockReset();
    await stopApplication(application);
    application = null;
  });

  function mount({ withOutlet = true } = {}) {
    document.body.innerHTML = `
      <div
        id="standalone"
        data-controller="advanced-search--v2--standalone"
        ${withOutlet ? 'data-advanced-search--v2--standalone-advanced-search--v2--builder-outlet="#builder"' : ""}
      >
        ${withOutlet ? '<div id="builder" data-controller="advanced-search--v2--builder"></div>' : ""}
      </div>
    `;

    application = startApplication();
    application.register(
      "advanced-search--v2--standalone",
      StandaloneController,
    );
    application.register("advanced-search--v2--builder", BuilderStub);
  }

  function controller() {
    return application.getControllerForElementAndIdentifier(
      document.getElementById("standalone"),
      "advanced-search--v2--standalone",
    );
  }

  it("renders the builder when the outlet is connected", async () => {
    mount({ withOutlet: true });

    await Promise.resolve();
    await Promise.resolve();

    expect(renderSpy).toHaveBeenCalled();
  });

  it("no-ops rendering callbacks when outlet is missing", async () => {
    mount({ withOutlet: false });

    await Promise.resolve();
    await Promise.resolve();

    expect(() => controller().renderBuilder()).not.toThrow();
    expect(() =>
      controller().advancedSearchV2BuilderOutletConnected(),
    ).not.toThrow();
    expect(renderSpy).not.toHaveBeenCalled();
  });
});
