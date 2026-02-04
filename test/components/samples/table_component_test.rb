# frozen_string_literal: true

require 'test_helper'

module Samples
  class TableComponentTest < ViewComponent::TestCase
    setup do
      Flipper.disable(:virtualized_samples_table)
    end

    teardown do
      Flipper.disable(:virtualized_samples_table)
    end

    test 'Should render a table of samples for a group that are sorted by the project column' do
      render_table_component

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
      assert_selector 'table tbody tr', count: @rendered_samples.count

      previous_project_puid = ''
      @rendered_samples.each do |sample|
        assert_selector 'table tbody tr td:nth-child(2)', text: sample.name
        assert_selector 'table tbody tr td:nth-child(3)', text: sample.project.puid
        # verify the samples are sorted
        assert previous_project_puid <= sample.project.puid
        previous_project_puid = sample.project.puid
      end
    end

    test 'selection checkboxes include Pathogen styling classes' do
      render_table_component

      assert_selector 'input[type="checkbox"][class~="size-6"]', minimum: 1
      assert_selector 'input[type="checkbox"][class*="-mt-0.5"]', minimum: 1
    end

    private

    def render_table_component(metadata_fields: [], abilities: default_abilities)
      with_request_url '/-/groups/group-1/-/samples' do
        namespace = groups(:group_one)
        pagy = build_pagy(namespace)

        render_inline Samples::TableComponent.new(
          @rendered_samples,
          namespace,
          pagy,
          **component_options(namespace, metadata_fields: metadata_fields, abilities: abilities)
        )
      end
    end

    def build_pagy(namespace)
      project_ids = Project.where(namespace_id: namespace.project_namespace_ids).pluck(:id)
      query = Sample::Query.new({ sort: 'namespaces.puid asc', project_ids: project_ids })
      pagy, samples = query.results(limit: 50, page: 1)
      @rendered_samples = samples.includes(project: { namespace: :parent })
      @pagy = pagy
      pagy
    end

    def component_options(namespace, metadata_fields: [], abilities: default_abilities)
      has_samples = if namespace.is_a?(Group)
                      namespace.has_samples?
                    else
                      # ProjectNamespace doesn't have has_samples? method
                      @rendered_samples.any?
                    end

      {
        has_samples: has_samples,
        abilities: abilities,
        metadata_fields: metadata_fields,
        search_params: default_search_params,
        empty: default_empty_messages
      }
    end

    def default_abilities
      { select_samples: true, edit_sample_metadata: true }
    end

    def default_search_params
      { metadata_template: 'none', sort: 'namespaces.puid asc' }.with_indifferent_access
    end

    def default_empty_messages
      {
        title: I18n.t(:'groups.samples.table.no_samples'),
        description: I18n.t(:'groups.samples.table.no_associated_samples')
      }
    end
  end
end
