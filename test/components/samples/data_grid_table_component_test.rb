# frozen_string_literal: true

require 'view_component_test_case'

module Samples
  class DataGridTableComponentTest < ViewComponentTestCase
    test 'renders data grid with sample rows' do
      samples = [samples(:sample1), samples(:sample2)]
      pagy = Pagy.new(count: samples.size, page: 1, items: 20)
      namespace = projects(:project1).namespace

      render_inline(Samples::DataGridTableComponent.new(
                      samples,
                      namespace,
                      pagy,
                      has_samples: true,
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      assert_selector '.pathogen-data-grid__table'
      assert_selector 'th', text: 'Sample PUID'
      assert_selector 'td', text: samples.first.puid
    end

    test 'renders empty state when samples are absent' do
      pagy = Pagy.new(count: 0, page: 1, items: 20)
      namespace = projects(:project1).namespace

      render_inline(Samples::DataGridTableComponent.new(
                      [],
                      namespace,
                      pagy,
                      has_samples: false,
                      empty: { title: 'No Samples', description: 'Nothing here' }
                    ))

      assert_selector '.empty_state_message', text: 'No Samples'
      assert_no_selector '.pathogen-data-grid__table'
    end
  end
end
