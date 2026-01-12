# frozen_string_literal: true

require 'test_helper'

module Samples
  class VirtualizedTableComponentTest < ViewComponent::TestCase
    setup do
      Flipper.enable(:virtualized_samples_table)
    end

    teardown do
      Flipper.disable(:virtualized_samples_table)
    end

    test 'renders virtualized table with virtual-scroll controller' do
      render_virtualized_table_component

      # Should have virtual-scroll controller
      assert_selector '#samples-table[data-controller~="virtual-scroll"]'
      assert_selector '#samples-table[data-virtual-scroll-metadata-fields-value]'
      assert_selector '#samples-table[data-virtual-scroll-fixed-columns-value]'
      assert_selector '#samples-table[data-virtual-scroll-sticky-column-count-value="2"]'
    end

    test 'renders ARIA grid semantics' do
      render_virtualized_table_component

      # Should have ARIA grid roles
      assert_selector 'table[role="grid"]'
      assert_selector 'thead[role="rowgroup"]'
      assert_selector 'tbody[role="rowgroup"]'
      assert_selector 'tbody tr[role="row"]', minimum: 1
      assert_selector 'tbody tr[aria-rowindex]', minimum: 1
    end

    test 'renders all metadata fields without limiting' do
      # Create 150 metadata fields
      metadata_fields = (1..150).map { |i| "field_#{i}" }

      render_virtualized_table_component(metadata_fields: metadata_fields)

      # Should render all metadata field headers (no limiting for virtualized table)
      expected_columns = 6 # puid, name, namespaces.puid, created_at, updated_at, attachments_updated_at
      assert_selector 'table thead th', count: expected_columns + 150
    end

    test 'renders template container for virtualized cells' do
      render_virtualized_table_component(metadata_fields: %w[field1 field2])

      # Should have template container
      assert_selector '#virtual-scroll-templates[data-virtual-scroll-target="templateContainer"]'
      assert_selector '#virtual-scroll-templates template[data-field]', minimum: 1
    end

    test 'deferred template loading for projects' do
      with_request_url '/namespaces/12/projects/1/samples' do
        project = projects(:project1)
        namespace = project.namespace
        pagy = build_pagy_for_project(project)
        metadata_fields = (1..50).map { |i| "field_#{i}" }

        render_inline Samples::VirtualizedTableComponent.new(
          @rendered_samples,
          namespace,
          pagy,
          **component_options(namespace, metadata_fields: metadata_fields)
        )

        # Should have deferred frame for remaining fields (after initial batch of 20)
        assert_selector 'turbo-frame#deferred-templates[src]', visible: :all
      end
    end

    test 'no deferred template loading for groups' do
      metadata_fields = (1..50).map { |i| "field_#{i}" }
      render_virtualized_table_component(metadata_fields: metadata_fields)

      # Groups should not have deferred frame
      assert_no_selector 'turbo-frame#deferred-templates'
    end

    test 'renders loading overlay' do
      render_virtualized_table_component

      # Should have loading overlay
      assert_selector '[data-virtual-scroll-target="loading"]'
    end

    test 'selection checkboxes include Pathogen styling classes' do
      render_virtualized_table_component

      assert_selector 'input[type="checkbox"][class~="size-6"]', minimum: 1
      assert_selector 'input[type="checkbox"][class*="-mt-0.5"]', minimum: 1
    end

    test 'renders editable cells with gridcell role' do
      render_virtualized_table_component(
        metadata_fields: ['field1'],
        abilities: { select_samples: true, edit_sample_metadata: true }
      )

      # Editable cells should have gridcell role
      assert_selector 'template td[role="gridcell"][data-editable-cell-target="editableCell"]', minimum: 1
    end

    private

    def render_virtualized_table_component(metadata_fields: [], abilities: default_abilities)
      with_request_url '/-/groups/group-1/-/samples' do
        namespace = groups(:group_one)
        pagy = build_pagy(namespace)

        render_inline Samples::VirtualizedTableComponent.new(
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

    def build_pagy_for_project(project)
      query = Sample::Query.new({ sort: 'name asc', project_ids: [project.id] })
      pagy, samples = query.results(limit: 20, page: 1)
      @rendered_samples = samples.includes(project: { namespace: :parent })
      @pagy = pagy
      pagy
    end

    def component_options(namespace, metadata_fields: [], abilities: default_abilities)
      {
        has_samples: namespace.has_samples?,
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
