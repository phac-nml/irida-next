# frozen_string_literal: true

class NextflowComponentPreview < ViewComponent::Preview
  # @param schema_file select :schema_file_options
  def default(schema_file: 'nextflow_schema.json')
    sample1 = Sample.first
    sample2 = Sample.second

    entry = {
      name: 'phac-nml/iridanextexample',
      description: 'IRIDA Next Example Pipeline',
      url: 'https://github.com/phac-nml/iridanextexample'
    }
    workflow = Irida::Pipeline.new(entry, '1.0.1',
                                   Rails.root.join('test/fixtures/files/nextflow/', schema_file),
                                   Rails.root.join('test/fixtures/files/nextflow/samplesheet_schema.json'))

    render_with_template(locals: {
                           samples: [sample1, sample2],
                           workflow:
                         })
  end

  private

  def schema_file_options
    Rails.root.join('test/fixtures/files/nextflow').entries.select do |f|
      File.file?(File.join('test/fixtures/files/nextflow', f)) && f.to_s.starts_with?('nextflow_schema')
    end
  end
end
