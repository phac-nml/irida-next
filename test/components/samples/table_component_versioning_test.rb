# frozen_string_literal: true

require 'view_component_test_case'

module Samples
  class TableComponentVersioningTest < ViewComponentTestCase
    test 'renders v1 when version override is v1' do
      render_component(version: :v1)

      assert_selector '[data-samples-table-version="v1"]'
      assert_selector 'table'
      assert_no_selector '.pathogen-data-grid__table'
    end

    test 'renders v2 when version override is v2' do
      render_component(version: :v2)

      assert_selector '[data-samples-table-version="v2"]'
      assert_selector '.pathogen-data-grid__table'
    end

    test 'raises when version override is invalid' do
      assert_raises(ArgumentError) do
        render_component(version: :v3)
      end
    end

    private

    def render_component(version:)
      project = projects(:project1)
      namespace = project.namespace
      sample = samples(:sample1)
      pagy = Pagy::Offset.new(count: 1, page: 1, limit: 20)

      with_request_url "/namespaces/#{project.namespace.parent.id}/projects/#{project.id}/samples" do
        render_inline(
          Samples::TableComponent.new([sample], namespace, pagy,
                                      version: version,
                                      has_samples: true,
                                      empty: { title: 'No Samples', description: 'Nothing here' })
        )
      end
    end
  end
end
