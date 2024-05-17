# frozen_string_literal: true

require 'application_system_test_case'

class NextflowSamplesheetTextCellComponentTest < ApplicationSystemTestCase
  test 'default' do
    visit('/rails/view_components/nextflow_samplesheet_text_cell_component/default')
    assert_selector 'input[type="text"][name="some[things]"]', count: 1
  end
end
