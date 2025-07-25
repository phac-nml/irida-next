# frozen_string_literal: true

# Configure custom form builders here
# Sets PathogenFormBuilder as the default form builder for the application
Rails.application.reloader.to_prepare do
  ActionView::Base.default_form_builder = Pathogen::FormBuilders::PathogenFormBuilder
end
