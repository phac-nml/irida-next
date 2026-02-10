# frozen_string_literal: true

# Pin pathogen controllers individually for importmap
# Note: pin_all_from doesn't work reliably with engine paths, so we pin explicitly
pin 'pathogen_view_components/tabs_controller', to: 'pathogen_view_components/tabs_controller.js'
pin 'pathogen_view_components/tooltip_controller', to: 'pathogen_view_components/tooltip_controller.js'
pin 'pathogen_view_components/datepicker/input_controller',
    to: 'pathogen_view_components/datepicker/input_controller.js'
pin 'pathogen_view_components/datepicker/beta_input_controller',
    to: 'pathogen_view_components/datepicker/beta_input_controller.js'
pin 'pathogen_view_components/datepicker/calendar_controller',
    to: 'pathogen_view_components/datepicker/calendar_controller.js'
pin 'pathogen_view_components/datepicker/beta_calendar_controller',
    to: 'pathogen_view_components/datepicker/beta_calendar_controller.js'
pin 'pathogen_view_components/datepicker/utils', to: 'pathogen_view_components/datepicker/utils.js'
pin 'pathogen_view_components/datepicker/constants', to: 'pathogen_view_components/datepicker/constants.js'

# Pin main entry point
pin 'pathogen_view_components', to: 'pathogen_view_components.js'
