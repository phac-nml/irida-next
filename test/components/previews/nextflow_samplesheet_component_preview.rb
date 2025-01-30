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

    workflow = Irida::Pipeline.new(entry, '1.0.1',
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

    workflow = Irida::Pipeline.new(entry, '1.0.1',
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

    workflow = Irida::Pipeline.new(entry, '1.0.1',
                                   Rails.root.join('test/fixtures/files/nextflow/', schema_file),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema_meta.json'))

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
