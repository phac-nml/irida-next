# frozen_string_literal: true

module Samples
  # @label Samples Data Grid Table
  class DataGridTableComponentPreview < ViewComponent::Preview
    # @label Project Samples
    def project_samples
      render Samples::DataGridTableComponent.new(
        sample_data,
        project_namespace,
        pagy_instance(3),
        has_samples: true,
        abilities: { select_samples: false, edit_sample_metadata: false },
        metadata_fields: %w[isolate_source collection_date],
        search_params: {},
        empty: { title: 'No Samples', description: 'No samples found' }
      )
    end

    # @label Group Samples (with Project PUID column)
    def group_samples
      render Samples::DataGridTableComponent.new(
        sample_data,
        group_namespace,
        pagy_instance(3),
        has_samples: true,
        abilities: { select_samples: false, edit_sample_metadata: false },
        metadata_fields: %w[isolate_source],
        search_params: {},
        empty: { title: 'No Samples', description: 'No samples found' }
      )
    end

    # @label Empty State
    def empty_state
      render Samples::DataGridTableComponent.new(
        [],
        project_namespace,
        pagy_instance(0),
        has_samples: false,
        abilities: { select_samples: false, edit_sample_metadata: false },
        metadata_fields: [],
        search_params: {},
        empty: { title: 'No Samples', description: 'This project has no samples yet' }
      )
    end

    # @label With Search Highlighting
    def with_search_highlighting
      render Samples::DataGridTableComponent.new(
        sample_data,
        project_namespace,
        pagy_instance(3),
        has_samples: true,
        abilities: { select_samples: false, edit_sample_metadata: false },
        metadata_fields: [],
        search_params: { name_or_puid_cont: 'Sample' },
        empty: { title: 'No Samples', description: 'No samples found' }
      )
    end

    # @label With Many Metadata Fields (triggers warning)
    def with_metadata_warning
      # Create many metadata fields to trigger the warning
      many_fields = (1..250).map { |i| "metadata_field_#{i}" }

      render Samples::DataGridTableComponent.new(
        sample_data,
        project_namespace,
        pagy_instance(3),
        has_samples: true,
        abilities: { select_samples: false, edit_sample_metadata: true },
        metadata_fields: many_fields,
        search_params: {},
        empty: { title: 'No Samples', description: 'No samples found' }
      )
    end

    private

    def sample_data
      [samples(:sample1), samples(:sample2), samples(:sample30)]
    end

    def project_namespace
      projects(:project1).namespace
    end

    def group_namespace
      groups(:group_one)
    end

    def pagy_instance(count)
      Pagy.new(count: count, page: 1, items: 20)
    end
  end
end
