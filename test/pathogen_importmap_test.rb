# frozen_string_literal: true

require 'test_helper'

# Tests that Pathogen Stimulus controllers are properly configured in the importmap.
# These smoke tests ensure controllers can be lazy-loaded by Stimulus without resolution errors.
# Utility files (constants, utils) are imported via relative paths and don't need importmap pins.
class PathogenImportmapTest < ActiveSupport::TestCase
  test 'all pathogen controllers are pinned' do
    specifiers = Rails.application.importmap.packages.keys

    expected_files = %w[
      controllers/pathogen/tabs_controller
      controllers/pathogen/tooltip_controller
      controllers/pathogen/datepicker/input_controller
      controllers/pathogen/datepicker/calendar_controller
    ]

    expected_files.each do |file|
      assert_includes specifiers, file, "#{file} should be pinned in importmap"
    end
  end
end
