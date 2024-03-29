# frozen_string_literal: true

class NextflowSamplesheetComponentPreview < ViewComponent::Preview
  # @param schema_file select :schema_file_options
  def default(schema_file: 'samplesheet_schema.json')
    sample1 = Sample.first
    sample2 = Sample.second

    render_with_template(locals: {
                           schema_file:,
                           samples: [sample1, sample2]
                         })
  end

  private

  def schema_file_options
    Rails.root.join('test/fixtures/files/nextflow').entries.select do |f|
      File.file?(File.join('test/fixtures/files/nextflow', f)) && f.to_s.starts_with?('samplesheet_schema')
    end
  end
end
