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
          search_params: { metadata_template: 'none', sort: 'namespaces.puid asc' }.with_indifferent_access,
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
        assert_selector 'table thead th:nth-child(3) svg.arrow-up-icon'
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

    test 'Should dynamically limit metadata fields based on sample count with 20 samples' do
      with_request_url '/namespaces/12/projects/1/samples' do
        project = projects(:project1)
        namespace = project.namespace
        samples = Sample.limit(20).to_a
        pagy = Pagy.new(count: 20, page: 1, limit: 20)
        metadata_fields = (1..150).map { |i| "field_#{i}" }

        render_inline Samples::TableComponent.new(
          samples,
          namespace,
          pagy,
          has_samples: true,
          abilities: {},
          metadata_fields: metadata_fields,
          search_params: { sort: 'name asc' }.with_indifferent_access,
          empty: {}
        )

        # 20 samples: 2000/20 = 100 fields max
        # Should show 100 metadata field columns (150 requested, limited to 100)
        expected_columns = 5 # puid, name, created_at, updated_at, attachments_updated_at
        assert_selector 'table thead th', count: expected_columns + 100

        # Should show warning message
        assert_selector 'div', text: /limited to 100 for 20 samples/
      end
    end

    test 'Should dynamically limit metadata fields based on sample count with 50 samples' do
      with_request_url '/namespaces/12/projects/1/samples' do
        project = projects(:project1)
        namespace = project.namespace
        samples = Sample.limit(50).to_a
        pagy = Pagy.new(count: 50, page: 1, limit: 50)
        metadata_fields = (1..100).map { |i| "field_#{i}" }

        render_inline Samples::TableComponent.new(
          samples,
          namespace,
          pagy,
          has_samples: true,
          abilities: {},
          metadata_fields: metadata_fields,
          search_params: { sort: 'name asc' }.with_indifferent_access,
          empty: {}
        )

        # 50 samples: 2000/50 = 40 fields max
        # Should show 40 metadata field columns (100 requested, limited to 40)
        expected_columns = 5 # puid, name, created_at, updated_at, attachments_updated_at
        assert_selector 'table thead th', count: expected_columns + 40

        # Should show warning message
        assert_selector 'div', text: /limited to 40 for 50 samples/
      end
    end

    test 'Should cap metadata fields at hard maximum of 200 with 5 samples' do
      with_request_url '/namespaces/12/projects/1/samples' do
        project = projects(:project1)
        namespace = project.namespace
        samples = Sample.limit(5).to_a
        pagy = Pagy.new(count: 5, page: 1, limit: 5)
        metadata_fields = (1..250).map { |i| "field_#{i}" }

        render_inline Samples::TableComponent.new(
          samples,
          namespace,
          pagy,
          has_samples: true,
          abilities: {},
          metadata_fields: metadata_fields,
          search_params: { sort: 'name asc' }.with_indifferent_access,
          empty: {}
        )

        # 5 samples: 2000/5 = 400, but capped at 200
        # Should show 200 metadata field columns (250 requested, limited to 200)
        expected_columns = 5 # puid, name, created_at, updated_at, attachments_updated_at
        assert_selector 'table thead th', count: expected_columns + 200

        # Should show warning message
        assert_selector 'div', text: /limited to 200 for 5 samples/
      end
    end

    test 'Should not show warning when metadata fields are within limit' do
      with_request_url '/namespaces/12/projects/1/samples' do
        project = projects(:project1)
        namespace = project.namespace
        samples = Sample.limit(20).to_a
        pagy = Pagy.new(count: 20, page: 1, limit: 20)
        metadata_fields = (1..50).map { |i| "field_#{i}" } # Well under the 100 limit for 20 samples

        render_inline Samples::TableComponent.new(
          samples,
          namespace,
          pagy,
          has_samples: true,
          abilities: {},
          metadata_fields: metadata_fields,
          search_params: { sort: 'name asc' }.with_indifferent_access,
          empty: {}
        )

        # Should show all 50 metadata field columns
        expected_columns = 5 # puid, name, created_at, updated_at, attachments_updated_at
        assert_selector 'table thead th', count: expected_columns + 50

        # Should NOT show warning message
        assert_no_selector 'div', text: /limited to/
      end
    end

    test 'Should handle single sample edge case' do
      with_request_url '/namespaces/12/projects/1/samples' do
        project = projects(:project1)
        namespace = project.namespace
        samples = Sample.limit(1).to_a
        pagy = Pagy.new(count: 1, page: 1, limit: 1)
        metadata_fields = (1..250).map { |i| "field_#{i}" }

        render_inline Samples::TableComponent.new(
          samples,
          namespace,
          pagy,
          has_samples: true,
          abilities: {},
          metadata_fields: metadata_fields,
          search_params: { sort: 'name asc' }.with_indifferent_access,
          empty: {}
        )

        # 1 sample: 2000/1 = 2000, capped at 200
        # Should show 200 metadata field columns (250 requested, limited to 200)
        expected_columns = 5 # puid, name, created_at, updated_at, attachments_updated_at
        assert_selector 'table thead th', count: expected_columns + 200

        # Should show warning message
        assert_selector 'div', text: /limited to 200 for 1 sample/
      end
    end
  end
end
