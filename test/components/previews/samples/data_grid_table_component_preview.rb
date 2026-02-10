# frozen_string_literal: true

module Samples
  # @label Samples Data Grid Table
  class DataGridTableComponentPreview < ViewComponent::Preview
    StubNamespace = Struct.new(:path, :parent, :project, keyword_init: true)
    StubProject = Struct.new(:puid, :namespace, keyword_init: true) do
      def to_param
        puid
      end
    end

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

    private

    def sample_data
      [
        build_sample(puid: 'INXT_SAM_AAAAAAAAAA', name: 'Sample 1',
                     metadata: { 'isolate_source' => 'Water', 'collection_date' => '2024-01-15' }),
        build_sample(puid: 'INXT_SAM_AAAAAAAAAB', name: 'Sample 2',
                     metadata: { 'isolate_source' => 'Soil', 'collection_date' => '2024-02-20' }),
        build_sample(puid: 'INXT_SAM_AAAAAAAAAC', name: 'Sample 30',
                     metadata: { 'isolate_source' => 'Air', 'collection_date' => '2024-03-10' })
      ]
    end

    def build_sample(puid:, name:, metadata: {})
      sample = Sample.new(name: name, created_at: 2.days.ago, updated_at: 1.day.ago)

      sample.define_singleton_method(:puid) { puid }
      sample.define_singleton_method(:to_param) { puid }
      sample.define_singleton_method(:metadata) { metadata }
      sample.define_singleton_method(:attachments_updated_at) { 1.hour.ago }

      project_stub = StubProject.new(puid: 'INXT_PRJ_AAAAAAAAAA',
                                     namespace: StubNamespace.new(parent: group_namespace))
      sample.define_singleton_method(:project) { project_stub }

      sample
    end

    def project_namespace
      @project_namespace ||= begin
        ns = Namespace.new(name: 'Preview Project', path: 'preview-project')
        ns.define_singleton_method(:parent) { StubNamespace.new(path: 'preview-group') }
        ns.define_singleton_method(:project) { StubProject.new(puid: 'INXT_PRJ_AAAAAAAAAA') }
        ns
      end
    end

    def group_namespace
      @group_namespace ||= Group.new(name: 'Preview Group', path: 'preview-group')
    end

    def pagy_instance(count)
      Pagy.new(count: count, page: 1, limit: 20)
    end
  end
end
