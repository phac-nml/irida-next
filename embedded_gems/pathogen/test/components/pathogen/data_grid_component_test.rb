# frozen_string_literal: true

require 'test_helper'

module Pathogen
  # Tests for Pathogen::DataGridComponent rendering behavior.
  class DataGridComponentTest < ViewComponent::TestCase
    test 'renders grid with caption and sticky columns' do
      render_inline(Pathogen::DataGridComponent.new(
                      caption: 'Sample grid',
                      sticky_columns: 1,
                      columns: [
                        { key: :id, label: 'ID', width: 120 },
                        { key: :name, label: 'Name', width: 200 }
                      ],
                      rows: [
                        { id: 'S-001', name: 'Sample one' },
                        { id: 'S-002', name: 'Sample two' }
                      ]
                    ))

      assert_selector '.pathogen-data-grid__table[aria-describedby]'
      assert_selector '.pathogen-data-grid__caption', text: 'Sample grid'
      assert_selector 'th.pathogen-data-grid__cell--header'
      assert_selector 'th.pathogen-data-grid__cell--sticky[style*="--pathogen-data-grid-sticky-left: 0px"]'
      assert_selector 'td.pathogen-data-grid__cell--body', text: 'Sample one'
    end
  end
end
