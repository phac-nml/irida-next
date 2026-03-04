# frozen_string_literal: true

module Nextflow
  # @label Samplesheet Component
  class SamplesheetComponentPreview < ViewComponent::Preview
    def default_v1(schema_file: 'nextflow_schema.json',
                   sample_ids: [Sample.first.id, Sample.second.id])
      Flipper.disable(:v2_samplesheet)
      samples = Sample.where(id: sample_ids)

      render NextflowComponent.new(
        workflow: default_workflow(schema_file),
        url: 'no_where',
        samples:,
        fields: [],
        namespace_id: 'SDFSDFSDF'
      )
    end

    def with_reference_files_v1(schema_file: 'nextflow_schema.json',
                                sample_ids: [Sample.first.id, Sample.second.id])
      Flipper.disable(:v2_samplesheet)
      samples = Sample.where(id: sample_ids)

      render NextflowComponent.new(
        workflow: with_reference_files_workflow(schema_file),
        url: 'no_where',
        samples:,
        fields: [],
        namespace_id: 'SDFSDFSDF'
      )
    end

    def with_metadata_v1(schema_file: 'nextflow_schema.json',
                         sample_ids: [Sample.first.id, Sample.second.id])
      Flipper.disable(:v2_samplesheet)
      samples = Sample.where(id: sample_ids)

      render NextflowComponent.new(
        workflow: with_metadata_workflow(schema_file),
        url: 'no_where',
        samples:,
        fields: [],
        namespace_id: 'SDFSDFSDF'
      )
    end

    def with_samplesheet_overrides_v1(sample_ids: [Sample.first.id, Sample.second.id])
      Flipper.disable(:v2_samplesheet)
      samples = Sample.where(id: sample_ids)

      render NextflowComponent.new(
        workflow: with_samplesheet_overrides_workflow,
        url: 'no_where',
        samples:,
        fields: %w[age gender collection_date],
        namespace_id: 'SDFSDFSDF'
      )
    end

    def default_v2(schema_file: 'nextflow_schema.json')
      Flipper.enable(:v2_samplesheet)

      render NextflowComponent.new(
        workflow: default_workflow(schema_file),
        url: 'no_where',
        sample_count: 2,
        fields: [],
        namespace_id: 'SDFSDFSDF'
      )
    end

    def with_reference_files_v2(schema_file: 'nextflow_schema.json')
      Flipper.enable(:v2_samplesheet)

      render NextflowComponent.new(
        workflow: with_reference_files_workflow(schema_file),
        url: 'no_where',
        sample_count: 2,
        fields: [],
        namespace_id: 'SDFSDFSDF'
      )
    end

    def with_metadata_v2(schema_file: 'nextflow_schema.json')
      Flipper.enable(:v2_samplesheet)

      render NextflowComponent.new(
        workflow: with_metadata_workflow(schema_file),
        url: 'no_where',
        sample_count: 1,
        fields: [],
        namespace_id: 'SDFSDFSDF'
      )
    end

    def with_samplesheet_overrides_v2
      Flipper.enable(:v2_samplesheet)

      render NextflowComponent.new(
        workflow: with_samplesheet_overrides_workflow,
        url: 'no_where',
        sample_count: 2,
        fields: %w[age gender collection_date],
        namespace_id: 'SDFSDFSDF'
      )
    end

    private

    def default_workflow(schema_file)
      entry = {
        name: 'phac-nml/iridanextexample',
        description: 'IRIDA Next Example Pipeline',
        url: 'https://github.com/phac-nml/iridanextexample'
      }.with_indifferent_access

      Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.1' },
                          Rails.root.join('test/fixtures/files/nextflow/', schema_file),
                          Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))
    end

    def with_reference_files_workflow(schema_file)
      entry = {
        name: 'phac-nml/iridanextexample',
        description: 'IRIDA Next Example Pipeline',
        url: 'https://github.com/phac-nml/iridanextexample'
      }.with_indifferent_access

      Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.1' },
                          Rails.root.join('test/fixtures/files/nextflow/', schema_file),
                          Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema_snvphyl.json'))
    end

    def with_metadata_workflow(schema_file)
      entry = {
        name: 'phac-nml/iridanextexample',
        description: 'IRIDA Next Example Pipeline',
        url: 'https://github.com/phac-nml/iridanextexample'
      }.with_indifferent_access

      Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.1' },
                          Rails.root.join('test/fixtures/files/nextflow/', schema_file),
                          Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema_meta.json'))
    end

    def with_samplesheet_overrides_workflow # rubocop:disable Metrics/MethodLength
      entry = {
        url: 'https://github.com/phac-nml/fastmatchirida',
        name: 'PNC Fast Match',
        description: 'IRIDA Next PNC Fast Match Pipeline',
        samplesheet_schema_overrides: {
          items: {
            properties: {
              metadata_1: { # rubocop:disable Naming/VariableNumber
                'x-irida-next-selected': 'new_isolates_date'
              },
              metadata_2: { # rubocop:disable Naming/VariableNumber
                'x-irida-next-selected': 'predicted_primary_identification_name'
              }
            },
            required: %w[
              sample
              mlst_alleles
            ]
          }
        },
        versions: [
          {
            name: '0.4.1',
            automatable: true
          }
        ]
      }.with_indifferent_access

      Irida::Pipeline.new('PNC Fast Match', entry, { name: '0.4.1' },
                          Rails.root.join(
                            'test/fixtures/files/nextflow/nextflow_schema_fastmatch.json'
                          ),
                          Rails.root.join(
                            'test/fixtures/files/nextflow/samplesheet_schema_fastmatch.json'
                          ))
    end
  end
end
