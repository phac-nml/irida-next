# frozen_string_literal: true

# Pin pathogen controllers individually for importmap
# Note: pin_all_from doesn't work reliably with engine paths, so we pin explicitly
pin 'pathogen-controllers/pathogen/tabs_controller', to: 'pathogen/tabs_controller.js'
pin 'pathogen-controllers/pathogen/tooltip_controller', to: 'pathogen/tooltip_controller.js'
pin 'pathogen-controllers/pathogen/datepicker/input_controller', to: 'pathogen/datepicker/input_controller.js'
pin 'pathogen-controllers/pathogen/datepicker/calendar_controller', to: 'pathogen/datepicker/calendar_controller.js'
pin 'pathogen-controllers/pathogen/datepicker/utils', to: 'pathogen/datepicker/utils.js'
pin 'pathogen-controllers/pathogen/datepicker/constants', to: 'pathogen/datepicker/constants.js'

# Pin main entry point
pin 'pathogen_view_components', to: 'pathogen_view_components.js'
