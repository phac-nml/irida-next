# frozen_string_literal: true

require 'test_helper'

module Samples
  class TableV2FooterComponentTest < ViewComponent::TestCase
    test 'footer shows the entire matching total on later pages' do
      render_table(count: 1200, page_number: 2)

      assert_selector '[data-samples-total]', text: 'Samples: 1,200'
      assert_selector 'tbody tr', count: 1
      assert_no_selector '.pvc-data-grid__scroll [data-samples-total]'
    end

    test 'footer shows zero for an empty filtered result' do
      render_table(count: 0, rows: [])

      assert_selector '[data-samples-total]', text: 'Samples: 0'
    end

    test 'empty project displays a total of zero' do
      render_table(count: 0, rows: [], has_samples: false)

      assert_selector '[data-samples-total]', text: 'Samples: 0'
      assert_selector '.empty_state_message'
    end

    test 'footer reuses the translated sample label' do
      I18n.with_locale(:fr) do
        render_table(count: 1)

        assert_selector '[data-samples-total]', text: 'Échantillons: 1'
      end
    end

    test 'does not infer a total from the loaded batch when pagination is absent' do
      render_table(count: nil)

      assert_no_selector '[data-samples-total]'
    end

    private

    def render_table(count:, page_number: 1, rows: [samples(:sample1)], has_samples: true)
      pagy = Pagy::Offset.new(count:, page: page_number, limit: 1) unless count.nil?
      with_request_url '/group-1/project-1/-/samples' do
        render_inline Table::V2::Component.new(rows, projects(:project1).namespace, pagy, has_samples:)
      end
    end
  end
end
