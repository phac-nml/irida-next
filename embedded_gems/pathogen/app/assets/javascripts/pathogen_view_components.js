// Import all Pathogen controllers using importmap-mapped paths
import TabsController from "pathogen_view_components/tabs_controller";
import TooltipController from "pathogen_view_components/tooltip_controller";
import DatepickerInputController from "pathogen_view_components/datepicker/input_controller";
import DatepickerCalendarController from "pathogen_view_components/datepicker/calendar_controller";

// Auto-register all controllers with their identifiers

function registerPathogenControllers(application) {
  application.register("pathogen--tabs", TabsController);
  application.register("pathogen--tooltip", TooltipController);
  application.register(
    "pathogen--datepicker--input",
    DatepickerInputController,
  );
  application.register(
    "pathogen--datepicker--calendar",
    DatepickerCalendarController,
  );
}

export {
  DatepickerCalendarController,
  DatepickerInputController,
  TabsController,
  TooltipController,
  registerPathogenControllers,
};
