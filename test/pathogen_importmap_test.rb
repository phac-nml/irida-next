# frozen_string_literal: true

require 'test_helper'

# Tests that Pathogen Stimulus controllers are properly configured in the importmap.
# These smoke tests ensure controllers can be lazy-loaded by Stimulus without resolution errors.
class PathogenImportmapTest < ActiveSupport::TestCase
  test 'all pathogen controllers and utilities are pinned' do
    specifiers = Rails.application.importmap.packages.keys

    expected_files = %w[
      controllers/pathogen/tabs_controller
      controllers/pathogen/tooltip_controller
      controllers/pathogen/datepicker/input_controller
      controllers/pathogen/datepicker/calendar_controller
      controllers/pathogen/datepicker/constants
      controllers/pathogen/datepicker/utils
    ]

    expected_files.each do |file|
      assert_includes specifiers, file, "#{file} should be pinned in importmap"
    end
  end
end
