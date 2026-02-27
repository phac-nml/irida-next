// Import all Pathogen controllers using importmap-mapped paths
import TabsController from "pathogen_view_components/tabs_controller";
import TooltipController from "pathogen_view_components/tooltip_controller";

function registerPathogenControllers(application) {
  if (!application || typeof application.register !== "function") {
    console.error("[pathogen] Invalid Stimulus application instance");
    return;
  }

  application.register("pathogen--tabs", TabsController);
  application.register("pathogen--tooltip", TooltipController);

  if (import.meta.env?.DEV) {
    console.debug("[pathogen] Registered 2 Stimulus controllers");
  }
}

export { TabsController, TooltipController, registerPathogenControllers };
