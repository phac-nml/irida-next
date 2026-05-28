// Import and register all your controllers from the importmap under controllers/*

import { application } from "controllers/application";

// Eager load all controllers defined in the import map under controllers/**/*_controller
// import { eagerLoadControllersFrom } from "@hotwired/stimulus-loading";

// eagerLoadControllersFrom("controllers", application);

// Lazy load controllers as they appear in the DOM (remember not to preload controllers in import map!)
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading";

const registerPathogenControllers = async () => {
  try {
    const pathogenModule = await import("pathogen_view_components");
    if (typeof pathogenModule.registerPathogenControllers === "function") {
      pathogenModule.registerPathogenControllers(application);
      return;
    }
  } catch (error) {
    console.error(
      "Failed to import pathogen_view_components entrypoint",
      error,
    );
  }

  try {
    const [tabs, tooltip, dataGrid, toolbar] = await Promise.all([
      import("pathogen_view_components/tabs_controller"),
      import("pathogen_view_components/tooltip_controller"),
      import("pathogen_view_components/data_grid_controller"),
      import("pathogen_view_components/toolbar_controller"),
    ]);

    application.register("pathogen--tabs", tabs.default);
    application.register("pathogen--tooltip", tooltip.default);
    application.register("pathogen--data-grid", dataGrid.default);
    application.register("pathogen--toolbar", toolbar.default);
  } catch (error) {
    console.error("Failed to register fallback pathogen controllers", error);
  }
};

registerPathogenControllers().finally(() => {
  lazyLoadControllersFrom("controllers", application);
});
