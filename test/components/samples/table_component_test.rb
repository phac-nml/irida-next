# frozen_string_literal: true

require 'test_helper'

module Samples
  class TableComponentTest < ViewComponent::TestCase
    test 'Should render a table of samples for a group that are sorted by the project column' do
      with_request_url '/-/groups/group-1/-/samples' do
        namespace = groups(:group_one)
        project_ids = Project.where(namespace_id: namespace.project_namespace_ids).pluck(:id)
        query = Sample::Query.new({ sort: 'namespaces.puid asc', project_ids: project_ids })
        pagy, samples = query.results(limit: 50, page: 1)
        samples = samples.includes(project: { namespace: :parent })

        render_inline Samples::TableComponent.new(
          samples,
          namespace,
          pagy,
          has_samples: namespace.has_samples?,
          abilities: {
            select_samples: true,
            edit_sample_metadata: true
          },
          metadata_fields: [],
          search_params: { metadata_template: 'none', sort: 'namespaces.puid asc' },
          empty: {
            title: I18n.t(:'groups.samples.table.no_samples'),
            description: I18n.t(:'groups.samples.table.no_associated_samples')
          }
        )

        assert_selector 'table', count: 1
        assert_selector 'table thead th', count: 6
        assert_selector 'table thead th:first-child', text: I18n.t('samples.table_component.puid')
        assert_selector 'table thead th:nth-child(2)', text: I18n.t('samples.table_component.name')
        assert_selector 'table thead th:nth-child(3)', text: I18n.t('samples.table_component.namespaces.puid')
        assert_selector 'table thead th:nth-child(3) [data-test-selector="sort_icon_asc"]'
        assert_selector 'table thead th:nth-child(4)', text: I18n.t('samples.table_component.created_at')
        assert_selector 'table thead th:nth-child(5)', text: I18n.t('samples.table_component.updated_at')
        assert_selector 'table thead th:nth-child(6)',
                        text: I18n.t('samples.table_component.attachments_updated_at')
        assert_selector 'table tbody tr', count: samples.count

        previous_project_puid = ''
        samples.each do |sample|
          assert_selector 'table tbody tr td:nth-child(2)', text: sample.name
          assert_selector 'table tbody tr td:nth-child(3)', text: sample.project.puid
          # verify the samples are sorted
          assert previous_project_puid <= sample.project.puid
          previous_project_puid = sample.project.puid
        end
      end
    end
  end
end
