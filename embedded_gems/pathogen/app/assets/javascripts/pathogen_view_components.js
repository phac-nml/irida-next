// Import all Pathogen controllers using importmap-mapped paths
import TabsController from "pathogen_view_components/tabs_controller";
import TooltipController from "pathogen_view_components/tooltip_controller";
import DatepickerInputController from "pathogen_view_components/datepicker/input_controller";
import DatepickerBetaInputController from "pathogen_view_components/datepicker/beta_input_controller";
import DatepickerCalendarController from "pathogen_view_components/datepicker/calendar_controller";
import DatepickerBetaCalendarController from "pathogen_view_components/datepicker/beta_calendar_controller";

function registerPathogenControllers(application) {
  if (!application || typeof application.register !== "function") {
    console.error("[pathogen] Invalid Stimulus application instance");
    return;
  }

  application.register("pathogen--tabs", TabsController);
  application.register("pathogen--tooltip", TooltipController);
  application.register(
    "pathogen--datepicker--input",
    DatepickerInputController,
  );
  application.register(
    "pathogen--datepicker--beta-input",
    DatepickerBetaInputController,
  );
  application.register(
    "pathogen--datepicker--calendar",
    DatepickerCalendarController,
  );
  application.register(
    "pathogen--datepicker--beta-calendar",
    DatepickerBetaCalendarController,
  );

  if (import.meta.env?.DEV) {
    console.debug("[pathogen] Registered 4 Stimulus controllers");
  }
}

export {
  DatepickerCalendarController,
  DatepickerInputController,
  TabsController,
  TooltipController,
  registerPathogenControllers,
};
