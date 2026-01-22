// Auto-registers all Pathogen Stimulus controllers
import { application } from "controllers/application"

// Import all Pathogen controllers using importmap-mapped paths
import TabsController from "pathogen-controllers/pathogen/tabs_controller"
import TooltipController from "pathogen-controllers/pathogen/tooltip_controller"
import DatepickerInputController from "pathogen-controllers/pathogen/datepicker/input_controller"
import DatepickerCalendarController from "pathogen-controllers/pathogen/datepicker/calendar_controller"

// Auto-register all controllers with their identifiers
application.register("pathogen--tabs", TabsController)
application.register("pathogen--tooltip", TooltipController)
application.register("pathogen--datepicker--input", DatepickerInputController)
application.register("pathogen--datepicker--calendar", DatepickerCalendarController)
