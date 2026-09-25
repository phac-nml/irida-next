# frozen_string_literal: true

require 'test_helper'

module Samples
  class TableV2MetadataComponentTest < ViewComponent::TestCase
    test 'metadata scalars render as escaped text with the published Pathogen API' do
      sample = samples(:sample1)
      sample.metadata = {
        'integer' => 42,
        'decimal' => 3.5,
        'boolean' => false,
        'empty' => nil,
        'html' => '<img src="x" onerror="alert(1)"><strong>sample</strong>'
      }

      with_request_url '/group-1/project-1/-/samples' do
        render_inline Table::V2::Component.new(
          [sample], projects(:project1).namespace, nil,
          metadata_fields: sample.metadata.keys
        )

        cells = page.all('tbody tr:first-child > *')
        assert_equal 10, cells.size
        assert_equal ['42', '3.5', 'false', '', sample.metadata.fetch('html')], cells.last(5).map(&:text)
        assert_no_selector 'tbody img, tbody strong, tbody script'
      end
    end
  end
end
