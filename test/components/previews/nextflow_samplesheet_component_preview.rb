# frozen_string_literal: true

class NextflowSamplesheetComponentPreview < ViewComponent::Preview
  # @param schema_file select :schema_file_options
  def default(schema_file: 'samplesheet_schema.json')
    project = Project.first
    sample1 = Sample.find_or_create_by(name: 'Sample 43', project_id: project.id)
    sample2 = Sample.find_or_create_by(name: 'Sample 44', project_id: project.id)

    render_with_template(locals: {
                           schema_file:,
                           samples: [sample1, sample2],
                           fields: %w[insdc_accession country metadata_3]
                         })
  end

  private

  def schema_file_options
    Rails.root.join('test/fixtures/files/nextflow').entries.select do |f|
      File.file?(File.join('test/fixtures/files/nextflow', f)) && f.to_s.starts_with?('samplesheet_schema')
    end
  end
end
