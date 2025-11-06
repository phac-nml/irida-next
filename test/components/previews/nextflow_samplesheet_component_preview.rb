# frozen_string_literal: true

class NextflowSamplesheetComponentPreview < ViewComponent::Preview
  # @param schema_file select :schema_file_options
  def default(schema_file: 'nextflow_schema.json', sample_ids: [Sample.first.id, Sample.second.id])
    samples = Sample.where(id: sample_ids)

    entry = {
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline',
      url: 'https://github.com/phac-nml/iridanextexample'
    }.with_indifferent_access

    workflow = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.1' },
                                   Rails.root.join('test/fixtures/files/nextflow/', schema_file),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    render_with_template(locals: {
                           samples:,
                           workflow:
                         })
  end

  def with_reference_files(schema_file: 'nextflow_schema.json', sample_ids: [Sample.first.id, Sample.second.id])
    samples = Sample.where(id: sample_ids)

    entry = {
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline',
      url: 'https://github.com/phac-nml/iridanextexample'
    }.with_indifferent_access

    workflow = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.1' },
                                   Rails.root.join('test/fixtures/files/nextflow/', schema_file),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema_snvphyl.json'))

    render_with_template(locals: {
                           samples:,
                           workflow:
                         })
  end

  def with_metadata(schema_file: 'nextflow_schema.json', sample_ids: [Sample.first.id, Sample.second.id])
    samples = Sample.where(id: sample_ids)
    entry = {
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline',
      url: 'https://github.com/phac-nml/iridanextexample'
    }.with_indifferent_access

    workflow = Irida::Pipeline.new('phac-nml/iridanextexample', entry, { name: '1.0.1' },
                                   Rails.root.join('test/fixtures/files/nextflow/', schema_file),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema_meta.json'))

    render_with_template(locals: {
                           samples:,
                           workflow:
                         })
  end

  def with_samplesheet_overrides(sample_ids: [Sample.first.id, Sample.second.id]) # rubocop:disable Metrics/MethodLength
    samples = Sample.where(id: sample_ids)

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

    workflow = Irida::Pipeline.new('PNC Fast Match', entry, { name: '0.4.1' },
                                   Rails.root.join(
                                     'test/fixtures/files/nextflow/nextflow_schema_fastmatch.json'
                                   ),
                                   Rails.root.join(
                                     'test/fixtures/files/nextflow/samplesheet_schema_fastmatch.json'
                                   ))

    render_with_template(locals: {
                           samples:,
                           workflow:
                         })
  end

  private

  def schema_file_options
    Rails.root.join('test/fixtures/files/nextflow').entries.select do |f|
      File.file?(File.join('test/fixtures/files/nextflow', f)) && f.to_s.starts_with?('samplesheet_schema')
    end
  end
end
