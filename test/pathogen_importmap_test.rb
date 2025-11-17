# frozen_string_literal: true

require 'test_helper'

class PathogenImportmapTest < ActiveSupport::TestCase
  test 'pathogen datepicker input controller is pinned' do
    specifiers = Rails.application.importmap.packages.keys
    assert_includes specifiers, 'controllers/pathogen/datepicker/input_controller'
  end

  test 'pathogen tabs controller is pinned' do
    specifiers = Rails.application.importmap.packages.keys
    assert_includes specifiers, 'controllers/pathogen/tabs_controller'
  end
end
